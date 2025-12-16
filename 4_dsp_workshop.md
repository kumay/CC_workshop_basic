# DSP workshop

## Table prep

1. open python script and insert credecial

```
> vi sample_dsp_data.py
```

2. get RDS(postgresql) data from AWS RDS console
```
# --- CONFIGURATION ---
DB_HOST = ""
DB_NAME = ""
DB_USER = ""
DB_PASS = ""

```

### Memo (What will be created)

-- 1. Customers (Dimension Table)
-- Used to enrich shipments with contact info and account priority.
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    address_city VARCHAR(100),
    account_level VARCHAR(50), -- e.g., 'Standard', 'Premium'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Warehouses (Dimension Table)
-- Used to enrich shipments with origin location details.
CREATE TABLE warehouses (
    warehouse_id INT PRIMARY KEY,
    warehouse_name VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    capacity_limit INT,
    manager_name VARCHAR(255),
    last_maintained TIMESTAMP
);

-- 3. Shipments (Fact/Stream Table)
-- This is the main stream you will process in Flink.
CREATE TABLE shipments (
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

## Connector

1. Set up postgresql CDC source connector if had not done yet.
See 2_connector_workshop for guidance.


## Flink join example

### Simple join
```
SELECT 
    s.shipment_id,
    s.order_time,
    s.status,
    -- Enriched Columns from Customers
    c.last_name || ' ' || c.first_name  AS full_name,
    c.email,
    c.account_level
FROM `cdc.public.shipments` AS s
LEFT JOIN `cdc.public.customers` AS c ON s.customer_id = c.customer_id;
```


### Aggregation with simple join
```
SELECT 
    c.last_name || ' ' || c.first_name  AS full_name,
    c.email,
    c.account_level,
    COUNT(s.customer_id) AS shipment_count
FROM `cdc.public.shipments` AS s
LEFT JOIN `cdc.public.customers` AS c ON s.customer_id = c.customer_id
WHERE s.status = 'CREATED'
GROUP BY 
  c.customer_id, 
  c.last_name, 
  c.first_name, 
  c.email,
  c.`account_level`;
```

## Challenge

1. create table called shipment_count with fields as follows..
- customer_id : int
- full_name : string
- email : string
- account_level : string
- shipment_count : int

set customer_id as primary_key

2.  



