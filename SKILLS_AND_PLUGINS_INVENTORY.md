# Docker Stack Skills & Plugins Inventory
# Unified Ecosystem - Tools, Services, & Integrations
# Date: 2026-05-05

## 🚀 CORE SERVICES (11 Services + Tools)

### 1. **Stash** (Media Manager)
- **Type**: Go-based media library management
- **Port**: 9999
- **Image**: ghcr.io/hotio/stash:nightly-01a7583364b97478dd582826fdfe9bff96c0ce97
- **Skills**: Scene organization, metadata management, plugin support
- **Integration**: Namer (auto-naming), CommunityScrapers (802 YAML scrapers)
- **GitHub**: https://github.com/stashapp/stash

### 2. **Namer** (Scene Automation)
- **Type**: Automated scene naming/organization
- **Port**: 6980
- **Image**: ghcr.io/theporndatabase/namer:latest
- **Skills**: Batch renaming, metadata extraction, pattern matching
- **Integration**: Stash (direct integration)
- **GitHub**: https://github.com/theporndatabase/namer

### 3. **UniScrape** (Scraper API)
- **Type**: Node.js/Express REST API
- **Port**: 9876
- **Stack**: PostgreSQL, Redis, Chrome CDP
- **Skills**: 
  - REST API endpoints (/stremio, /plex, /jellyfin, /stash, /scrape, /metadata, /manager, /torrent, /tools/rss, /tools/meta, /saas)
  - Proxy rotation (ProxyCrawl integration)
  - HTML-to-RSS conversion
  - Link metadata extraction
  - Image processing (libvips)
- **GitHub**: https://github.com/mgtechgroup/UniScrape

### 4. **Whisparr** (Audio Organizer)
- **Type**: Audio/Music library management
- **Port**: 6969
- **Image**: hotio/whisparr:latest (v3.3.3-release.683)
- **Skills**: Music discovery, album organization, quality profiles
- **Compatible With**: Stash, transmission, automation
- **GitHub**: https://github.com/Whisparr/Whisparr

### 5. **Open Liberty** (Java Application Server)
- **Type**: Jakarta EE 10 / MicroProfile 5.0
- **Port**: 9080 (HTTP), 9443 (HTTPS)
- **Image**: open-liberty:latest (26.0.0.3)
- **Skills**:
  - RESTful API development (JAX-RS/Jakarta REST)
  - MicroProfile services (health checks, metrics, config)
  - Database access (JDBC/JPA with PostgreSQL)
  - OpenAPI 3.1 documentation
  - JWT SSO authentication
  - Microservices architecture
- **Features**: WebProfile-10.0, OpenAPI-3.1, mpMetrics-5.0, mpHealth-4.0, jwtSso-1.0
- **GitHub**: https://github.com/OpenLiberty/open-liberty

### 6. **IMDB Scraper** (Web Scraper API)
- **Type**: Node.js Nightmare.js + Express.js
- **Port**: 3000
- **Image**: mgtechgroup/imdb-scraper:latest
- **Skills**:
  - Movie/TV series data scraping (titles, ratings, metadata)
  - Poster/image downloading
  - Headless browser automation (Chromium)
  - REST API endpoints (/api/scrape/titles, /api/scrape/posters, /api/scrape/images, /api/scrape/movie/:id)
  - Health checks, metrics, status reporting
- **Technologies**: Nightmare.js, Cheerio, Express.js, Chromium
- **GitHub**: https://github.com/mariazevedo88/imdb-scraper

### 7. **PostgreSQL** (Relational Database)
- **Type**: SQL database
- **Port**: 5432 (internal only)
- **Image**: postgres:16-alpine
- **Skills**: ACID compliance, JSONB support, FTS, window functions, temporal queries
- **Data**: UniScrape metadata, user data, cross-service querying
- **Backup**: Automated via Docker volumes

### 8. **Redis** (Cache & Session Store)
- **Type**: In-memory data structure store
- **Port**: 6379 (internal only)
- **Image**: redis:7-alpine
- **Skills**: Session caching, rate limiting, pub/sub messaging, sorted sets, streams
- **Config**: 512MB max memory, allkeys-lru policy, persistence enabled
- **Integration**: UniScrape session management, cross-service cache

### 9. **Chrome Headless** (Browser Automation)
- **Type**: Headless Chromium via CDP
- **Port**: 9222 (internal only)
- **Image**: chromedp/headless-shell:latest
- **Skills**: Headless browser rendering, screenshot capture, JavaScript execution, DOM interaction
- **Integration**: IMDB Scraper (poster image extraction), UniScrape (JS-heavy pages)

