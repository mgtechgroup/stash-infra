# IMDB Scraper API Integration Guide
# Latest Version - IMDB Movie/TV Series Scraper with REST API
# Date: 2026-05-05

## Overview

IMDB Scraper is a Node.js-based web scraper with a REST API server that automatically extracts movie/TV series data from IMDB, including:
- Movie titles, rankings, ratings
- Poster images (downloaded to disk)
- Genre information
- Runtime, plot, cast data
- Metadata extraction via OpenGraph

Built with:
- **Nightmare.js**: Headless browser automation
- **Cheerio**: HTML parsing
- **Express.js**: REST API framework
- **Chromium**: Headless browser
- **Node.js 18**: Runtime

## Architecture

```
Internet
   │
   └─► IMDB.com (https://www.imdb.com)
   │
   ├─ Extract Titles (Cheerio)
   ├─ Fetch Posters (Request-Promise)
   ├─ Render Images (Nightmare.js + Chromium)
   └─ Save to Disk

User Requests
   │
   ├─► Express.js REST API (Port 3000)
   │   ├─ /api/scrape/titles
   │   ├─ /api/scrape/posters
   │   ├─ /api/scrape/images
   │   ├─ /api/scrape/movie/:id
   │   └─ /api/status
   │
   └─► Nginx Reverse Proxy (Port 443)
       └─ /imdb/* → IMDB Scraper
```

## Quick Start

### 1. Build Container

```bash
cd stash/
docker build -f ../repos/scrape/imdb-scraper/Dockerfile -t mgtechgroup/imdb-scraper:latest ../repos/scrape/imdb-scraper/
```

### 2. Start Service

```bash
docker compose -f docker-compose.unified.yml up -d imdb-scraper
```

### 3. Verify Running

```bash
# Check container
docker ps | grep imdb-scraper

# Health check
curl http://localhost:3000/health

# Via Nginx
curl -k https://localhost/imdb/health

# View logs
docker logs -f imdb-scraper
```

## REST API Endpoints

### Health & Status

#### `GET /health`
**Description**: Basic health check
**Response**: 
```json
{
  "status": "UP",
  "timestamp": "2026-05-05T11:30:00.000Z",
  "service": "imdb-scraper",
  "uptime": 3600,
  "memory": {
    "used": 256,
    "total": 512
  }
}
```

#### `GET /health/ready`
**Description**: Ready status (can serve requests)
**Response**:
```json
{
  "ready": true,
  "checks": {
    "nightmare": true,
    "cheerio": true,
    "fileSystem": true
  }
}
```

#### `GET /api/status`
**Description**: Detailed service status
**Response**:
```json
{
  "service": "imdb-scraper-api",
  "status": "RUNNING",
  "version": "1.0.0",
  "uptime": 3600,
  "posters_downloaded": 50,
  "memory": {
    "used_mb": 256,
    "total_mb": 512
  },
  "node_version": "v18.20.0",
  "timestamp": "2026-05-05T11:30:00.000Z"
}
```

### Scraping Endpoints

#### `GET /api/scrape/titles`
**Description**: Scrape top 50 IMDB movie titles and ratings
**Time**: ~10-15 seconds
**Response**:
```json
{
  "success": true,
  "count": 50,
  "data": [
    {
      "rank": 0,
      "title": "The Shawshank Redemption",
      "imdbRating": "9.3",
      "descriptionUrl": "https://www.imdb.com/title/tt0111161/"
    },
    ...
  ],
  "timestamp": "2026-05-05T11:30:00.000Z"
}
```

#### `GET /api/scrape/posters`
**Description**: Scrape titles + poster URLs
**Time**: ~20-30 seconds
**Response**:
```json
{
  "success": true,
  "count": 50,
  "data": [
    {
      "rank": 0,
      "title": "The Shawshank Redemption",
      "imdbRating": "9.3",
      "descriptionUrl": "https://www.imdb.com/title/tt0111161/",
      "posterUrl": "https://www.imdb.com/title/tt0111161/mediaviewer/rm..."
    },
    ...
  ],
  "timestamp": "2026-05-05T11:30:00.000Z"
}
```

