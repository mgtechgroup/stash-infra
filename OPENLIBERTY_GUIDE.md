# Open Liberty Integration Guide
# Latest Version - Production Setup

## Overview

Open Liberty is a lightweight, open-source Java application server built on top of Eclipse MicroProfile and Jakarta EE standards. It's integrated into the unified Docker stack for:

- RESTful API development (JAX-RS/Jakarta REST)
- MicroProfile services (health checks, metrics, config)
- Database access (JDBC/JPA)
- Cloud-native deployments

## Architecture

```
                         Internet
                             |
                           HTTPS
                             |
                    [Nginx Reverse Proxy]
                    - SSL/TLS Termination
                    - Rate Limiting
                    - Security Headers
                             |
            /api  /health  /liberty
                    |
            [Open Liberty (9080)]
              - Java App Server
              - REST APIs
              - MicroProfile
                    |
         [PostgreSQL] [Redis] [Chrome CDP]
```

## Quick Start

### 1. Build Open Liberty Container

```bash
cd stash/
docker build -f open-liberty/Dockerfile -t open-liberty:custom .
```

### 2. Start Stack

```bash
docker compose -f docker-compose.unified.yml up -d liberty
```

### 3. Verify Health Check

```bash
# Direct access
curl http://localhost:9080/health

# Via Nginx
curl https://localhost/liberty/health

# Via Docker
docker logs liberty
```

### 4. Access Services

| Endpoint | Description |
|----------|-------------|
| `http://localhost:9080/health` | MicroProfile Health Check |
| `http://localhost:9080/api/status` | API Status Endpoint |
| `http://localhost:9080/api/info` | System Information |
| `http://localhost:9080/api/echo` | Echo Service (POST) |
| `https://localhost/liberty/...` | Via Nginx |

## Configuration

### Server Configuration (server.xml)

Located at: `stash/open-liberty/server.xml`

Key features:
- Port 9080 (HTTP), 9443 (HTTPS)
- Web Profile 10.0 (Jakarta EE 10)
- MicroProfile features (health, metrics, config)
- PostgreSQL datasource
- Security configuration (JWT, SSL)
- Session management
- Logging

### Environment Variables

```yaml
environment:
  JAVA_OPTS: "-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"
  WLP_OUTPUT_DIR: /opt/ol/wlp/output
  DB_PASSWORD: uniscrape
  TZ: UTC
```

### Database Connection

PostgreSQL is auto-configured:
```xml
<datasource id="DefaultDataSource" jndiName="jdbc/DefaultDS">
    <jdbcDriver libraryRef="PostgreSQLLibrary"/>
    <properties.postgresql
        serverName="postgres"
        portNumber="5432"
        databaseName="uniscrape"
        user="uniscrape"
        password="${DB_PASSWORD}"/>
</datasource>
```

Usage in Java:
```java
@Resource(lookup = "jdbc/DefaultDS")
private DataSource ds;

// Use ds for database operations
```

## Deploying Applications

### Option A: WAR File (Recommended)

1. Build your application:
```bash
mvn clean package
```

2. Copy WAR to Liberty:
```bash
docker cp target/myapp.war liberty:/opt/ol/wlp/usr/servers/defaultServer/dropins/
```

3. Liberty auto-deploys (check logs):
```bash
docker logs -f liberty | grep "myapp"
```

### Option B: Update server.xml

Add application definition:
```xml
<webApplication location="myapp.war" contextRoot="/myapp" />
```

Restart Liberty:
```bash
docker compose -f docker-compose.unified.yml restart liberty
```

### Option C: Docker Volume Mount

For development with hot reload:
```yaml
volumes:
  - ./apps/myapp:/opt/ol/wlp/usr/servers/defaultServer/dropins:ro
```

## REST API Development

### Create a REST Resource