### 10. **Nginx** (Reverse Proxy + SSL Termination)
- **Type**: Reverse proxy, load balancer, SSL/TLS termination
- **Ports**: 80 (HTTP → HTTPS), 443 (HTTPS)
- **Image**: nginx:alpine
- **Skills**:
  - SSL/TLS termination (HSTS, CSP headers)
  - Rate limiting per endpoint (general: 10 req/s, scrape: 5 req/s, API: 100 req/min)
  - Request routing by path (/stash, /namer, /api, /scrape, /whisparr, /liberty, /imdb)
  - Compression (gzip), caching, connection pooling
  - Security headers (X-Frame-Options, X-Content-Type-Options, etc.)
- **Routes**: Stash (9999), Namer (6980), UniScrape (9876), Whisparr (6969), Liberty (9080), IMDB (3000)

### 11. **Transmission** (Torrent/DHT Client)
- **Type**: Torrent client with DHT support
- **Port**: 9091 (Web UI), 51413 (P2P UDP)
- **Image**: linuxserver/transmission:latest
- **Skills**: Torrent downloading, DHT node, magnet links, bandwidth management
- **Integration**: UniScrape (metadata lookup), media sourcing
- **GitHub**: https://github.com/transmission/transmission

### 12. **Portainer** (Container Management UI)
- **Type**: Docker container management interface
- **Port**: 9000 (Web UI)
- **Image**: portainer/portainer-ce:alpine
- **Skills**: Visual container management, logs viewing, stats monitoring, image management
- **Integration**: Full stack visibility and control

---

## 🛠️ ADDITIONAL TOOLS & PLUGINS (Available on Machine)

### Media & Scraping Tools

**SourceScraper** (746 files)
- Multi-anime scraper framework
- 9 integrated scrapers: GogoAnime, KissAnime, MasterAnime, MP4Upload, MyStream, 9xbuddy, OpenLoad, etc.
- **Skill**: Anime/streaming source discovery

**html2rss** (Ruby, 270 files)
- HTML-to-RSS feed converter
- **Skill**: Feed generation from arbitrary HTML

**ProxyCrawl** (Node.js + PHP, 41 files)
- Proxy rotation and anti-scraping bypass
- **Skill**: Circumvent IP bans, handle JavaScript rendering

**scraperx** (Python, 49 files)
- General-purpose web scraping framework
- **Skill**: Flexible HTML parsing and extraction

**scraply** (Ruby, 11 files)
- Ruby-based scraper library
- **Skill**: Clean scraping DSL

**link-meta-extractor** (16 files)
- OpenGraph/metadata extraction
- **Skill**: Extract meta from any URL (title, description, images)

### Image Processing

**libvips** (7 repos, 53 files)
- Fast image processing library
- Bindings: Python (pyvips), PHP (php-vips), Ruby (ruby-vips)
- **Skills**:
  - Image resizing, cropping, rotation
  - Format conversion (JPEG, PNG, WebP, etc.)
  - Thumbnail generation
  - EXIF data handling
  - Batch processing

### Docker Infrastructure

**docker-iot-dashboard** (86 files)
- IoT monitoring dashboard
- Services: API server, cron backups, Expo, InfluxDB, MQTT, Node-RED, Postfix, Nginx
- **Skills**: Time-series monitoring, MQTT messaging, workflow automation

**docker-home-server** (32 files)
- Home automation stack
- Services: HomeAssistant, Homepage, Media Server, Monitoring, Nextcloud, Pi-hole, Portainer, Speedtest, Traefik
- **Skills**: Network management, DNS blocking, reverse proxy

**docker-nginx-https** (11 files)
- Pre-configured SSL-enabled Nginx
- **Skills**: Automatic cert rotation, multi-domain support

**easy-multidomain-docker-server** (14 files)
- Multi-domain hosting solution
- Services: Nginx proxy, dev cert updater
- **Skill**: Multi-tenant Docker hosting

**home-media-server** (32 files)
- Complete media server stack
- **Skills**: Plex, Jellyfin, Stremio integration

### Stash Ecosystem

**CommunityScrapers** (1,006 files, 802 YAML scrapers)
- Pre-built scrapers for Stash
- Sources: Adult industry databases, metadata providers
- **Skills**: Batch metadata lookup, fuzzy matching

**CommunityScripts** (542 files)
- User-contributed Stash plugins/scripts
- **Skills**: Automation, custom workflows, API integration

