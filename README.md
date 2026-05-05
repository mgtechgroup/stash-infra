# Stash - Infrastructure & Services Stack

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](docker-compose.yml)
[![Nginx](https://img.shields.io/badge/Nginx-Proxy-orange.svg)]()
[![Security](https://img.shields.io/badge/Security-Hardened-green.svg)]()

## 🏗️ Overview

**Stash** is the infrastructure backbone powering the BLBGenSix AI ecosystem. It provides a comprehensive suite of containerized services including reverse proxy, caching, message queues, databases, monitoring, and security services.

Designed for high availability and security, Stash ensures reliable operation of all dependent applications with enterprise-grade hardening and monitoring.

---

## 📦 Services List & Descriptions

### Core Infrastructure

| Service | Image | Description | Port |
|---------|-------|-------------|------|
| **Nginx Proxy** | `nginx:alpine` | Reverse proxy, SSL termination, load balancer | 80/443 |
| **PostgreSQL** | `postgres:16-alpine` | Primary relational database | 5432 |
| **Redis** | `redis:7-alpine` | Cache, sessions, pub/sub, queues | 6379 |
| **Redis Commander** | `rediscommander/redis-commander` | Redis web management UI | 8081 |

### Message Queues & Workers

| Service | Image | Description | Port |
|---------|-------|-------------|------|
| **RabbitMQ** | `rabbitmq:3-management` | Message broker with management UI | 5672/15672 |
| **Worker** | `custom` | Laravel queue worker container | - |

### Search & Analytics

| Service | Image | Description | Port |
|---------|-------|-------------|------|
| **Meilisearch** | `getmeili/meilisearch:v1.6` | Fast, relevant search engine | 7700 |
| **Elasticsearch** | `elasticsearch:8.x` | Distributed search and analytics | 9200/9300 |

### Monitoring & Observability

| Service | Image | Description | Port |
|---------|-------|-------------|------|
| **Prometheus** | `prom/prometheus:latest` | Metrics collection and alerting | 9090 |
| **Grafana** | `grafana/grafana:latest` | Metrics visualization and dashboards | 3000 |
| **Node Exporter** | `prom/node-exporter:latest` | System metrics exporter | 9100 |
| **cAdvisor** | `gcr.io/cadvisor/cadvisor` | Container metrics exporter | 8080 |

### Logging

| Service | Image | Description | Port |
|---------|-------|-------------|------|
| **Loki** | `grafana/loki:latest` | Log aggregation system | 3100 |
| **Promtail** | `grafana/promtail:latest` | Log shipping agent | - |

### Security

| Service | Image | Description | Port |
|---------|-------|-------------|------|
| **Vault** | `hashicorp/vault:latest` | Secrets management | 8200 |
| **Fail2ban** | `linuxserver/fail2ban:latest` | Intrusion prevention | - |
| **ClamAV** | `clamav/clamav:latest` | Antivirus scanning | 3310 |

### Storage & Backups

| Service | Image | Description | Port |
|---------|-------|-------------|------|
| **MinIO** | `minio/minio:latest` | S3-compatible object storage | 9000/9001 |
| **Backup** | `custom` | Automated backup service | - |

---

## 🐳 Docker Compose Setup

### Prerequisites
- Docker 24.x+
- Docker Compose 2.x+
- 8GB+ RAM recommended
- 50GB+ free disk space

### Quick Start

```bash
# Clone the repository
git clone https://github.com/mgtechgroup/stash.git
cd stash

# Configure environment
cp .env.example .env
nano .env

# Start all services
docker-compose up -d

# Verify services are running
docker-compose ps

# View logs
docker-compose logs -f
```

### Environment Configuration

Edit `.env` file:
```env
# Domain Configuration
DOMAIN=blbgensixai.club
SSL_EMAIL=admin@blbgensixai.club

# Database Credentials
POSTGRES_DB=blbgensixai
POSTGRES_USER=postgres
POSTGRES_PASSWORD=secure_db_password

# Redis Configuration
REDIS_PASSWORD=secure_redis_password

# Vault Configuration
VAULT_ROOT_TOKEN=your_vault_root_token

# MinIO Configuration
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=secure_minio_password

# Grafana Configuration
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=secure_grafana_password

# Meilisearch
MEILI_MASTER_KEY=secure_meili_key

# Cloudflare (optional)
CLOUDFLARE_API_KEY=
CLOUDFLARE_ZONE_ID=
```

### Service Groups

Start specific service groups:
```bash
# Core infrastructure only
docker-compose up -d nginx postgres redis

# Monitoring stack
docker-compose up -d prometheus grafana node-exporter cadvisor

# Logging stack
docker-compose up -d loki promtail

# Security stack
docker-compose up -d vault fail2ban clamav
```

---

## 🔒 Security Hardening Details

### Nginx Security Configuration

Located in `nginx/security.conf`:
```nginx
# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self' ..." always;

# Rate limiting
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login:10m rate=2r/s;

# SSL hardening
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:50m;
```

### Vault Secrets Management

Initialize Vault:
```bash
# Start Vault
docker-compose up -d vault

# Initialize (run once)
docker-compose exec vault vault operator init -key-shares=5 -key-threshold=3

# Unseal Vault (required after restart)
docker-compose exec vault vault operator unseal <key1>
docker-compose exec vault vault operator unseal <key2>
docker-compose exec vault vault operator unseal <key3>

# Login
docker-compose exec vault vault login <root_token>
```

Store secrets:
```bash
# Store API keys
vault kv put secret/blbgensixai/openai-api-key value=sk-...

# Store database credentials
vault kv put secret/blbgensixai/postgres \
  username=postgres \
  password=secure_password

# Read secrets
vault kv get secret/blbgensixai/openai-api-key
```

### Fail2ban Configuration

Located in `security/fail2ban/`:
```ini
# /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
bantime = 7200

[nginx-botsearch]
enabled = true
filter = nginx-botsearch
logpath = /var/log/nginx/access.log
```

### ClamAV Antivirus

```bash
# Update virus definitions
docker-compose exec clamav freshclam

# Scan a directory
docker-compose exec clamav clamscan -r /data

# Automatic scanning (configured in docker-compose)
# Scans /data volume every 6 hours
```

### Network Isolation

Services communicate through isolated Docker networks:
```yaml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # No external access
  database:
    driver: bridge
    internal: true
```

Only Nginx proxy has external access; all other services are isolated.

---

## 📊 Monitoring Guide

### Prometheus Metrics

Access Prometheus at `http://localhost:9090`

Key metrics to monitor:
```promql
# Container CPU usage
sum(rate(container_cpu_usage_seconds_total[5m])) by (container)

# Memory usage
sum(container_memory_usage_bytes) by (container)

# HTTP request rate
rate(nginx_http_requests_total[5m])

# Database connections
pg_stat_database_numbackends{datname="blbgensixai"}

# Redis memory
redis_memory_used_bytes
```

### Grafana Dashboards

Access Grafana at `http://localhost:3000` (admin / configured password)

Import pre-built dashboards:
```bash
# Copy dashboard JSON files
cp dashboards/*.json /var/lib/grafana/dashboards/

# Or import via UI:
# Dashboards → Import → Upload JSON file
```

Available dashboards:
- **System Overview**: CPU, RAM, Disk, Network
- **Application Metrics**: Request rate, latency, errors
- **Database Performance**: Connections, queries, locks
- **Redis Metrics**: Memory, keys, hit rate
- **Docker Containers**: Per-container stats

### Alerting Rules

Configure in `monitoring/prometheus/alerts.yml`:
```yaml
groups:
  - name: stash_alerts
    rules:
      - alert: HighCPUUsage
        expr: sum(rate(container_cpu_usage_seconds_total[5m])) by (container) > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.container }}"

      - alert: DatabaseDown
        expr: up{job="postgres"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "PostgreSQL is down"
```

### Loki Log Aggregation

Access Loki at `http://localhost:3100`

Query logs in Grafana:
1. Add Loki as data source
2. Use LogQL queries:
   ```
   {container="nginx"} |= "error"
   {service="blbgensixai"} |= "exception"
   ```

### Health Check Endpoints

All services expose health checks:
```bash
# Nginx
curl http://localhost/health

# PostgreSQL
docker-compose exec postgres pg_isready

# Redis
docker-compose exec redis redis-cli ping

# Meilisearch
curl http://localhost:7700/health

# Vault
curl http://localhost:8200/v1/sys/health
```

---

## 🗂️ Project Structure

```
stash/
├── docker-compose.yml           # Main compose file
├── docker-compose.prod.yml      # Production overrides
├── .env.example                 # Environment template
├── 
├── nginx/                       # Nginx configurations
│   ├── conf.d/
│   │   ├── default.conf         # Main site config
│   │   ├── blbgensixai.club.conf
│   │   └── ssl.conf             # SSL configuration
│   ├── security.conf            # Security headers
│   └── nginx.conf               # Main config
│
├── postgres/                    # PostgreSQL configs
│   ├── init.sql                 # Initialization scripts
│   ├── postgresql.conf          # Custom config
│   └── pg_hba.conf              # Access control
│
├── redis/                       # Redis configurations
│   ├── redis.conf
│   └── persistence.conf
│
├── monitoring/                  # Monitoring stack
│   ├── prometheus/
│   │   ├── prometheus.yml       # Prometheus config
│   │   ├── alerts.yml           # Alert rules
│   │   └── targets.json        # Scrape targets
│   ├── grafana/
│   │   ├── dashboards/          # JSON dashboards
│   │   └── datasources/         # Data source configs
│   └── alertmanager/
│       └── alertmanager.yml
│
├── logging/                     # Logging stack
│   ├── loki/
│   │   └── loki-config.yaml
│   └── promtail/
│       └── promtail-config.yaml
│
├── security/                    # Security configs
│   ├── vault/
│   │   ├── config.hcl
│   │   └── policies/
│   ├── fail2ban/
│   │   ├── jail.local
│   │   └── filter.d/
│   └── clamav/
│       └── clamd.conf
│
├── scripts/                     # Utility scripts
│   ├── backup.sh                # Backup script
│   ├── restore.sh               # Restore script
│   ├── health-check.sh          # Health check
│   └── unseal-vault.sh          # Vault unseal
│
├── certs/                       # SSL certificates
│   ├── live/                    # Let's Encrypt certs
│   └── cloudflare/              # Cloudflare origin certs
│
└── data/                        # Persistent volumes
    ├── postgres/
    ├── redis/
    ├── meilisearch/
    └── minio/
```

---

## 🚀 Common Operations

### Backup All Data

```bash
# Run backup script
./scripts/backup.sh

# Manual backup
# PostgreSQL
docker-compose exec postgres pg_dump -U postgres blbgensixai > backup_$(date +%Y%m%d).sql

# Redis
docker-compose exec redis redis-cli BGSAVE

# MinIO (use mc client)
docker-compose exec minio mc mirror /data /backup
```

### Restore from Backup

```bash
# PostgreSQL
cat backup_20240115.sql | docker-compose exec -T postgres psql -U postgres blbgensixai

# Restore Vault secrets
vault operator restore -sha256 < backup.vault
```

### Update Services

```bash
# Pull latest images
docker-compose pull

# Recreate containers with new images
docker-compose up -d --force-recreate

# Clean up old images
docker image prune -a
```

### Scale Services

```bash
# Scale workers
docker-compose up -d --scale worker=5

# Scale nginx (requires load balancer)
docker-compose up -d --scale nginx=2
```

---

## 📞 Support

- **GitHub Issues**: [Report infrastructure issues](https://github.com/mgtechgroup/stash/issues)
- **Documentation**: [Full infrastructure docs](https://docs.blbgensixai.club/infrastructure)
- **Email**: ops@blbgensixai.club

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- HashiCorp for Vault
- Prometheus & Grafana communities
- All open-source projects that power this infrastructure stack
