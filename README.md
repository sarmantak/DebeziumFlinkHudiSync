# Debezium Flink Hudi Sync

A data synchronization pipeline that captures changes from MySQL using Debezium, streams them through Kafka, processes them with Apache Flink, and stores the data in Apache Hudi. This enables real-time data lakehouse capabilities with both Trino and Spark for analytics.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Services & Access](#services--access)
- [Common Commands](#common-commands)
- [Project Structure](#project-structure)
- [Troubleshooting](#troubleshooting)

## Overview

This project implements a modern data stack for real-time data synchronization:
- **Source**: MySQL database with change data capture (CDC)
- **Transport**: Apache Kafka for streaming (input and output)
- **Processing**: Apache Flink for stream processing and transformations
- **Lake Format**: Apache Hudi and Delta Lake formats for lakehouse
- **Streaming**: Delta Lake streaming for incremental data updates
- **Metadata**: Hive Metastore (PostgreSQL) for table metadata management
- **Storage**: MinIO (S3-compatible) for object storage
- **Query**: Trino for analytics on lakehouse data

## Architecture

```
MySQL → Debezium → Kafka → Flink → Kafka → Spark-Hudi → MinIO → Trino
 (CDC)              (Stream)         (Stream)  (Lake)   (Storage) (Query)
                                                   ↓
                                     Delta Lake Streaming
                                                   ↓
                                            Hive Metastore
                                            (PostgreSQL)
```

**Pipeline Flow:**
1. **MySQL** - Source database with CDC enabled
2. **Debezium** - Captures change data and streams to Kafka
3. **Kafka (Input)** - Message broker for CDC events
4. **Flink** - Stream processing and data transformation
5. **Kafka (Output)** - Intermediate stream after Flink processing
6. **Spark-Hudi** - Writes processed data to Hudi data lake format
7. **Delta Lake Streaming** - Enables incremental streaming updates to lakehouse tables
8. **Hive Metastore** - Manages table metadata (backed by PostgreSQL)
9. **MinIO** - S3-compatible object storage for data lake files
10. **Trino** - SQL query engine for analytics on lakehouse data

## Prerequisites

- **Docker & Docker Compose** - For orchestrating services
- **Python 3.9+** - For JupyterLab and Flink notebooks
- **wget or curl** - For downloading large JAR files
- **Sufficient disk space** - Minimum 50GB recommended for volumes
- **Linux/macOS** - Tested on macOS and Linux (Windows WSL2 may work)
- **Java 11+** - For Flink and Spark (included in containers)

## Quick Start

1. **Navigate to project directory**:
   ```bash
   cd ~/projects/DebeziumFlinkHudiSync
   ```

2. **Download Hudi JAR** (large file, not included in repo):
   ```bash
   mkdir -p hudi-jars
   wget https://repo.maven.apache.org/maven2/org/apache/hudi/hudi-utilities-slim-bundle_2.12/0.15.0/hudi-utilities-slim-bundle_2.12-0.15.0.jar \
     -O hudi-jars/hudi-utilities-slim-bundle_2.12-0.15.0.jar
   ```

3. **Start all services**:
   ```bash
   ACCEPT_EULA=true docker-compose up -d
   ```

4. **Verify services are running**:
   ```bash
   docker-compose ps
   ```

5. **Access web interfaces** (see [Services & Access](#services--access) below)

6. **Stop services** (when done):
   ```bash
   docker-compose down
   ```

## Workflow & Running Jobs

After all services have started, follow these steps to run the complete data pipeline:

### Step 1: Create Debezium Connectors (CDC)

The Debezium connectors must be created FIRST to capture MySQL data changes:

```bash
# List available Kafka Connect plugins
docker-compose exec kafka curl -s http://kafka:8083/connector-plugins | jq . | grep -i mysql

# Create MySQL Debezium connector for customers
cat ./debezium/mysql-inventory-customers.json | docker-compose exec -T kafka curl -i \
  -X POST -H "Content-Type:application/json" http://localhost:8083/connectors -d @-

# Create MySQL Debezium connector for orders
cat ./debezium/mysql-inventory-orders.json | docker-compose exec -T kafka curl -i \
  -X POST -H "Content-Type:application/json" http://localhost:8083/connectors -d @-

# View Kafka Connect logs
docker exec debeziumflinkhudisync_kafka_1 tail -200 /var/log/connect-distributed.log
docker exec debeziumflinkhudisync_kafka_1 tail -f /var/log/connect-distributed.log
```

Wait for connectors to be running and verify topics are being populated with CDC data.

### Step 2: Start JupyterLab and Execute Flink Jobs

From the project directory:

```bash
cd ~/projects/DebeziumFlinkHudiSync
jupyter lab --ip=0.0.0.0
```

Or with virtual environment:
```bash
cd ~/jupyterlab_project
source venv/bin/activate
jupyter lab --ip=0.0.0.0
```

JupyterLab will be available at `http://localhost:8888`

Then open `flink.ipynb` and run the notebook cells to:
- Set up Flink stream processing jobs
- Configure CDC sources (MySQL via Debezium Kafka topics)
- Process streaming data through Kafka
- Output to Kafka topics for downstream consumption

### Step 3: Run Spark-Hudi Container Job

Start the Spark job that reads from Kafka and writes to Hudi/Delta Lake:

```bash
cd ~/projects/DebeziumFlinkHudiSync
docker-compose -f docker-compose-spark.yml up -d
```

Monitor the Spark job:
```bash
docker logs -f spark-hudi
```

Or save logs to file:
```bash
docker logs spark-hudi > spark_hudi_snapshot.log 2>&1
docker logs --tail 1000 spark-hudi > spark_hudi_tail.log 2>&1
```

### Step 4: Verify Pipeline

After all jobs are running:
1. **Check Kafka topics** for processed data
2. **Query Hudi/Delta tables** via Trino
3. **Monitor MinIO** for data lake files
4. **View Hive Metastore** for table metadata

## Services & Access

| Service | URL/Host | Credentials |
|---------|----------|-------------|
| Lenses UI | http://localhost:9991 | admin / admin |
| Kafka Broker | localhost:9092 | - |
| Schema Registry | http://localhost:8081 | - |
| Kafka Connect | localhost:8083 | - |
| MySQL | localhost:3306 | mysqluser / mysqlpw |
| PostgreSQL (Metastore) | localhost:5432 | metastore / metastore_pw |
| Hive Metastore | localhost:9083 | - |
| Spark (Hudi Writer) | http://localhost:8088 | - |
| Trino Coordinator (Analytics) | http://localhost:8080 | - |
| MinIO Console | http://localhost:9001 | minioadmin / minioadmin |

## Common Commands

### Docker Compose Management

```bash
# Start services
ACCEPT_EULA=true docker-compose up -d

# Check status
docker-compose ps

# View logs (all services)
docker-compose logs -f

# View logs for specific service
docker-compose logs -f mysql
docker-compose logs -f trino-coordinator

# Stop services (keep data)
docker-compose down

# Stop services and remove all data
docker-compose down -v

# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart trino-coordinator

# Rebuild and start services
docker-compose up -d --build
docker-compose -f docker-compose-spark.yml up -d --build
```

### MySQL Commands

```bash
# Connect as root user
docker exec -it mysql mysql -h mysql -u root -pdebezium

# Connect as application user
docker exec -it mysql mysql -h mysql -u mysqluser -pmysqlpw

# Connect to specific database
docker exec -it mysql mysql -h mysql -u mysqluser -pmysqlpw inventory

# List databases
docker exec -it mysql mysql -u mysqluser -pmysqlpw -e "SHOW DATABASES;"

# Insert sample data
docker exec -it mysql mysql -h mysql -u mysqluser -pmysqlpw inventory <<EOF
INSERT INTO orders (order_date, purchaser, quantity, product_id) VALUES ('2026-04-16', 1001, 5, 107);
EOF
```

### Kafka Commands

```bash
# List all topics
docker exec -it demo-kafka kafka-topics --bootstrap-server localhost:9092 --list

# Create a new topic
docker exec -it demo-kafka kafka-topics --bootstrap-server localhost:9092 --create \
  --topic test-topic --partitions 1 --replication-factor 1

# Describe topic
docker exec -it demo-kafka kafka-topics --bootstrap-server localhost:9092 --describe --topic test-topic

# Consume messages from beginning
docker exec -it demo-kafka kafka-console-consumer --bootstrap-server localhost:9092 \
  --topic test-topic --from-beginning

# List Kafka Connect connectors
docker-compose exec kafka curl -H "Accept:application/json" http://kafka:8083/connectors
```

### PostgreSQL (Metastore) Commands

```bash
# Connect to PostgreSQL metastore
docker exec -it metastore-db psql -U metastore -d metastore_db

# List all tables in metastore database
docker exec -it metastore-db psql -U metastore -d metastore_db -c "\dt"

# View Hive tables
docker exec -it metastore-db psql -U metastore -d metastore_db -c "SELECT * FROM tbls;"

# View table columns
docker exec -it metastore-db psql -U metastore -d metastore_db -c "SELECT * FROM columns_v2;"
```

### Hive Metastore

Hive Metastore stores metadata about Hudi and Delta Lake tables and is essential for:
- **Spark** - Writes processed data to Hudi and Delta Lake tables with proper schema registration
- **Trino** - Queries Hudi and Delta Lake tables via Hive connector for analytics
- **Table Management** - Tracks table structure, partitions, and properties

The metastore is backed by PostgreSQL and runs as a service accessible on port 9083.

### Delta Lake Streaming

Delta Lake provides ACID transactions and streaming capabilities for lakehouse tables:
- **Incremental Updates** - Streams data incrementally into tables
- **Schema Evolution** - Automatically handles schema changes
- **Time Travel** - Query historical versions of data
- **Data Quality** - Enforces constraints and data validation
- **Unified Metadata** - Works with Hive Metastore for consistent metadata

Delta Lake complements Hudi for flexible lakehouse operations and streaming scenarios.

## Project Structure

```
DebeziumFlinkHudiSync/
├── docker-compose.yml              # Main services orchestration
├── docker-compose-spark.yml        # Spark-specific configuration
├── flink.ipynb                      # Flink stream processing jobs
├── README.md                        # This file
│
├── mysql/                           # MySQL initialization scripts
├── debezium/                        # Debezium CDC connector configurations
├── trino/                           # Trino SQL query engine configuration
├── spark-conf/                      # Spark configuration
├── hudi-jars/                       # Hudi library dependencies (download required)
└── postgresscripts/                 # PostgreSQL/Hive Metastore scripts
```

**Note on hudi-jars:**
- The `hudi-utilities-slim-bundle_2.12-0.15.0.jar` file (103 MB) is not included in the repository due to GitHub's 100 MB file size limit
- Download it using the command in [Quick Start](#quick-start) step 2
- Alternatively, add to `.gitignore` and download manually before running services

## Troubleshooting

### Services Won't Start
- Check Docker daemon is running: `docker ps`
- Review logs: `docker-compose logs`
- Ensure ports are not in use: `lsof -i :9091,9092,8083` etc.

### Connection Refused Errors
- Wait for services to fully start (may take 30-60 seconds)
- Check service health: `docker-compose ps`
- Verify network: `docker network ls`

### Data Persistence Issues
- Docker volumes store data - check available disk space
- To reset completely: `docker-compose down -v`
- Spark checkpoints saved to persistent volumes

### Performance Issues
- Monitor resource usage: `docker stats`
- Check available disk space
- Review log files for errors

## Additional Resources

- [Debezium Documentation](https://debezium.io)
- [Apache Kafka Documentation](https://kafka.apache.org)
- [Apache Flink Documentation](https://flink.apache.org)
- [Apache Hudi Documentation](https://hudi.apache.org)
- [Delta Lake Documentation](https://docs.delta.io)
- [Hive Metastore Documentation](https://cwiki.apache.org/confluence/display/Hive/Design)
- [Trino Documentation](https://trino.io)
- [MinIO Documentation](https://min.io)

## Advanced Operations

### MinIO/S3 Operations

```bash
# List objects in MinIO data lake
docker run --rm --network lakehouse --entrypoint /bin/sh minio/mc -c "\
  mc alias set myminio http://minio:9000 admin password; \
  mc ls --recursive myminio/warehouse/processed_orders"
```

### Trino Interactive SQL

```bash
# Access Trino CLI
docker exec -it trino-coordinator trino

# Inside Trino CLI:
SHOW CATALOGS;
USE hudi.default;
SELECT * FROM processed_orders LIMIT 10;
```

### Docker Cleanup & Maintenance

```bash
# Fix Docker network communication issues
sudo systemctl stop docker.socket

# Prune unused volumes and networks
docker volume prune
docker network prune

# Clean build cache
docker builder prune

# View disk usage by containers
docker system df
```