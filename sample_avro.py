from confluent_kafka import Producer
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroSerializer
from confluent_kafka.serialization import SerializationContext, MessageField

# --- Configuration Section ---

# 1. Kafka Cluster Configuration
# Replace with your Cluster API Key and Secret
conf = {
    'bootstrap.servers': '<CLUSTER_BOOTSTRAP_SERVER>',  # e.g., pkc-xxxxx.us-east1.gcp.confluent.cloud:9092
    'security.protocol': 'SASL_SSL',
    'sasl.mechanism': 'PLAIN',
    'sasl.username': '<CLUSTER_API_KEY>',
    'sasl.password': '<CLUSTER_API_SECRET>'
}

# 2. Schema Registry Configuration
# Replace with your Schema Registry API Key and Secret
schema_registry_conf = {
    'url': '<SCHEMA_REGISTRY_ENDPOINT>',  # e.g., https://psrc-xxxxx.region.confluent.cloud
    'basic.auth.user.info': '<SR_API_KEY>:<SR_API_SECRET>'
}

topic = "user-topic"
# -----------------------------

# Define your Avro Schema
schema_str = """
{
    "type": "record",
    "name": "User",
    "namespace": "com.example",
    "fields": [
        {"name": "name", "type": "string"},
        {"name": "favorite_number", "type": "int"},
        {"name": "favorite_color", "type": "string"}
    ]
}
"""

# Initialize Schema Registry Client
schema_registry_client = SchemaRegistryClient(schema_registry_conf)

# Initialize Avro Serializer
avro_serializer = AvroSerializer(
    schema_registry_client,
    schema_str
)

# Initialize Producer
producer = Producer(conf)

def delivery_report(err, msg):
    if err is not None:
        print(f"Delivery failed for record {msg.key()}: {err}")
    else:
        print(f"Record {msg.key()} successfully produced to {msg.topic()} [{msg.partition()}] at offset {msg.offset()}")

# Produce Data
print("Producing Avro data with Auth...")

data = {
    "name": "Alice", 
    "favorite_number": 42, 
    "favorite_color": "blue"
}

try:
    producer.produce(
        topic=topic,
        key=str(data["name"]),
        value=avro_serializer(
            data, 
            SerializationContext(topic, MessageField.VALUE)
        ),
        on_delivery=delivery_report
    )
    
    producer.flush()

except Exception as e:
    print(f"Error producing message: {e}")