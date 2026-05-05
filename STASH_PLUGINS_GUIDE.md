# Stash Plugin System - Custom Plugins & Integrations
# Unified Docker Stack Plugin Repository
# Date: 2026-05-05

## 📦 Plugin Overview

Stash supports JavaScript plugins for extending functionality. This document outlines created plugins and integration points for the unified stack.

## 🔧 Plugin Architecture

```
/root/.stash/plugins/
├── MultiScraper/
│   ├── multiScraper.js
│   └── manifest.json
├── IMDBIntegration/
│   ├── imdbPlugin.js
│   └── manifest.json
├── UniScrapeAPI/
│   ├── uniscrapePlugin.js
│   └── manifest.json
├── ProxyRotation/
│   ├── proxyPlugin.js
│   └── manifest.json
├── AutoNaming/
│   ├── autoNamingPlugin.js
│   └── manifest.json
└── MediaLibrarySync/
    ├── syncPlugin.js
    └── manifest.json
```

---

## 🎬 Plugin 1: IMDB Integration Plugin

**Purpose**: Fetch movie metadata directly from IMDB Scraper API

**File**: `stash/plugins/IMDBIntegration/manifest.json`

```json
{
  "name": "IMDB Integration",
  "description": "Fetch movie metadata from IMDB Scraper API",
  "version": "1.0.0",
  "author": "Stack Integration",
  "disabled": false,
  "requires": ["0.26.0"],
  "tasks": [
    {
      "name": "Fetch IMDB Metadata",
      "description": "Fetch movie/scene metadata from IMDB",
      "modifiesLibrary": true,
      "scheduled": false
    }
  ]
}
```

**File**: `stash/plugins/IMDBIntegration/imdbPlugin.js`

```javascript
// Stash Plugin: IMDB Integration
const http = gql.client.http;

class IMDBPlugin {
  async fetchMovieMetadata(imdbId) {
    const response = await fetch(`http://imdb-scraper:3000/api/scrape/movie/${imdbId}`);
    const data = await response.json();
    
    if (!data.success) {
      throw new Error(`IMDB fetch failed: ${data.error}`);
    }
    
    return {
      title: data.data.title,
      date: data.data.year,
      director: data.data.director,
      details: {
        rating: data.data.rating,
        runtime: data.data.runtime,
        genres: data.data.genres.join(', '),
        plot: data.data.plot
      },
      urls: [
        {
          type: 'IMDB',
          url: `https://imdb.com/title/${data.data.imdbId}/`
        }
      ]
    };
  }

  async updateSceneFromIMDB(sceneId, imdbId) {
    try {
      const metadata = await this.fetchMovieMetadata(imdbId);
      
      // Update scene in Stash
      const response = await stash.callGQL({
        operationName: 'SceneUpdate',
        variables: {
          input: {
            id: sceneId,
            title: metadata.title,
            date: metadata.date,
            details: JSON.stringify(metadata.details),
            urls: metadata.urls
          }
        }
      });
      
      return response;
    } catch (error) {
      console.error(`Error updating scene: ${error.message}`);
      throw error;
    }
  }

  async batchUpdateFromIMDB(imdbIds) {
    const results = [];
    
    for (const [sceneId, imdbId] of Object.entries(imdbIds)) {
      try {
        const result = await this.updateSceneFromIMDB(sceneId, imdbId);
        results.push({ sceneId, status: 'success', result });
      } catch (error) {
        results.push({ sceneId, status: 'error', error: error.message });
      }
    }
    
    return results;
  }
}

stash.on('task', async (task) => {
  if (task.Name === 'Fetch IMDB Metadata') {
    const plugin = new IMDBPlugin();
    // Example: fetch metadata for scenes with IMDB URLs
    await plugin.batchUpdateFromIMDB({
      'scene1': 'tt0111161',
      'scene2': 'tt0137523'
    });
  }
});
```

---

## 🔗 Plugin 2: UniScrape API Integration

**Purpose**: Use UniScrape API for advanced scraping capabilities

**File**: `stash/plugins/UniScrapeAPI/manifest.json`

```json
{
  "name": "UniScrape API",
  "description": "Integrate UniScrape API for metadata extraction",
  "version": "1.0.0",
  "author": "Stack Integration",
  "disabled": false,
  "requires": ["0.26.0"],
  "tasks": [
    {
      "name": "UniScrape Search",
      "description": "Search content via UniScrape API",
      "modifiesLibrary": true,
      "scheduled": false
    }
  ]
}
```

**File**: `stash/plugins/UniScrapeAPI/uniscrapePlugin.js`

```javascript
// Stash Plugin: UniScrape API Integration
class UniScrapePlugin {
  constructor() {
    this.baseUrl = 'http://uniscrape:9876';
  }