**StashServer** (Go, 178 files)
- Go-based Stash backend reference
- **Skills**: Go microservices, gRPC integration

**StashFrontend** (React, 153 files)
- React-based Stash UI
- **Skills**: React component library, media browsing UI

### Torrent & P2P

**BiglyBT** (BitTorrent client with DHT)
- **Skills**: Advanced torrent management, plugin system

**bzTorrent**
- **Skills**: Torrent metadata retrieval

**Torrent-Updater**
- **Skills**: Automated torrent feed management

**WebTorrentX**
- **Skills**: WebRTC-based torrent streaming

### Node.js & JavaScript Tools

**Ophiuchi Desktop** (161 files)
- Next.js + Tauri desktop application
- **Skills**: Cross-platform desktop apps, Docker service management
- **Technologies**: React, TypeScript, Tailwind CSS, Zustand

**multi-scrobbler** (Dockerized)
- Music scrobbling to multiple platforms
- **Skills**: Multi-client scrobbling (Last.fm, ListenBrainz, etc.)
- **Features**: Concurrency, TypeScript, Docusaurus docs

### Search & Metadata

**rivr-search** (Search engine/indexing)
- **Skills**: Full-text search, indexing

**OpenTor-X** (Torrent search)
- **Skills**: Torrent metadata search

### Python Tools

**python-web-scrapping** (48 files)
- General Python scraping utilities
- **Skills**: BeautifulSoup, requests, Selenium integration

---

## 📊 INTEGRATION MATRIX

```
┌─────────────────────────────────────────────────────────────┐
│                    Nginx (Reverse Proxy)                    │
├─────────────────────────────────────────────────────────────┤
│ /stash    │ /namer    │ /api    │ /whisparr │ /liberty │ /imdb
│           │           │         │           │          │
├─────┬─────┼──────┬─────┼────┬────┼──────┬────┼────┬──────┼────┬─────┐
│     │     │      │     │    │    │      │    │    │      │    │     │
▼     ▼     ▼      ▼     ▼    ▼    ▼      ▼    ▼    ▼      ▼    ▼     ▼
Stash Namer UniScrape Whisparr Liberty IMDB-Scraper
  │     │     │        │        │       │
  └─────┼─────┼────────┼────────┼───────┴──────────┐
        │     │        │        │                  │
        ▼     ▼        ▼        ▼                  ▼
       PostgreSQL   Redis    Chrome CDP      Chromium
        (unified DB) (cache) (headless)      (browser)
```

### Data Flow Examples

**Media Discovery & Organization:**
1. IMDB Scraper → scrapes movie metadata
2. UniScrape API → stores in PostgreSQL, caches in Redis
3. Stash → displays library, Namer auto-organizes files
4. Transmission → downloads related content (torrents)

**Cross-Service Search:**
1. User searches Stash UI
2. Stash → queries PostgreSQL + Redis
3. Redis → returns cached results
4. PostgreSQL → full-text search queries
5. UniScrape → proxy to external APIs if needed

**Automation Pipeline:**
1. Cron job on Transmission → new torrent available
2. Transmission → MQTT/webhook to Stash
3. Stash → Namer auto-organizes
4. Namer → Stash metadata update
5. Liberty API → notification service

---

## 🎯 FEATURE MATRIX

| Feature | Stash | UniScrape | Whisparr | Liberty | IMDB | Nginx |
|---------|-------|-----------|----------|---------|------|-------|
| **REST API** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (proxy) |
| **Database** | ✅ (SQLite) | ✅ (PostgreSQL) | ✅ (SQLite) | ✅ (JDBC) | ❌ | ❌ |
| **Caching** | ✅ | ✅ (Redis) | ✅ | ✅ (Optional) | ❌ | ✅ |
| **Web UI** | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| **Automation** | ✅ (Plugins) | ✅ (Scripts) | ✅ (Profiles) | ✅ (Java) | ❌ | ❌ |
| **Headless Rendering** | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ |
| **Proxy Rotation** | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **SSL/TLS** | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| **Health Checks** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Rate Limiting** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Metrics** | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ |
| **Microservices** | ❌ | ✅ | ❌ | ✅ | ✅ | ✅ |

---

## 🚀 DEPLOYMENT STRATEGIES

### Single-Node Deployment (Current)
All 11 services on one machine with Docker Compose
- **Pros**: Simple, fast, all shared storage
- **Cons**: Single point of failure, resource constraints
- **Best for**: Development, small-scale deployments