#### `GET /api/scrape/images`
**Description**: Full scrape (titles + ratings + posters + images)
**Time**: ~3-5 minutes (slowest operation)
**Response**:
```json
{
  "success": true,
  "count": 50,
  "data": [
    {
      "rank": 0,
      "title": "The Shawshank Redemption",
      "imdbRating": "9.3",
      "descriptionUrl": "https://www.imdb.com/title/tt0111161/",
      "posterUrl": "https://www.imdb.com/title/tt0111161/mediaviewer/...",
      "posterImageUrl": "https://m.media-amazon.com/images/M/MV5..."
    },
    ...
  ],
  "message": "Scraped 50 movies with poster images",
  "timestamp": "2026-05-05T11:30:00.000Z"
}
```

**Note**: Poster images are also saved to `/app/posters/` as PNG files (0.png, 1.png, etc.)

#### `GET /api/scrape/movie/:id`
**Description**: Scrape specific movie by IMDB ID
**Parameters**:
- `id` (required): IMDB movie ID (e.g., `tt0111161`)
**Example**: `GET /api/scrape/movie/tt0111161`
**Time**: ~2-3 seconds
**Response**:
```json
{
  "success": true,
  "data": {
    "imdbId": "tt0111161",
    "title": "The Shawshank Redemption",
    "rating": "9.3/10",
    "year": "1994",
    "runtime": "142 min",
    "genres": ["Drama"],
    "plot": "Two imprisoned men bond over a number of years...",
    "posterUrl": "https://m.media-amazon.com/images/M/MV5..."
  },
  "timestamp": "2026-05-05T11:30:00.000Z"
}
```

## Usage Examples

### JavaScript/Node.js

```javascript
// Basic fetch
const response = await fetch('http://localhost:3000/api/scrape/titles');
const data = await response.json();
console.log(`Found ${data.count} movies`);

// With error handling
try {
  const res = await fetch('http://localhost:3000/api/scrape/posters');
  const { success, data, error } = await res.json();
  
  if (success) {
    data.forEach(movie => {
      console.log(`${movie.rank}: ${movie.title} (${movie.imdbRating})`);
    });
  } else {
    console.error('Error:', error);
  }
} catch (err) {
  console.error('Request failed:', err);
}
```

### cURL

```bash
# Get titles
curl http://localhost:3000/api/scrape/titles | jq .

# Get posters
curl http://localhost:3000/api/scrape/posters | jq '.data[] | {rank, title, posterUrl}'

# Scrape specific movie
curl http://localhost:3000/api/scrape/movie/tt0111161 | jq .

# Check status
curl http://localhost:3000/api/status | jq .
```

### Python

```python
import requests
import json

# Scrape titles
response = requests.get('http://localhost:3000/api/scrape/titles')
data = response.json()

if data['success']:
    for movie in data['data']:
        print(f"{movie['rank']+1}. {movie['title']} ({movie['imdbRating']})")
else:
    print(f"Error: {data['error']}")

# Scrape specific movie
imdb_id = 'tt0111161'
response = requests.get(f'http://localhost:3000/api/scrape/movie/{imdb_id}')
movie = response.json()['data']
print(json.dumps(movie, indent=2))
```

### PHP

```php
<?php
// Using cURL
$ch = curl_init('http://localhost:3000/api/scrape/titles');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$response = curl_exec($ch);
$data = json_decode($response, true);

if ($data['success']) {
    foreach ($data['data'] as $movie) {
        echo $movie['title'] . " - " . $movie['imdbRating'] . "\n";
    }
}
?>
```

## Integration with Stack Services

### Stash Integration

