# Traefik Use Cases Guide

This guide covers practical scenarios you'll encounter when managing multiple applications with Traefik on a VPS.

## Table of Contents

1. [Application Maintenance & Updates](#1-application-maintenance--updates)
2. [Multiple Domains & SSL Management](#2-multiple-domains--ssl-management)
3. [Load Balancing](#3-load-balancing)

---

## 1. Application Maintenance & Updates

### Scenario: Update one app without affecting others

When you need to update, fix bugs, or maintain a specific application while keeping other services running.

### Method 1: Zero-Downtime Update (Recommended for Production)

**Step 1: Build new version**
```bash
# Build updated image with new tag
cd app1-flask
docker build -t flask-app:v2 .
```

**Step 2: Start new container alongside old one**
```bash
# Add new container to docker-compose.yml temporarily
docker-compose up -d flask-app-v2
```

**Step 3: Switch traffic using labels**
```yaml
# Update labels to point to new version
flask-app-v2:
  image: flask-app:v2
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.flask.rule=Host(`flask.localhost`)"
```

**Step 4: Stop old container**
```bash
docker-compose stop flask-app
docker-compose rm flask-app
```

### Method 2: Rolling Update (Simple approach)

```bash
# Stop specific service
docker-compose stop flask-app

# Rebuild the service
docker-compose build flask-app

# Start updated service
docker-compose up -d flask-app

# Verify it's working
curl http://flask.localhost/health
```

**Other services continue running without interruption!**

### Method 3: Using Docker Deploy (Production)

Create update script `update-app.sh`:

```bash
#!/bin/bash
APP_NAME=$1

echo "Updating $APP_NAME..."

# Pull latest code
git pull origin main

# Rebuild specific service
docker-compose build $APP_NAME

# Recreate container
docker-compose up -d --no-deps $APP_NAME

# Check health
docker-compose ps $APP_NAME

echo "$APP_NAME updated successfully!"
```

Usage:
```bash
chmod +x update-app.sh
./update-app.sh flask-app
```

### Health Checks for Safe Updates

Add health checks to docker-compose.yml:

```yaml
flask-app:
  build: ./app1-flask
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.flask.rule=Host(`flask.localhost`)"
    - "traefik.http.services.flask.loadbalancer.server.port=5000"
    # Health check configuration
    - "traefik.http.services.flask.loadbalancer.healthcheck.path=/health"
    - "traefik.http.services.flask.loadbalancer.healthcheck.interval=10s"
    - "traefik.http.services.flask.loadbalancer.healthcheck.timeout=3s"
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 40s
```

### Rollback Strategy

**Quick Rollback:**
```bash
# Keep old image tagged
docker tag flask-app:latest flask-app:backup

# If update fails, rollback
docker-compose down flask-app
docker tag flask-app:backup flask-app:latest
docker-compose up -d flask-app
```

### Best Practices

1. **Always test locally first**
2. **Backup database before updates**
3. **Use health checks**
4. **Monitor logs during update**
   ```bash
   docker-compose logs -f flask-app
   ```
5. **Keep old image for quick rollback**

---

## 2. Multiple Domains & SSL Management

### Scenario: Host multiple applications with different domains and HTTPS

### Setup Structure for Production

**Update traefik.yml for SSL:**

```yaml
api:
  dashboard: true
  insecure: false  # Secure dashboard in production

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
          permanent: true
  
  websecure:
    address: ":443"
    http:
      tls:
        certResolver: letsencrypt

certificatesResolvers:
  letsencrypt:
    acme:
      email: your-email@example.com
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: traefik-network

log:
  level: INFO
```

### Docker Compose for Multiple Domains

```yaml
version: '3.8'

services:
  traefik:
    image: traefik:v2.10
    container_name: traefik
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik.yml:/etc/traefik/traefik.yml:ro
      - ./letsencrypt:/letsencrypt
    networks:
      - traefik-network
    restart: unless-stopped

  # Flask API on api.example.com
  flask-app:
    build: ./app1-flask
    container_name: flask-app
    labels:
      - "traefik.enable=true"
      # HTTP Router
      - "traefik.http.routers.flask.rule=Host(`api.example.com`)"
      - "traefik.http.routers.flask.entrypoints=websecure"
      - "traefik.http.routers.flask.tls=true"
      - "traefik.http.routers.flask.tls.certresolver=letsencrypt"
      - "traefik.http.services.flask.loadbalancer.server.port=5000"
    networks:
      - traefik-network
    restart: unless-stopped

  # Node.js API on shop.example.com
  nodejs-app:
    build: ./app2-nodejs
    container_name: nodejs-app
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.nodejs.rule=Host(`shop.example.com`)"
      - "traefik.http.routers.nodejs.entrypoints=websecure"
      - "traefik.http.routers.nodejs.tls=true"
      - "traefik.http.routers.nodejs.tls.certresolver=letsencrypt"
      - "traefik.http.services.nodejs.loadbalancer.server.port=3000"
    networks:
      - traefik-network
    restart: unless-stopped

  # Static site on www.example.com
  static-app:
    build: ./app3-static
    container_name: static-app
    labels:
      - "traefik.enable=true"
      # Support both www and non-www
      - "traefik.http.routers.static.rule=Host(`www.example.com`) || Host(`example.com`)"
      - "traefik.http.routers.static.entrypoints=websecure"
      - "traefik.http.routers.static.tls=true"
      - "traefik.http.routers.static.tls.certresolver=letsencrypt"
      - "traefik.http.services.static.loadbalancer.server.port=80"
    networks:
      - traefik-network
    restart: unless-stopped

networks:
  traefik-network:
    driver: bridge
```

### Multiple Domains for Single Application

```yaml
blog-app:
  build: ./blog
  labels:
    - "traefik.enable=true"
    # Multiple domains for same app
    - "traefik.http.routers.blog.rule=Host(`blog.example.com`) || Host(`articles.example.com`)"
    - "traefik.http.routers.blog.entrypoints=websecure"
    - "traefik.http.routers.blog.tls=true"
    - "traefik.http.routers.blog.tls.certresolver=letsencrypt"
```

### Subdomain Routing

```yaml
admin-app:
  build: ./admin
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.admin.rule=Host(`admin.example.com`)"
    - "traefik.http.routers.admin.entrypoints=websecure"
    - "traefik.http.routers.admin.tls=true"
    - "traefik.http.routers.admin.tls.certresolver=letsencrypt"
```

### Wildcard SSL Certificates

For wildcard domains (*.example.com), use DNS challenge:

```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: your-email@example.com
      storage: /letsencrypt/acme.json
      dnsChallenge:
        provider: cloudflare  # or your DNS provider
        resolvers:
          - "1.1.1.1:53"
          - "8.8.8.8:53"
```

Set environment variables:
```bash
export CF_API_EMAIL=your-email@example.com
export CF_API_KEY=your-cloudflare-api-key
```

### SSL Certificate Management

**Check certificate status:**
```bash
# View acme.json (where certs are stored)
cat letsencrypt/acme.json | jq

# Check certificate expiry in Traefik dashboard
# Visit https://your-domain:8080
```

**Certificate auto-renewal:**
- Let's Encrypt certificates auto-renew
- Traefik handles renewal automatically
- Certificates valid for 90 days
- Renewal happens at 30 days before expiry

**Force certificate regeneration:**
```bash
# Stop Traefik
docker-compose stop traefik

# Remove acme.json
rm letsencrypt/acme.json

# Create new acme.json with correct permissions
touch letsencrypt/acme.json
chmod 600 letsencrypt/acme.json

# Restart Traefik
docker-compose up -d traefik
```

### Using Custom SSL Certificates

If you have your own SSL certificates:

```yaml
traefik:
  volumes:
    - ./certs:/certs
  command:
    - "--providers.file.filename=/certs/dynamic.yml"
```

Create `certs/dynamic.yml`:
```yaml
tls:
  certificates:
    - certFile: /certs/example.com.crt
      keyFile: /certs/example.com.key
    - certFile: /certs/shop.example.com.crt
      keyFile: /certs/shop.example.com.key
```

### Environment Variables for Domains

Use `.env` file for easier management:

```bash
# .env
DOMAIN_API=api.example.com
DOMAIN_SHOP=shop.example.com
DOMAIN_MAIN=example.com
EMAIL=your-email@example.com
```

Reference in docker-compose.yml:
```yaml
labels:
  - "traefik.http.routers.flask.rule=Host(`${DOMAIN_API}`)"
```

---

## 3. Load Balancing

### Scenario: Scale applications to handle more traffic

### Simple Load Balancing (Multiple Replicas)

**Method 1: Using docker-compose scale**

```yaml
flask-app:
  build: ./app1-flask
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.flask.rule=Host(`flask.localhost`)"
    - "traefik.http.services.flask.loadbalancer.server.port=5000"
  networks:
    - traefik-network
  restart: unless-stopped
```

Scale to 3 instances:
```bash
docker-compose up -d --scale flask-app=3
```

Traefik automatically load balances between all 3 containers!

### Load Balancing Algorithms

**Round Robin (Default):**
```yaml
labels:
  - "traefik.http.services.flask.loadbalancer.server.port=5000"
```

**Weighted Round Robin:**
```yaml
# Give different weights to instances
flask-app-1:
  labels:
    - "traefik.http.services.flask.loadbalancer.server.port=5000"
    - "traefik.http.services.flask.loadbalancer.server.weight=2"

flask-app-2:
  labels:
    - "traefik.http.services.flask.loadbalancer.server.port=5000"
    - "traefik.http.services.flask.loadbalancer.server.weight=1"
```

**Sticky Sessions (Session Affinity):**

For applications that need same user → same server:

```yaml
labels:
  - "traefik.http.services.flask.loadbalancer.sticky.cookie=true"
  - "traefik.http.services.flask.loadbalancer.sticky.cookie.name=flask_session"
  - "traefik.http.services.flask.loadbalancer.sticky.cookie.secure=true"
  - "traefik.http.services.flask.loadbalancer.sticky.cookie.httpOnly=true"
```

### Advanced Load Balancing Setup

**Complete example with health checks and sticky sessions:**

```yaml
version: '3.8'

services:
  traefik:
    image: traefik:v2.10
    container_name: traefik
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik.yml:/etc/traefik/traefik.yml:ro
    networks:
      - traefik-network
    restart: unless-stopped

  flask-app:
    build: ./app1-flask
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.flask.rule=Host(`api.example.com`)"
      - "traefik.http.routers.flask.entrypoints=websecure"
      - "traefik.http.routers.flask.tls=true"
      - "traefik.http.routers.flask.tls.certresolver=letsencrypt"
      
      # Load balancer configuration
      - "traefik.http.services.flask.loadbalancer.server.port=5000"
      
      # Health check
      - "traefik.http.services.flask.loadbalancer.healthcheck.path=/health"
      - "traefik.http.services.flask.loadbalancer.healthcheck.interval=10s"
      - "traefik.http.services.flask.loadbalancer.healthcheck.timeout=3s"
      
      # Sticky sessions
      - "traefik.http.services.flask.loadbalancer.sticky.cookie=true"
      - "traefik.http.services.flask.loadbalancer.sticky.cookie.name=server_id"
      
    networks:
      - traefik-network
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  traefik-network:
    driver: bridge
```

Deploy with:
```bash
docker-compose up -d --scale flask-app=3
```

### Manual Load Balancing (Different Servers)

Create separate containers pointing to same domain:

```yaml
flask-app-1:
  build: ./app1-flask
  container_name: flask-app-1
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.flask.rule=Host(`api.example.com`)"
    - "traefik.http.services.flask.loadbalancer.server.port=5000"
  networks:
    - traefik-network

flask-app-2:
  build: ./app1-flask
  container_name: flask-app-2
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.flask.rule=Host(`api.example.com`)"
    - "traefik.http.services.flask.loadbalancer.server.port=5000"
  networks:
    - traefik-network

flask-app-3:
  build: ./app1-flask
  container_name: flask-app-3
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.flask.rule=Host(`api.example.com`)"
    - "traefik.http.services.flask.loadbalancer.server.port=5000"
  networks:
    - traefik-network
```

### Testing Load Balancing

**Test round-robin distribution:**

```bash
# Make multiple requests
for i in {1..10}; do
  curl http://api.example.com/ | jq .host
done

# You should see different container hostnames
```

**Monitor in Traefik Dashboard:**
- Visit http://localhost:8080
- Go to HTTP Services
- See all backend servers
- Check health status

### Circuit Breaker Pattern

Prevent cascading failures:

Add to traefik.yml:
```yaml
http:
  middlewares:
    circuit-breaker:
      circuitBreaker:
        expression: "NetworkErrorRatio() > 0.3 || ResponseCodeRatio(500, 600, 0, 600) > 0.3"
```

Use in docker-compose.yml:
```yaml
labels:
  - "traefik.http.routers.flask.middlewares=circuit-breaker@file"
```

### Rate Limiting

Protect your services from overload:

```yaml
labels:
  - "traefik.http.middlewares.rate-limit.ratelimit.average=100"
  - "traefik.http.middlewares.rate-limit.ratelimit.burst=50"
  - "traefik.http.routers.flask.middlewares=rate-limit"
```

### Blue-Green Deployment

Zero-downtime deployments with instant rollback:

```yaml
# Blue (Current production)
flask-app-blue:
  build: ./app1-flask
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.flask.rule=Host(`api.example.com`)"
    - "traefik.http.services.flask.loadbalancer.server.port=5000"

# Green (New version - disabled initially)
flask-app-green:
  build: ./app1-flask
  labels:
    - "traefik.enable=false"  # Disabled until ready
```

**Switch to green:**
```bash
# Enable green, disable blue
docker-compose up -d flask-app-green
# Update labels to switch traffic
# If issues, instant rollback by re-enabling blue
```

### Monitoring Load Balancing

**View backend servers:**
```bash
# Check Traefik dashboard
# Or use API
curl http://localhost:8080/api/http/services
```

**Prometheus metrics (advanced):**

Add to traefik.yml:
```yaml
metrics:
  prometheus:
    addEntryPointsLabels: true
    addServicesLabels: true
```

Access metrics:
```bash
curl http://localhost:8080/metrics
```

### Auto-Scaling (Docker Swarm)

For production auto-scaling, use Docker Swarm:

```yaml
version: '3.8'

services:
  flask-app:
    image: flask-app:latest
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.flask.rule=Host(`api.example.com`)"
```

Deploy:
```bash
docker stack deploy -c docker-compose.yml mystack
```

Scale:
```bash
docker service scale mystack_flask-app=5
```

---

## Summary

### Use Case 1: Maintenance & Updates
- Update individual apps without downtime
- Use health checks for safe deployments
- Keep rollback strategy ready

### Use Case 2: Multiple Domains & SSL
- Automatic SSL with Let's Encrypt
- Support multiple domains per app
- Auto-renewal of certificates

### Use Case 3: Load Balancing
- Scale with `--scale` flag
- Automatic distribution across replicas
- Sticky sessions for stateful apps
- Health checks ensure traffic to healthy instances

## Next Steps

1. Practice these scenarios locally
2. Set up staging environment
3. Implement monitoring (Prometheus + Grafana)
4. Add logging aggregation (ELK stack)
5. Set up CI/CD pipeline for automated deployments

## Additional Resources

- [Traefik Load Balancing](https://doc.traefik.io/traefik/routing/services/#load-balancing)
- [Let's Encrypt Configuration](https://doc.traefik.io/traefik/https/acme/)
- [Docker Swarm with Traefik](https://doc.traefik.io/traefik/providers/docker/#docker-swarm-mode)
