import psycopg2
import time
import random
from faker import Faker
from datetime import datetime

# --- CONFIGURATION ---
DB_HOST = ""
DB_NAME = ""
DB_USER = ""
DB_PASS = ""

# --- INIT ---
fake = Faker("jp-JP")

def get_connection():
    conn = psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASS
    )
    conn.autocommit = True
    return conn

def init_tables(curr):

    sql = """
        CREATE TABLE IF NOT EXISTS customers (
            customer_id INT PRIMARY KEY,
            first_name VARCHAR(255) NOT NULL,
            last_name VARCHAR(255) NOT NULL,
            email VARCHAR(255),
            address_city VARCHAR(100),
            account_level VARCHAR(50), -- e.g., 'Standard', 'Premium'
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        CREATE TABLE IF NOT EXISTS warehouses (
            warehouse_id INT PRIMARY KEY,
            warehouse_name VARCHAR(255) NOT NULL,
            city VARCHAR(100) NOT NULL,
            capacity_limit INT,
            manager_name VARCHAR(255),
            last_maintained TIMESTAMP
        );
        CREATE TABLE IF NOT EXISTS shipments (
            shipment_id VARCHAR(50) PRIMARY KEY,
            customer_id INT NOT NULL,  -- Join Key 1
            warehouse_id INT NOT NULL, -- Join Key 2
            order_time TIMESTAMP NOT NULL, -- Critical for Flink Watermarks/Event Time
            status VARCHAR(50),        -- e.g., 'CREATED', 'SHIPPED', 'DELIVERED'
            weight_kg DECIMAL(10, 2),
            destination_city VARCHAR(100),
            FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
            FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
        );
    """

    curr.execute(sql)


def create_warehouses(curr):
    """Creates static warehouse data if not exists."""
    print("--- Checking/Creating Warehouses ---")
    curr.execute("SELECT count(*) FROM warehouses")
    if curr.fetchone()[0] > 0:
        print("Warehouses already exist. Skipping.")
        return

    # Create 5 fixed warehouses
    for i in range(1, 6):
        sql = """
            INSERT INTO warehouses (warehouse_id, warehouse_name, city, capacity_limit, manager_name, last_maintained)
            VALUES (%s, %s, %s, %s, %s, NOW())
        """
        curr.execute(sql, (
            i, 
            f"WH-{fake.city_suffix().upper()}-{i}", 
            fake.city(), 
            random.randint(1000, 50000), 
            fake.name()
        ))
    print("Initialized 5 Warehouses.")

def create_customer(curr, customer_id):
    """Inserts a single customer."""
    sql = """
        INSERT INTO customers (customer_id, first_name, last_name, email, address_city, account_level, updated_at)
        VALUES (%s, %s, %s, %s, %s, %s, NOW())
    """
    account_levels = ['Standard', 'Silver', 'Gold', 'Platinum']
    curr.execute(sql, (
        customer_id,
        fake.first_name(),
        fake.last_name(),
        fake.email(),
        fake.city(),
        random.choice(account_levels)
    ))
    # print(f"Inserted Customer ID: {customer_id}")

def create_shipment(curr, shipment_id, max_customer_id):
    """Inserts a shipment for a random existing customer."""
    if max_customer_id < 1: return

    sql = """
        INSERT INTO shipments (shipment_id, customer_id, warehouse_id, order_time, status, weight_kg, destination_city)
        VALUES (%s, %s, %s, NOW(), %s, %s, %s)
    """
    statuses = ['CREATED', 'PROCESSING', 'SHIPPED']
    curr.execute(sql, (
        shipment_id,
        random.randint(1, max_customer_id), # Pick random existing customer
        random.randint(1, 5),               # Pick random warehouse (1-5)
        random.choice(statuses),
        round(random.uniform(1.0, 50.0), 2),
        fake.city()
    ))
    print(f" > Generated Shipment {shipment_id} for Customer {random.randint(1, max_customer_id)}")

def main():
    conn = get_connection()
    curr = conn.cursor()

    # 0. init table creation
    init_tables(curr)

    # 1. Setup Static Data
    create_warehouses(curr)

    # 2. Initial Load: 100 Customers
    print(f"--- Generating Initial 100 Customers ---")
    current_customer_id = 1
    for _ in range(100):
        create_customer(curr, current_customer_id)
        current_customer_id += 1
    print("Initial load complete.")

    # 3. Continuous Loop
    print("--- Starting Real-time Simulation ---")
    print("1. Generates Shipments every 2 seconds (Fact Stream)")
    print("2. Adds a new Customer every 30 seconds (Slowly Changing Dimension)")
    
    last_customer_time = time.time()
    shipment_counter = 1

    try:
        while True:
            # A. Generate Shipment (The Stream)
            # We generate a unique string ID for shipments
            ship_id = f"SHP-{int(time.time())}-{shipment_counter}"
            create_shipment(curr, ship_id, current_customer_id - 1)
            shipment_counter += 1

            # B. Check if 30 seconds passed to add Customer
            if time.time() - last_customer_time >= 30:
                print(f"--- 30s TICK: Adding New Customer ID {current_customer_id} ---")
                create_customer(curr, current_customer_id)
                current_customer_id += 1
                last_customer_time = time.time()

            # Sleep to control shipment velocity
            time.sleep(2) 

    except KeyboardInterrupt:
        print("\nStopping generator...")
    finally:
        curr.close()
        conn.close()

if __name__ == "__main__":
    main()