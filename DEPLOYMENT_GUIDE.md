# Consolidated Docker Stack Deployment Guide
# Stash + UniScrape + Whisparr + Namer + Infrastructure
# Date: 2026-05-04

## Overview

This unified docker-compose stack consolidates all services into a single, production-grade deployment with:

- **10 Core Services**: Stash (hotio nightly), Namer, UniScrape, Whisparr, PostgreSQL, Redis, Chrome CDP, Nginx, Transmission, Portainer
- **Security Hardening**: Resource limits, capability dropping, read-only filesystems, health checks, rate limiting
- **Network Isolation**: Backend bridge network (172.20.0.0/16)
- **SSL/TLS Termination**: Nginx with HSTS, CSP, X-Frame-Options headers
- **Performance Optimization**: Layer caching, gzip compression, connection pooling

## File Structure

```
stash/
├── docker-compose.unified.yml       # Main compose file (10 services)
├── nginx/
│   ├── nginx.conf                   # Security-hardened reverse proxy
│   ├── ssl/
│   │   ├── cert.pem                 # Self-signed certificate
│   │   └── key.pem                  # Private key
│   └── html/
│       └── index.html               # Static landing page
├── postgres/
│   └── init-scripts/                # Database initialization scripts
├── SECURITY_AUDIT_REPORT.txt        # Hardening report
└── security-hardening.ps1           # PowerShell hardening script
```

## Prerequisites

- Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- 8+ GB RAM
- 50+ GB free disk space
- Windows: Administrator rights for firewall rules

## Quick Start

### 1. Prepare Environment

```powershell
cd stash
# Create required directories
mkdir nginx/ssl, nginx/html, postgres/init-scripts -Force

# Run security hardening
powershell -ExecutionPolicy Bypass -File security-hardening.ps1
```

### 2. Generate SSL Certificates (Self-Signed)

For development/testing:
```powershell
# Using OpenSSL (if installed)
openssl req -x509 -newkey rsa:2048 -keyout nginx/ssl/key.pem -out nginx/ssl/cert.pem -days 365 -nodes

# Or use PowerShell
$cert = New-SelfSignedCertificate -Subject "CN=localhost" -KeyLength 2048 -NotAfter (Get-Date).AddYears(1)
# Export and convert as needed
```