```javascript
// From Stash plugin - fetch movie data
const imdbResponse = await fetch('http://imdb-scraper:3000/api/scrape/movie/tt0111161');
const movieData = await imdbResponse.json();

// Store in Stash
await stash.updateScene({
  title: movieData.data.title,
  date: movieData.data.year,
  director: movieData.data.director,
  url: `https://imdb.com/title/${movieData.data.imdbId}/`
});
```

### UniScrape Integration

```javascript
// From UniScrape API
router.get('/api/imdb/:id', async (req, res) => {
  const imdbId = req.params.id;
  const imdbResponse = await fetch(`http://imdb-scraper:3000/api/scrape/movie/${imdbId}`);
  const imdbData = await imdbResponse.json();
  
  // Combine with other metadata
  const combined = {
    ...imdbData.data,
    // Add other metadata from PostgreSQL, etc.
  };
  
  res.json(combined);
});
```

### Open Liberty Integration

```java
@Inject
@RestClient
private ImdbClient imdbClient;

@Path("/api/movies/{id}")
@GET
public Response getMovieData(@PathParam("id") String imdbId) {
    try {
        MovieData movie = imdbClient.getMovie(imdbId);
        return Response.ok(movie).build();
    } catch (Exception e) {
        return Response.serverError().entity(e.getMessage()).build();
    }
}

@RegisterRestClient(baseUri = "http://imdb-scraper:3000")
public interface ImdbClient {
    @GET
    @Path("/api/scrape/movie/{id}")
    MovieData getMovie(@PathParam("id") String id);
}
```

## Performance Considerations

### Timeouts
- **Titles Scrape**: 10-15 seconds
- **Posters Scrape**: 20-30 seconds
- **Images Scrape**: 3-5 minutes (parallel downloads + Nightmare rendering)
- **Single Movie**: 2-3 seconds

### Nginx Timeout Configuration
```nginx
proxy_connect_timeout 30s;
proxy_send_timeout 300s;
proxy_read_timeout 300s;
```

### Memory Usage
- **Base**: ~100MB
- **Per Request**: +50-100MB
- **Max Heap**: 512MB (configured)
- **Peak Usage**: ~400-500MB during image scraping

### Parallel Requests
- Safe to make 2-3 concurrent requests
- Nightmare.js uses single browser instance (sequential execution)
- Rate limiting at Nginx: 5 req/sec (scrape), 10 req/burst

## Troubleshooting

### Service Won't Start
```bash
# Check logs
docker logs imdb-scraper

# Verify port not in use
netstat -ano | findstr :3000

# Check image built correctly
docker images | grep imdb
```

### Scraping Hangs
```bash
# IMDB may be blocking - add delay
curl -H "User-Agent: Mozilla/5.0" http://localhost:3000/api/scrape/titles

# Check Docker logs for timeout errors
docker logs --follow imdb-scraper
```

### Memory Issues
```bash
# Monitor memory usage
docker stats imdb-scraper

# Reduce MAX_OLD_SPACE_SIZE in docker-compose.yml
NODE_OPTIONS: "--max-old-space-size=256"

# Restart service
docker restart imdb-scraper
```

### Chromium Issues
```bash
# Verify Chromium installed
docker exec imdb-scraper which chromium-browser

# Check NIGHTMARE_ELECTRON_PATH
docker exec imdb-scraper echo $NIGHTMARE_ELECTRON_PATH

# View Nightmare logs
docker logs imdb-scraper | grep -i nightmare
```

### Connection Issues (from other services)
```bash
# Test connectivity from Stash
docker exec stash curl -v http://imdb-scraper:3000/health

# Check network
docker network inspect backend | grep imdb

# Verify DNS
docker exec imdb-scraper nslookup imdb-scraper
```

## Configuration

### Environment Variables

```yaml
environment:
  NODE_ENV: production           # production|development
  PORT: 3000                     # API port
  NODE_OPTIONS: --max-old-space-size=512  # Heap size (MB)
  NIGHTMARE_ELECTRON_PATH: /usr/bin/chromium-browser  # Browser path
```

### Modify Configuration

Edit `docker-compose.unified.yml`:

```yaml
imdb-scraper:
  environment:
    PORT: 3001  # Change port
    NODE_OPTIONS: --max-old-space-size=1024  # Increase heap
```

Restart:
```bash
docker compose -f docker-compose.unified.yml restart imdb-scraper
```

## Monitoring & Logs

### View Logs

```bash
# Real-time
docker logs -f imdb-scraper

