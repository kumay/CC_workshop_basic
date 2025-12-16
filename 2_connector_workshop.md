# Connector workshop


## Connector

### Datagen connector
Create following connectors
- stock
- shoe (Create shoe topic)
- shoe_customer (Create shoe_customer topic)
- shoe_order (Create shoe_order topic)


### DB config

DB name = mydb
DB user = postgres
password = SuperSecurePassword123!


### Postgres sink connector
Create with following settings

"topic": "shoe"

For DB credencials chekc AWS console


### Postgres source connector (optional)

"table": "shoe"

For DB credencials chekc AWS console


### Postgres CDC source connector (optional)

For DB credencials check AWS console