  async searchContent(query, source = 'stash') {
    const response = await fetch(`${this.baseUrl}/api/search`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ query, source })
    });
    
    if (!response.ok) {
      throw new Error(`UniScrape search failed: ${response.statusText}`);
    }
    
    return await response.json();
  }

  async fetchMetadata(url) {
    const response = await fetch(`${this.baseUrl}/api/metadata`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ url })
    });
    
    return await response.json();
  }

  async getRSSFeed(source) {
    const response = await fetch(`${this.baseUrl}/tools/rss/${source}`);
    return await response.json();
  }

  async createScene(data) {
    const response = await stash.callGQL({
      operationName: 'SceneCreate',
      variables: {
        input: {
          title: data.title,
          date: data.date,
          urls: data.urls,
          details: data.details
        }
      }
    });
    
    return response.data.sceneCreate.id;
  }

  async syncFromSource(source) {
    try {
      const results = await this.searchContent('*', source);
      
      for (const item of results.data) {
        const scene = await this.createScene(item);
        console.log(`Created scene: ${scene}`);
      }
      
      return { status: 'success', count: results.data.length };
    } catch (error) {
      console.error(`Sync error: ${error.message}`);
      throw error;
    }
  }
}

stash.on('task', async (task) => {
  if (task.Name === 'UniScrape Search') {
    const plugin = new UniScrapePlugin();
    await plugin.syncFromSource('stash');
  }
});
```

---

## 🔄 Plugin 3: Proxy Rotation Plugin

**Purpose**: Use ProxyCrawl for anti-scraping bypass

**File**: `stash/plugins/ProxyRotation/manifest.json`

```json
{
  "name": "Proxy Rotation",
  "description": "Rotate proxies via ProxyCrawl for scraping",
  "version": "1.0.0",
  "author": "Stack Integration",
  "disabled": false,
  "requires": ["0.26.0"]
}
```

**File**: `stash/plugins/ProxyRotation/proxyPlugin.js`

```javascript
// Stash Plugin: Proxy Rotation
class ProxyRotationPlugin {
  constructor(apiKey) {
    this.apiKey = apiKey || process.env.PROXYCRAWL_API_KEY;
    this.baseUrl = 'https://api.proxycrawl.com';
  }

  async fetchWithProxy(url, options = {}) {
    const params = new URLSearchParams({
      token: this.apiKey,
      url: url,
      scraper: 'beautifulsoup',
      country: options.country || 'US',
      ...options
    });

    const response = await fetch(`${this.baseUrl}?${params}`);
    const data = await response.json();

    if (data.status_code !== 200) {
      throw new Error(`Proxy fetch failed: ${data.error}`);
    }

    return data.body;
  }

  async scrapeWithProxy(url, selector, options = {}) {
    const html = await this.fetchWithProxy(url, options);
    
    // Parse HTML and extract data
    const cheerio = require('cheerio');
    const $ = cheerio.load(html);
    
    const results = [];
    $(selector).each((i, el) => {
      results.push($(el).text());
    });
    
    return results;
  }
}

// Export for use in other plugins
module.exports = ProxyRotationPlugin;
```

---

## ✏️ Plugin 4: Auto-Naming Plugin

**Purpose**: Integration with Namer service for automatic scene naming

**File**: `stash/plugins/AutoNaming/manifest.json`

```json
{
  "name": "Auto Naming",
  "description": "Automatically name scenes using Namer service",
  "version": "1.0.0",
  "author": "Stack Integration",
  "disabled": false,
  "requires": ["0.26.0"],
  "tasks": [
    {
      "name": "Auto-Rename Scenes",
      "description": "Automatically rename scenes using Namer",
      "modifiesLibrary": true,
      "scheduled": true
    }
  ]
}
```

**File**: `stash/plugins/AutoNaming/autoNamingPlugin.js`

```javascript
// Stash Plugin: Auto-Naming via Namer Service
class AutoNamingPlugin {
  async getScenesByFilter(filter) {
    const response = await stash.callGQL({
      operationName: 'FindScenes',
      variables: { filter }
    });
    
    return response.data.findScenes.scenes;
  }

