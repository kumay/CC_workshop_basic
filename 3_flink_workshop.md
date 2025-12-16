# Flink workshop

## Table Prep

### Get all data

```
SELECT * FROM <TABLE name>
```

### DO aggregation

```
SELECT * FROM <TABLE name> AS c
GROUP BY <FIELD name>, .... ;
```

### Simple join

```
SELECT COUNT(\*) FROM <TABLE name> AS s
JOIN <TABLE name> AS c ON s.id = c.id;
```


### Create table
1. Create table
```
CREATE TABLE ws_users (
    user_id BIGINT,
    user_name STRING,
    user_email STRING,
    age INT,
    ts TIMESTAMP(3),
    -- Define the Primary Key
    PRIMARY KEY (user_id) NOT ENFORCED
)
```

2. see topic 

3. Insert data

```
INSERT INTO ws_users
VALUES (
    1, 
    'Alice Smith', 
    'alice@example.com', 
    28, 
    TIMESTAMP '2023-10-25 14:30:00'
),
(
    2, 
    'Bob Jones', 
    'bob@example.com', 
    35, 
    CURRENT_TIMESTAMP
);
```

4. CTAS (Creae Table As Select)
```
CREATE TABLE user_activity AS
SELECT
    user_id,
    COUNT(*) AS event_count,
    MAX(event_time) AS last_event_time
FROM raw_events
GROUP BY user_id;
```