```java
package com.example.api;

import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

@Path("/api/items")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ItemsResource {

    @GET
    public Response listItems() {
        // Query database
        return Response.ok(items).build();
    }

    @POST
    public Response createItem(Item item) {
        // Save to database
        return Response.status(201).entity(item).build();
    }

    @GET
    @Path("/{id}")
    public Response getItem(@PathParam("id") String id) {
        return Response.ok(item).build();
    }
}
```

### Test Endpoints

```bash
# List items
curl http://localhost:9080/api/items

# Create item
curl -X POST http://localhost:9080/api/items \
  -H "Content-Type: application/json" \
  -d '{"name":"Item 1"}'

# Get item
curl http://localhost:9080/api/items/123
```

## Database Access

### JDBC (Direct SQL)

```java
@Resource(lookup = "jdbc/DefaultDS")
private DataSource ds;

public List<Item> getItems() throws SQLException {
    try (Connection conn = ds.getConnection();
         Statement stmt = conn.createStatement();
         ResultSet rs = stmt.executeQuery("SELECT * FROM items")) {
        
        List<Item> items = new ArrayList<>();
        while (rs.next()) {
            items.add(new Item(rs.getInt("id"), rs.getString("name")));
        }
        return items;
    }
}
```

### JPA (ORM)

1. Add persistence configuration (persistence.xml):
```xml
<persistence-unit name="defaultPU" transaction-type="JTA">
    <provider>org.eclipse.persistence.jpa.PersistenceProvider</provider>
    <jta-data-source>jdbc/DefaultDS</jta-data-source>
    <class>com.example.Item</class>
    <properties>
        <property name="eclipselink.ddl-generation" value="create-tables"/>
    </properties>
</persistence-unit>
```

2. Create entity:
```java
@Entity
@Table(name = "items")
public class Item {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;
    
    @Column(name = "name")
    private String name;
}
```

3. Use EntityManager:
```java
@PersistenceContext(unitName = "defaultPU")
private EntityManager em;

public void saveItem(Item item) {
    em.persist(item);
}
```

## Health Checks

### MicroProfile Health

Access at: `http://localhost:9080/health`

Response:
```json
{
    "status": "UP",
    "checks": [
        {
            "name": "OpenLibertyLiveness",
            "status": "UP",
            "data": {
                "status": "UP",
                "timestamp": 1715000000000
            }
        }
    ]
}
```

### Custom Health Check

```java
@Health
@ApplicationScoped
public class DatabaseHealthCheck implements HealthCheck {

    @Resource(lookup = "jdbc/DefaultDS")
    private DataSource ds;

    @Override
    public HealthCheckResponse call() {
        try (Connection conn = ds.getConnection()) {
            return HealthCheckResponse.up("Database")
                    .withData("connection", "OK")
                    .build();
        } catch (Exception e) {
            return HealthCheckResponse.down("Database")
                    .withData("error", e.getMessage())
                    .build();
        }
    }
}
```

## Metrics

### Enable Metrics

In server.xml:
```xml
<feature>mpMetrics-5.0</feature>
```

Access metrics: `http://localhost:9080/metrics`

### Custom Metrics

```java
@Inject
@RegistryType(type = MetricRegistry.Type.APPLICATION)
MetricRegistry registry;

public void recordEvent(String name) {
    Counter counter = registry.counter(name);
    counter.inc();
}
```

## Configuration via MicroProfile Config

### application.properties

```properties
# Database
quarkus.datasource.jdbc.url=jdbc:postgresql://postgres:5432/uniscrape
quarkus.datasource.username=uniscrape
quarkus.datasource.password=secret

# Application
app.name=MyApp
app.version=1.0.0
```

### Access Configuration

```java
@Inject
@ConfigProperty(name = "app.name", defaultValue = "MyApp")
private String appName;
```

## Security

### JWT Authentication

In server.xml:
```xml
<feature>jwtSso-1.0</feature>
```

### HTTPS

Liberty uses SSL by default (configured in server.xml). Behind Nginx, HTTP is used internally, HTTPS is terminated at Nginx.

### User Authentication