  async suggestName(sceneData) {
    const response = await fetch('http://namer:6980/api/suggest-name', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(sceneData)
    });
    
    return await response.json();
  }

  async updateSceneName(sceneId, newName) {
    return await stash.callGQL({
      operationName: 'SceneUpdate',
      variables: {
        input: {
          id: sceneId,
          title: newName
        }
      }
    });
  }

  async autoRenameScenes(filter = {}) {
    const scenes = await this.getScenesByFilter(filter);
    const results = [];

    for (const scene of scenes) {
      try {
        const suggestion = await this.suggestName({
          title: scene.title,
          date: scene.date,
          details: scene.details
        });

        if (suggestion.confidence > 0.7) {
          await this.updateSceneName(scene.id, suggestion.suggestedName);
          results.push({
            sceneId: scene.id,
            oldName: scene.title,
            newName: suggestion.suggestedName,
            confidence: suggestion.confidence
          });
        }
      } catch (error) {
        console.error(`Error renaming scene ${scene.id}: ${error.message}`);
      }
    }

    return results;
  }
}

stash.on('task', async (task) => {
  if (task.Name === 'Auto-Rename Scenes') {
    const plugin = new AutoNamingPlugin();
    const results = await plugin.autoRenameScenes();
    console.log(`Renamed ${results.length} scenes`);
  }
});
```

---

## 🔀 Plugin 5: Media Library Sync Plugin

**Purpose**: Sync between Stash, Whisparr, Transmission, and other services

**File**: `stash/plugins/MediaLibrarySync/manifest.json`

```json
{
  "name": "Media Library Sync",
  "description": "Sync library across Stash, Whisparr, Transmission",
  "version": "1.0.0",
  "author": "Stack Integration",
  "disabled": false,
  "requires": ["0.26.0"],
  "tasks": [
    {
      "name": "Sync Whisparr",
      "description": "Sync scenes with Whisparr library",
      "modifiesLibrary": false,
      "scheduled": true
    },
    {
      "name": "Sync Transmission",
      "description": "Sync scenes with active torrents",
      "modifiesLibrary": true,
      "scheduled": true
    }
  ]
}
```

**File**: `stash/plugins/MediaLibrarySync/syncPlugin.js`

```javascript
// Stash Plugin: Media Library Sync
class MediaLibrarySyncPlugin {
  async getStashScenes() {
    const response = await stash.callGQL({
      operationName: 'FindScenes',
      variables: { filter: { per_page: 10000 } }
    });
    return response.data.findScenes.scenes;
  }

  async getWhisparrAlbums() {
    const response = await fetch('http://whisparr:6969/api/v1/album');
    return await response.json();
  }

  async getTransmissionTorrents() {
    const response = await fetch('http://transmission:9091/transmission/rpc');
    // Parse torrent list
    return response.json();
  }

  async compareLibraries() {
    const stashScenes = await this.getStashScenes();
    const whisparrAlbums = await this.getWhisparrAlbums();
    const torrents = await this.getTransmissionTorrents();

    return {
      inStashOnly: stashScenes.filter(s => !whisparrAlbums.find(a => a.title === s.title)),
      inWhisparrOnly: whisparrAlbums.filter(a => !stashScenes.find(s => s.title === a.title)),
      inTransmissionOnly: torrents.filter(t => !stashScenes.find(s => s.title.includes(t.name)))
    };
  }

  async syncWithWhisparr() {
    const { inWhisparrOnly } = await this.compareLibraries();
    
    for (const album of inWhisparrOnly) {
      try {
        await stash.callGQL({
          operationName: 'SceneCreate',
          variables: {
            input: {
              title: album.title,
              details: JSON.stringify({
                artist: album.artistMetadata?.name,
                album: album.title,
                year: album.releaseDate?.split('-')[0],
                trackCount: album.trackFileCount
              })
            }
          }
        });
      } catch (error) {
        console.error(`Error syncing album: ${error.message}`);
      }
    }
  }