For production: Use proper CA certificates (Let's Encrypt, commercial CA, etc.)

### 3. Configure Services

Edit `docker-compose.unified.yml` to customize:

```yaml
# PostgreSQL credentials (change in production)
environment:
  POSTGRES_PASSWORD: uniscrape  # CHANGE THIS

# Redis password (change in production)
command: >
  redis-server
  --requirepass redispass123    # CHANGE THIS

# Namer configuration
volumes:
  - namer_config:/config:rw     # Will contain namer.cfg
```

### 4. Start Stack

```powershell
cd stash
docker compose -f docker-compose.unified.yml up -d
```

### 5. Verify Services

```powershell
# Check all services
docker compose -f docker-compose.unified.yml ps

# Check logs
docker compose -f docker-compose.unified.yml logs -f

# Test health checks
docker compose -f docker-compose.unified.yml ps --format "{{.Names}}: {{.Status}}"
```

## Service Endpoints

| Service | Port | URL | Notes |
|---------|------|-----|-------|
| Stash | 9999 | http://localhost:9999 | Media manager |
| Namer | 6980 | http://localhost:6980 | Scene naming/organization |
| UniScrape | 9876 | http://localhost:9876 | Scraper API |
| Whisparr | 6969 | http://localhost:6969 | Audio/music organizer |
| Nginx HTTP | 80 | http://localhost | Redirects to HTTPS |
| Nginx HTTPS | 443 | https://localhost | SSL termination |
| PostgreSQL | 5432 | localhost:5432 | Internal only |
| Redis | 6379 | localhost:6379 | Internal only |
| Chrome CDP | 9222 | localhost:9222 | Headless browser |
| Transmission | 9091 | http://localhost:9091 | Torrent/DHT client |
| Portainer | 9000 | http://localhost:9000 | Container management UI |

## Accessing Services

### Via Nginx (Recommended - SSL/TLS)
```bash
# HTTPS (self-signed certificate - ignore browser warnings)
https://localhost/stash
https://localhost/namer
https://localhost/whisparr
https://localhost/api/...        # UniScrape API
https://localhost/scrape/...     # UniScrape scraping
```

### Direct (Development Only)
```bash
# Direct without Nginx
http://localhost:9999            # Stash
http://localhost:6980            # Namer
http://localhost:9876            # UniScrape
http://localhost:6969            # Whisparr
```

## Database Access

### PostgreSQL Connection
```bash
# From host (port 5432 mapped to localhost - configure as needed)
psql -h localhost -U uniscrape -d uniscrape

# From Docker container
docker exec -it postgres psql -U uniscrape -d uniscrape
```

### Redis Access
```bash
# Direct connection
redis-cli -h localhost -p 6379 -a redispass123

# From Docker container
docker exec -it redis redis-cli -a redispass123
```

## Stopping & Cleanup

```powershell
# Stop all services (keep volumes)
docker compose -f docker-compose.unified.yml down

# Stop and remove all data
docker compose -f docker-compose.unified.yml down -v

# Remove specific volume
docker volume rm stash_data
```

## Resource Limits

Services are configured with CPU and memory limits:

```yaml
whisparr:
  deploy:
    resources:
      limits:
        cpus: '1'
        memory: 512M
      reservations:
        cpus: '0.5'
        memory: 256M
```

Adjust based on your hardware:
- **Small machine (4GB RAM)**: Reduce Stash to 2GB, UniScrape to 1GB, others to 256MB
- **Medium machine (8GB RAM)**: Current limits are appropriate
- **Large machine (16GB+ RAM)**: Increase Stash to 8GB, UniScrape to 3GB, Chrome to 4GB

## Monitoring & Logs

```powershell
# Follow all logs
docker compose -f docker-compose.unified.yml logs -f

# Follow specific service
docker compose -f docker-compose.unified.yml logs -f stash

# View only recent logs (last 50 lines)
docker compose -f docker-compose.unified.yml logs --tail=50 namer

# Check service health
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "healthy|unhealthy"
```

## Common Issues

### Port Already in Use
```powershell
# Find process using port
netstat -aon | findstr :9999
taskkill /PID <PID> /F

# Or change port in docker-compose.yml
# ports:
#   - "9998:9999"  # Changed from 9999
```

### Certificate/SSL Errors
```powershell
# Regenerate self-signed certificate
rm stash/nginx/ssl/cert.pem, stash/nginx/ssl/key.pem
# Re-run security-hardening.ps1
```

### Service Failing to Start
```powershell
# Check logs
docker logs <container_name>

# Restart single service
docker compose -f docker-compose.unified.yml restart stash

# Rebuild with no cache
docker compose -f docker-compose.unified.yml up -d --build --no-cache
```

### Database Connection Issues
```powershell
# Check PostgreSQL health
docker exec postgres pg_isready

# Reset PostgreSQL
docker volume rm stash_postgres_data
docker compose -f docker-compose.unified.yml up -d postgres
```

## Production Deployment

For production, modify:

1. **Credentials**:
   ```yaml
   POSTGRES_PASSWORD: <strong-random-password>
   requirepass: <strong-random-password>
   ```

2. **SSL Certificates**:
   ```bash
   # Use Let's Encrypt with certbot
   certbot certonly --standalone -d yourdomain.com
   cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem stash/nginx/ssl/cert.pem
   cp /etc/letsencrypt/live/yourdomain.com/privkey.pem stash/nginx/ssl/key.pem
   ```

3. **Backup Strategy**:
   ```powershell
   # Backup PostgreSQL
   docker exec postgres pg_dump -U uniscrape uniscrape > backup.sql
   
   # Backup volumes
   docker run --rm -v stash_data:/data -v C:\backups:/backup alpine tar czf /backup/stash_data.tar.gz /data
   ```

4. **Reverse Proxy** (nginx/Traefik):
   - Place behind SSL-terminating reverse proxy
   - Enable rate limiting per IP
   - Configure DNS records
   - Set up monitoring/alerting

## Performance Tuning

### Increase Cache Sizes
```yaml
redis:
  command: >
    redis-server
    --maxmemory 1gb              # Increase from 512mb
    --maxmemory-policy allkeys-lru

postgres:
  environment:
    POSTGRES_INITDB_ARGS: "--shared_buffers=256MB --effective_cache_size=1GB"
```

### Scale UniScrape (Docker Swarm/Kubernetes only)
```yaml
uniscrape:
  deploy:
    replicas: 3
```

### Enable BuildKit for Faster Builds
```powershell
$env:DOCKER_BUILDKIT=1
docker compose -f docker-compose.unified.yml build --no-cache
```

## Security Best Practices

1. **Change default passwords** (PostgreSQL, Redis)
2. **Use proper SSL certificates** (Let's Encrypt, not self-signed)
3. **Enable firewall rules** (run security-hardening.ps1)
4. **Run periodic security audits** (npm audit, docker scout)
5. **Keep images updated** (docker pull, docker compose pull)
6. **Monitor logs** for suspicious activity
7. **Backup data regularly** (PostgreSQL, volumes)
8. **Use strong authentication** for API endpoints

## Updates & Maintenance

### Update Images
```powershell
docker compose -f docker-compose.unified.yml pull
docker compose -f docker-compose.unified.yml up -d
```

### Update Stash Nightly
```powershell
docker pull ghcr.io/hotio/stash:nightly-<latest-tag>
# Update docker-compose.yml
docker compose -f docker-compose.unified.yml up -d
```

### Database Migrations
```powershell
# PostgreSQL will auto-migrate on startup
# Monitor logs
docker logs postgres
```

## Support & Documentation

- Stash: https://docs.stashapp.cc/
- Namer: https://github.com/theporndatabase/namer
- UniScrape: https://github.com/mgtechgroup/UniScrape
- Whisparr: https://whisparr.com/
- Docker: https://docs.docker.com/

---

**Last Updated**: 2026-05-04
**Version**: 1.0.0 (Unified Stack)
