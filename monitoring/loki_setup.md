# Loki Monitoring Setup

## Components
- Loki: Stores application logs.
- Promtail: Collects Docker container logs.
- Grafana: Visualizes logs.

## Start Monitoring

docker compose -f monitoring/docker-compose.yaml up -d

## Verify Services

docker ps

## Grafana

URL: http://localhost:3000
Username: admin
Password: admin

## Loki Data Source

URL: http://loki:3100

## LogQL Queries

View all NGINX logs:

{job="nginx"}

Find NGINX container logs:

{container=~".*nginx.*"}

## Test Error Logs

curl http://localhost:20791/page-not-found