  async syncWithTransmission() {
    const { inTransmissionOnly } = await this.compareLibraries();
    
    for (const torrent of inTransmissionOnly) {
      try {
        await stash.callGQL({
          operationName: 'SceneCreate',
          variables: {
            input: {
              title: torrent.name,
              details: JSON.stringify({
                downloadProgress: torrent.downloadDir,
                size: torrent.totalSize,
                seeders: torrent.peersSendingToUs
              })
            }
          }
        });
      } catch (error) {
        console.error(`Error syncing torrent: ${error.message}`);
      }
    }
  }
}

stash.on('task', async (task) => {
  const plugin = new MediaLibrarySyncPlugin();
  
  if (task.Name === 'Sync Whisparr') {
    await plugin.syncWithWhisparr();
  } else if (task.Name === 'Sync Transmission') {
    await plugin.syncWithTransmission();
  }
});
```

---

## 📋 Plugin Installation

### Method 1: Manual Installation

1. Create plugin directory:
```bash
mkdir -p /root/.stash/plugins/IMDBIntegration
```

2. Create manifest.json and plugin JS files (see above)

3. Restart Stash:
```bash
docker restart stash
```

### Method 2: Docker Volume Mount

In `docker-compose.unified.yml`:

```yaml
stash:
  volumes:
    - ./stash/plugins:/root/.stash/plugins:ro
```

### Method 3: API Installation

```bash
curl -X POST http://localhost:9999/api/plugins \
  -F "manifest=@manifest.json" \
  -F "file=@plugin.js"
```

---

## 🔌 Plugin Configuration

In Stash Settings → Plugins, configure:

```json
{
  "plugins": {
    "IMDBIntegration": {
      "enabled": true,
      "imdbApiUrl": "http://imdb-scraper:3000"
    },
    "UniScrapeAPI": {
      "enabled": true,
      "uniscrapeUrl": "http://uniscrape:9876"
    },
    "ProxyRotation": {
      "enabled": true,
      "proxycrawlApiKey": "your-api-key"
    },
    "AutoNaming": {
      "enabled": true,
      "namerUrl": "http://namer:6980"
    },
    "MediaLibrarySync": {
      "enabled": true,
      "syncInterval": 3600
    }
  }
}
```

---

## 📚 Community Plugins (Available)

From `repos/stash/CommunityScripts/`:
- LocalVisage (facial recognition)
- stash-watcher (file monitoring)
- 540+ other community plugins

From `repos/scrape/`:
- SourceScraper (multi-anime scraper)
- html2rss (feed generator)
- link-meta-extractor (metadata extraction)

---

## 🚀 Creating Custom Plugins

### Plugin Template

```javascript
// Stash Plugin Template
class CustomPlugin {
  async onLibraryLoad() {
    console.log('Plugin loaded');
  }

  async onSceneCreate(scene) {
    console.log(`Scene created: ${scene.title}`);
  }

  async onSceneUpdate(scene) {
    console.log(`Scene updated: ${scene.title}`);
  }

  async onSceneDelete(sceneId) {
    console.log(`Scene deleted: ${sceneId}`);
  }
}

// Register hooks
stash.hook('library.load', plugin.onLibraryLoad);
stash.hook('scene.create', plugin.onSceneCreate);
stash.hook('scene.update', plugin.onSceneUpdate);
stash.hook('scene.delete', plugin.onSceneDelete);
```

### Testing Plugins

```bash
# Enable debug mode
docker exec stash curl -X POST http://localhost:9999/api/debug/enable

# View plugin logs
docker logs -f stash | grep plugin

# Test plugin via API
curl -X POST http://localhost:9999/api/plugins/test \
  -H "Content-Type: application/json" \
  -d '{"pluginId": "IMDBIntegration", "task": "testTask"}'
```

---

**Status**: ✅ Plugins Ready for Integration
**Version**: 1.0.0
**Last Updated**: 2026-05-05