```java
@RolesAllowed({"ADMIN", "USER"})
@GET
@Path("/admin")
public Response adminEndpoint() {
    return Response.ok("Admin access granted").build();
}
```

## Logging

### View Logs

```bash
# Real-time
docker logs -f liberty

# All logs
docker logs liberty

# With timestamp
docker logs -f --timestamps liberty
```

### Log Configuration

In server.xml:
```xml
<logging
    traceSpecification="*=info"
    maxFileSize="20M"
    maxFiles="10"
    logDirectory="/opt/ol/wlp/output/defaultServer/logs">
</logging>
```

JSON logging:
```xml
<jvm>
    <option>-Dcom.ibm.ws.logging.console.format=json</option>
</jvm>
```

## Performance Tuning

### JVM Options

```yaml
environment:
  JAVA_OPTS: "-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseStringDeduplication -XX:+ParallelRefProcEnabled"
```

### Connection Pooling

In server.xml:
```xml
<connectionManager
    maxPoolSize="20"
    minPoolSize="5"
    connectionTimeout="30s"
    reapTime="180s"/>
```

### Session Persistence

```xml
<httpSession
    invalidationTimeout="30m"
    idLength="40"
    cookieSecure="true"
    cookieHttpOnly="true"
    cookieSameSite="Strict"/>
```

## Troubleshooting

### Application Not Deploying

```bash
# Check logs
docker logs liberty | grep -i deploy

# Verify WAR location
docker exec liberty ls -la /opt/ol/wlp/usr/servers/defaultServer/dropins/

# Check file permissions
docker exec liberty chmod 644 /opt/ol/wlp/usr/servers/defaultServer/dropins/*.war
```

### Database Connection Failed

```bash
# Test database connectivity
docker exec liberty curl -X POST http://postgres:5432 || echo "Connection failed"

# Check datasource configuration
docker exec liberty cat /opt/ol/wlp/output/defaultServer/logs/messages.log | grep -i datasource
```

### High Memory Usage

```bash
# Check JVM heap
docker exec liberty jps -lmv

# Reduce MaxRAMPercentage
# Edit docker-compose.yml:
# JAVA_OPTS: "-XX:MaxRAMPercentage=50.0"
```

### SSL Certificate Errors

```bash
# Regenerate certificates
docker exec liberty rm -f /opt/ol/wlp/output/defaultServer/resources/security/*

# Restart Liberty
docker compose -f docker-compose.unified.yml restart liberty
```

## Integration with Stack Services

### Calling UniScrape from Liberty

```java
@WebClient
private RestClientBuilder builder;

public String scrapeContent(String url) {
    String response = builder.baseUri(URI.create("http://uniscrape:8085"))
        .build(UniScrapeClient.class)
        .scrape(url);
    return response;
}
```

### Calling Stash from Liberty

```java
@Inject
@RestClient
private StashClient stashClient;

public List<Scene> getScenes() {
    return stashClient.listScenes();
}
```

## Deployment to Production

1. **Update Credentials**
   ```yaml
   DB_PASSWORD: <strong-random-password>
   ```

2. **Configure SSL Certificates**
   ```bash
   # Place proper CA certificates in:
   stash/open-liberty/resources/security/
   ```

3. **Scale Resources**
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '4'
         memory: 4G
   ```

4. **Enable Monitoring**
   ```bash
   # Access metrics dashboard (if integrated)
   curl https://yourdomain.com/liberty/metrics
   ```

5. **Set Up Backups**
   ```bash
   # Backup Liberty configuration
   docker exec liberty tar czf - /opt/ol/wlp/usr/servers/defaultServer > liberty-backup.tar.gz
   ```

## References

- Open Liberty: https://openliberty.io/
- Jakarta EE: https://jakarta.ee/
- MicroProfile: https://microprofile.io/
- JAX-RS/Jakarta REST: https://jakarta.ee/specifications/restful-ws/
- OpenAPI: https://www.openapis.org/

---

**Version**: 1.0.0
**Updated**: 2026-05-05
**Status**: Production Ready
