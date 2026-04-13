# Debezium Flink Hudi Sync

## Docker Commands

### Start Services
```bash
cd /home/almat/projects/DebeziumFlinkHudiSync
ACCEPT_EULA=true docker-compose up -d
```

### Check Status
```bash
docker-compose ps
```

### View Logs
```bash
docker-compose logs -f
docker-compose logs -f mysql
docker-compose logs -f demo-kafka
docker-compose logs -f lenses-hq
```

### Stop Services
```bash
docker-compose down
```

### Stop and Remove All Data
```bash
docker-compose down -v
```

### Restart Services
```bash
docker-compose restart
```

### Rebuild and Start
```bash
docker-compose up -d --build
```

## Service Access

- **Lenses UI**: http://localhost:9991 (admin/admin)
- **Kafka Broker**: localhost:9092
- **Schema Registry**: http://localhost:8081
- **Kafka Connect**: localhost:8083
- **MySQL**: localhost:3306 (mysqluser/mysqlpw)

## MySQL Commands

### Connect to MySQL
```bash
docker exec -it mysql mysql -u mysqluser -pmysqlpw inventory
```

### List Databases
```bash
docker exec -it mysql mysql -u mysqluser -pmysqlpw -e "SHOW DATABASES;"
```

## Kafka Commands

### List Topics
```bash
docker exec -it demo-kafka kafka-topics --bootstrap-server localhost:9092 --list
```

### Create Topic
```bash
docker exec -it demo-kafka kafka-topics --bootstrap-server localhost:9092 --create --topic test-topic --partitions 1 --replication-factor 1
```

### Describe Topic
```bash
docker exec -it demo-kafka kafka-topics --bootstrap-server localhost:9092 --describe --topic test-topic
```

### Consume Messages
```bash
docker exec -it demo-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic test-topic --from-beginning
```

```bash
docker exec -it mysql mysql -h mysql -u root -pdebezium
docker exec -it mysql mysql -h mysql -u mysqluser -pmysqlpw
docker exec -it mysql mysql -h mysql -u mysqluser -pmysqlpw inventory

docker-compose exec kafka curl -H "Accept:application/json" http://kafka:8083/connectors
docker-compose exec kafka curl -s http://kafka:8083/connector-plugins | jq . | grep -i mysql


cat ./debezium/mysql-inventory-customers.json | docker-compose exec -T kafka curl -i -X POST -H "Content-Type:application/json" http://localhost:8083/connectors -d @-

```