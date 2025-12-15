# Kafka workshop

## Create Topic

### Insert data to topic
Browser

### Prerequisite

```

confluent environment use <env-xxxxxx>

confluent kafka cluster use <lkc-xxxxxx>

confluent api-key store --resource <lkc-xxxxxx> <key> <secret>

confluent api-key use <key>


```

### Insert via Confluent CLI

**Value only**
confluent kafka topic produce <topic-name> --value-format string


**Key and Value**
confluent kafka topic produce <topic-name> \
  --value-format string \
  --key-format string \
  --parse-key \
  --delimiter ":"


### Consumer data Confluent Cli

**Just Consume**
confluent kafka topic consume <topic-name> --from-beginning




### Insert schema message

**Produce AVRO message**

1. Save following as schema.avsc
```
{
  "type": "record",
  "name": "User",
  "fields": [
    {"name": "id", "type": "int"},
    {"name": "name", "type": "string"},
    {"name": "email", "type": "string"}
  ]
}
```

2. Create Schema rgistry key/secret


3. replace api-key/secret and url.
```
confluent kafka topic produce <topic-name> \
  --value-format avro \
  --schema schema.avsc \
  --schema-registry-endpoint <SR-ENDPOINT-URL> \
  --schema-registry-api-key <SR-API-KEY> \
  --schema-registry-api-secret <SR-API-SECRET>
```

**Consume message with schema**

confluent kafka topic consume <topic-name> \
  --value-format avro \
  --from-beginning \
  --schema-registry-endpoint <SR-ENDPOINT-URL> \
  --schema-registry-api-key <SR-API-KEY> \
  --schema-registry-api-secret <SR-API-SECRET>


### Python Producer

sample_avro.py