### Multi-Node Deployment (Docker Swarm)
```bash
docker swarm init
docker stack deploy -c docker-compose.unified.yml stack-name
```
- Services replicated across nodes
- Built-in load balancing
- Distributed storage (NFS, GlusterFS)

### Kubernetes Deployment
```bash
# Convert docker-compose to Kubernetes manifests
kompose convert -f docker-compose.unified.yml -o k8s/
kubectl apply -f k8s/
```
- Auto-scaling, rolling updates
- Persistent volume management
- Service mesh (Istio, Linkerd)
- Multi-region deployment

### CI/CD Integration

**GitHub Actions Pipeline:**
1. Code push → GitHub
2. Build Docker images → ghcr.io
3. Push to registry
4. Deploy to production Docker stack
5. Run smoke tests
6. Rollback on failure

---

## 📈 PERFORMANCE METRICS

### Resource Allocation

```
Total: ~16GB RAM, 8 CPUs (configurable)

Stash:        4GB RAM, 4 CPUs
UniScrape:    2GB RAM, 2 CPUs
Chrome:       2GB RAM, 2 CPUs
PostgreSQL:   1.5GB RAM, 1.5 CPUs
Open Liberty: 2GB RAM, 2 CPUs
IMDB Scraper: 1.5GB RAM, 1.5 CPUs
Redis:        768MB RAM, 1 CPU
Others:       ~1.2GB, 1 CPU
```

### Scaling Recommendations

**Small (4GB RAM, 2 CPU)**
- Stash: 1GB, 1 CPU
- UniScrape: 1GB, 0.5 CPU
- Chrome: 512MB, 0.5 CPU
- Others: Minimal

**Large (64GB RAM, 16 CPU)**
- Stash: 8GB, 4 CPU
- UniScrape: 6GB, 4 CPU
- Chrome: 4GB, 3 CPU
- PostgreSQL: 4GB, 2 CPU
- Liberty: 4GB, 3 CPU

---

## 🔒 SECURITY POSTURE

✅ **Implemented**
- No hardcoded secrets (env() everywhere)
- SSL/TLS termination at Nginx
- Network isolation (backend bridge)
- Resource limits per container
- Non-root users (Namer, Whisparr, Transmission, IMDB)
- Dropped ALL capabilities (min permissions)
- Health checks + auto-restart
- Rate limiting (DoS protection)
- Security headers (HSTS, CSP, X-Frame-Options)
- Firewall rules (Windows)
- Zero npm vulnerabilities (post-audit fix)

⚠️ **Recommended**
- Replace self-signed SSL with CA certificates
- Set up centralized logging (ELK, Splunk)
- Implement vulnerability scanning (Trivy, Scout)
- Enable audit logging
- Set up secrets management (Vault, Docker Secrets)
- Implement network policies (if Kubernetes)

---

## 📚 LEARNING RESOURCES & NEXT STEPS

### Deploy IMDB Scraper
```bash
cd stash/
docker compose -f docker-compose.unified.yml up -d imdb-scraper
curl http://localhost:3000/health
```

### Create Custom Scrapers
- Use UniScrape as base
- Integrate ProxyCrawl for rotation
- Store metadata in PostgreSQL
- Cache in Redis

### Extend with Plugins
- Stash plugin SDK: https://github.com/stashapp/stash-plugins
- CommunityScripts integration
- Custom Go/Rust extensions

### Monitoring & Observability
- Set up Prometheus for metrics
- Grafana dashboards for visualization
- Alert rules for critical services
- Distributed tracing (Jaeger)

### Advanced Features
- OAuth2 authentication (for APIs)
- GraphQL layer (for data access)
- Event-driven architecture (Kafka/RabbitMQ)
- Machine learning (content classification, recommendations)
- Mobile app (React Native)

---

## 📖 DOCUMENTATION REFERENCES

- Docker: https://docs.docker.com/
- Stash: https://docs.stashapp.cc/
- Open Liberty: https://openliberty.io/docs/
- PostgreSQL: https://www.postgresql.org/docs/
- Redis: https://redis.io/documentation
- Nginx: https://nginx.org/en/docs/
- Nightmare.js: https://www.nightmarejs.org/
- Express.js: https://expressjs.com/
- Cheerio: https://cheerio.js.org/

---

**Ecosystem Status**: 🟢 Production Ready
**Version**: 1.0.0 (Unified Stack)
**Last Updated**: 2026-05-05
**Total Services**: 12 (11 core + Portainer)
**Total Skills/Integrations**: 50+