# Last 50 lines
docker logs --tail 50 imdb-scraper

# With timestamps
docker logs -f --timestamps imdb-scraper

# Error logs only
docker logs imdb-scraper | grep -i error
```

### Health Monitoring

```bash
# Automated health check via Docker
docker inspect --format='{{json .State.Health}}' imdb-scraper | jq .

# API health endpoint
curl -s http://localhost:3000/health | jq .

# Ready status
curl -s http://localhost:3000/health/ready | jq .
```

### Metrics

```bash
# Service status and stats
curl -s http://localhost:3000/api/status | jq .

# Extract posters count
curl -s http://localhost:3000/api/status | jq .posters_downloaded

# Memory usage
curl -s http://localhost:3000/api/status | jq .memory
```

## Advanced Usage

### Batch Scraping

```bash
#!/bin/bash

# Scrape multiple IMDB IDs
IMDB_IDS=("tt0111161" "tt0137523" "tt0468569" "tt1375666")

for id in "${IMDB_IDS[@]}"; do
  curl "http://localhost:3000/api/scrape/movie/$id" | jq '.data | {title, rating, year}'
done
```

### Scheduled Scraping (via cron)

```bash
# In docker-compose.yml, add volume mount for cron script
volumes:
  - ./cron-scrape.sh:/app/cron-scrape.sh

# Then in the container:
0 2 * * * /usr/bin/curl http://localhost:3000/api/scrape/titles > /app/logs/titles.json
```

### Integration with Transmission

```javascript
// Webhook from Transmission → IMDB Scraper
// When torrent completes, extract IMDB ID and fetch metadata

app.post('/webhook/transmission', async (req, res) => {
  const { title } = req.body;
  
  // Extract IMDB ID from title (e.g., "Movie.2020.tt0111161")
  const match = title.match(/tt\d{7,}/);
  if (match) {
    const imdbId = match[0];
    const movieData = await fetch(`http://localhost:3000/api/scrape/movie/${imdbId}`);
    // Store metadata, update Stash, etc.
  }
});
```

## Security

✅ **Implemented**
- Non-root user (appuser, UID 1001)
- No privileges escalation (no-new-privileges)
- Dropped all capabilities
- Read-only root filesystem (where applicable)
- Health checks + auto-restart
- Resource limits (1.5 CPU, 1.5GB RAM max)
- Rate limiting via Nginx (5 req/sec)

⚠️ **Considerations**
- IMDB may block aggressive scraping (use proxy rotation if needed)
- Chromium requires significant resources
- Image downloads use external bandwidth
- Store posters in persistent volume (for retention)

## Performance Optimization

### Caching Strategy

```javascript
// Cache titles in Redis (1 hour TTL)
const cache = require('redis').createClient();

app.get('/api/scrape/titles', async (req, res) => {
  const cached = await cache.get('imdb:titles');
  if (cached) {
    return res.json(JSON.parse(cached));
  }
  
  // Scrape and cache
  const data = await scrapeTitles();
  await cache.setex('imdb:titles', 3600, JSON.stringify(data));
  res.json(data);
});
```

### Image Optimization

```javascript
// Convert images to WebP (40% smaller)
const sharp = require('sharp');

async function optimizeImage(inputPath) {
  await sharp(inputPath)
    .webp({ quality: 80 })
    .toFile(inputPath.replace('.png', '.webp'));
}
```

### Parallel Downloads

```javascript
// Use worker threads for image downloads
const { Worker } = require('worker_threads');

const workers = new Array(4).fill(null).map(() => new Worker('./download-worker.js'));
```

## References

- IMDB Scraper GitHub: https://github.com/mariazevedo88/imdb-scraper
- Nightmare.js: https://www.nightmarejs.org/
- Cheerio: https://cheerio.js.org/
- Express.js: https://expressjs.com/
- Docker: https://docs.docker.com/

---

**Status**: ✅ Production Ready
**Version**: 1.0.0
**Last Updated**: 2026-05-05
