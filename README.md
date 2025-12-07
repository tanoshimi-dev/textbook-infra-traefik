# Traefik Learning Demo

A comprehensive demo project to learn Traefik reverse proxy with multiple applications running behind it.

## What is Traefik?

Traefik is a modern HTTP reverse proxy and load balancer that makes deploying microservices easy. It integrates with your existing infrastructure components and configures itself automatically and dynamically.

## Project Structure

```
traefik/
├── app1-flask/          # Python Flask API
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
├── app2-nodejs/         # Node.js Express API
│   ├── server.js
│   ├── package.json
│   └── Dockerfile
├── app3-static/         # Static HTML site with Nginx
│   ├── index.html
│   └── Dockerfile
├── traefik.yml          # Traefik configuration
├── docker-compose.yml   # Docker Compose configuration
└── README.md
```

## Applications Included

1. **Flask API** (Python) - REST API with user endpoints
2. **Node.js API** (Express) - REST API with product endpoints
3. **Static Website** (Nginx) - HTML landing page

## Prerequisites

- Docker Desktop installed and running
- Basic understanding of Docker and containers

## Getting Started

### 1. Start All Services

Navigate to the project directory and run:

```bash
cd E:\dev\zed_projects\learning\traefik
docker-compose up -d --build
```

This will:
- Build all three application images
- Start Traefik reverse proxy
- Start all applications
- Configure routing automatically

### 2. Check Running Containers

```bash
docker-compose ps
```

You should see 4 containers running:
- traefik
- flask-app
- nodejs-app
- static-app

### 3. Access Your Applications

Once everything is running, you can access:

- **Flask API**: http://flask.localhost
  - Users endpoint: http://flask.localhost/api/users
  - Health check: http://flask.localhost/health

- **Node.js API**: http://nodejs.localhost
  - Products endpoint: http://nodejs.localhost/api/products
  - Health check: http://nodejs.localhost/health

- **Static Website**: http://static.localhost

- **Traefik Dashboard**: http://localhost:8080
  - Monitor all your services in real-time
  - View routing rules and configurations

## How Traefik Works in This Demo

### 1. Service Discovery

Traefik automatically discovers services through Docker labels. In `docker-compose.yml`:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.flask.rule=Host(`flask.localhost`)"
  - "traefik.http.routers.flask.entrypoints=web"
  - "traefik.http.services.flask.loadbalancer.server.port=5000"
