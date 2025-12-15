# Flink workshop

## Table Prep

### Get all data
SELECT * FROM <TABLE name>


### DO aggregation
SELECT * FROM <TABLE name> AS c
GROUP BY <FIELD name>, .... ;


### Simple join
SELECT COUNT(\*) FROM <TABLE name> AS s
JOIN <TABLE name> AS c ON s.id = c.id;