```

### 2. Routing Rules

- `Host()` rule: Routes traffic based on the hostname
- Each service gets its own subdomain (flask.localhost, nodejs.localhost, etc.)
- Traefik listens on port 80 and routes to the correct container

### 3. Entry Points

- **web**: Port 80 for HTTP traffic
- **traefik**: Port 8080 for the dashboard

## Key Traefik Concepts

### Labels Explained

1. `traefik.enable=true`
   - Tells Traefik to manage this container

2. `traefik.http.routers.<name>.rule=Host(\`domain\`)`
   - Defines routing rule (hostname-based in this demo)

3. `traefik.http.routers.<name>.entrypoints=web`
   - Specifies which entry point to use

4. `traefik.http.services.<name>.loadbalancer.server.port=<port>`
   - Tells Traefik which port the container listens on

### Configuration File (traefik.yml)

```yaml
api:
  dashboard: true    # Enable the web dashboard
  insecure: true     # Allow dashboard without auth (dev only!)

entryPoints:
  web:
    address: ":80"   # Listen on port 80

providers:
  docker:            # Use Docker as service provider
    exposedByDefault: false  # Only expose services with traefik.enable=true
```

## Common Commands

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f traefik
docker-compose logs -f flask-app
```

### Stop All Services

```bash
docker-compose down
```

### Rebuild and Restart

```bash
docker-compose up -d --build
```

### Stop and Remove Everything

```bash
docker-compose down -v
```

## Testing the Setup

### Using curl

```bash
# Test Flask API
curl http://flask.localhost
curl http://flask.localhost/api/users

# Test Node.js API
curl http://nodejs.localhost
curl http://nodejs.localhost/api/products
```

### Using Browser

Simply visit the URLs in your browser. The static site at http://static.localhost has links to all services.

## For VPS Deployment

When you're ready to deploy to a VPS, you'll need to make these changes:

### 1. Use Real Domain Names

Replace `.localhost` with your actual domain:

```yaml
- "traefik.http.routers.flask.rule=Host(`api.yourdomain.com`)"
```

### 2. Enable HTTPS with Let's Encrypt

Add to `traefik.yml`:

```yaml
entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"

certificatesResolvers:
  letsencrypt:
    acme:
      email: your-email@example.com
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
```

### 3. Secure the Dashboard

Change `insecure: true` to `false` and add authentication:

```yaml
api:
  dashboard: true
  insecure: false
```

Add middleware for basic auth in docker-compose.yml.

### 4. Use Environment Variables

Store sensitive data in `.env` file:

```env
DOMAIN=yourdomain.com
EMAIL=your-email@example.com
```

## Troubleshooting

### Can't access *.localhost domains

On Windows, you might need to add entries to your hosts file:
```
C:\Windows\System32\drivers\etc\hosts
```

Add:
```
127.0.0.1 flask.localhost
127.0.0.1 nodejs.localhost
127.0.0.1 static.localhost
```

### Containers not starting

Check logs:
```bash
docker-compose logs
```

### Port conflicts

Make sure ports 80 and 8080 are not already in use:
```bash
netstat -ano | findstr :80
netstat -ano | findstr :8080
```

## Documentation

### Quick Start
- **[QUICK-START.md](QUICK-START.md)** - Get running in 5 minutes

### Use Cases & Examples
- **[USECASES.md](USECASES.md)** - Comprehensive guide covering:
  1. Application maintenance and updates
  2. Multiple domains with SSL management
  3. Load balancing strategies

### Practical Examples
- **[examples/](examples/)** - Hands-on examples with ready-to-use configurations:
  - **maintenance/** - Zero-downtime updates, health checks, rollback strategies
  - **ssl-domains/** - Production SSL setup with Let's Encrypt
  - **load-balancing/** - Scaling, sticky sessions, circuit breakers

## Learning Path

### Beginner
1. **Start with basic setup** - Run `docker-compose up -d --build`
2. **Explore Traefik dashboard** - http://localhost:8080
3. **Read [QUICK-START.md](QUICK-START.md)** - Understand the basics

### Intermediate
4. **Study [USECASES.md](USECASES.md)** - Learn real-world scenarios
5. **Try maintenance example** - Practice updating services without downtime
6. **Experiment with load balancing** - Scale services and test distribution

### Advanced
7. **Set up SSL** - Configure Let's Encrypt for production
8. **Implement advanced features** - Rate limiting, circuit breakers, sticky sessions
9. **Deploy to VPS** - Take it to production

## Real-World Use Cases

### 1. Application Maintenance & Updates

Learn how to update your applications without downtime:

```bash
cd examples/maintenance
./update-script.sh flask-app
```

**See:** [examples/maintenance/](examples/maintenance/) for detailed examples

**Topics covered:**
- Zero-downtime deployments
- Blue-green deployments
- Health checks
- Automatic rollback

### 2. Multiple Domains & SSL

Manage multiple applications on different domains with automatic SSL:

```bash
cd examples/ssl-domains
cp .env.example .env
# Edit .env with your domains
./setup-ssl.sh
```

**See:** [examples/ssl-domains/](examples/ssl-domains/) for production setup

**Topics covered:**
- Let's Encrypt integration
- Multiple domains per application
- Automatic certificate renewal
- Admin panel security

### 3. Load Balancing

Scale your applications to handle more traffic:

```bash
cd examples/load-balancing
docker-compose -f docker-compose.loadbalancing.yml up -d --scale flask-app=3
./test-loadbalancing.sh
```

**See:** [examples/load-balancing/](examples/load-balancing/) for examples

**Topics covered:**
- Auto-scaling with replicas
- Weighted load balancing
- Sticky sessions
- Rate limiting
- Circuit breakers

## Quick Commands

```bash
# Start demo
docker-compose up -d --build

# View all services
docker-compose ps

# Scale a service
docker-compose up -d --scale flask-app=3

# Update a specific service
docker-compose up -d --no-deps --build flask-app

# View logs
docker-compose logs -f

# Stop everything
docker-compose down
```

## Resources

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Docker Provider Guide](https://doc.traefik.io/traefik/providers/docker/)
- [Let's Encrypt with Traefik](https://doc.traefik.io/traefik/https/acme/)

## License

This is a learning demo project. Feel free to use and modify as needed.
