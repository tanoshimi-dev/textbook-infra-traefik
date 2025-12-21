# Docker Compose Configuration Explanation

## Overview

The `docker-compose.yml` file at the root of this project defines and orchestrates the entire multi-service infrastructure. It sets up **Traefik as a reverse proxy** to route traffic to multiple backend applications based on hostnames.

## Purpose

This file is required because it provides **infrastructure as code** - a single `docker-compose up` command starts the entire multi-application environment with proper routing configured.

## Services Defined

### 1. Traefik Service (Reverse Proxy/Load Balancer)

```yaml
traefik:
    image: traefik:v2.10
    container_name: traefik
```

**Key Features:**
- Routes HTTP traffic on port 80
- Provides a management dashboard on port 8080
- Automatically discovers Docker containers via Docker socket
- Reads configuration from `traefik.yml` and `dynamic-config.yml`
- Uses insecure API mode for development purposes

**Ports Exposed:**
- `80:80` - HTTP traffic entry point
- `8080:8080` - Traefik dashboard

**Volumes Mounted:**
- `/var/run/docker.sock` - Docker socket for container discovery (read-only)
- `./traefik.yml` - Static Traefik configuration
- `./dynamic-config.yml` - Dynamic routing configuration

### 2. Flask Application

```yaml
flask-app:
    build: ./app1-flask
    container_name: flask-app
```

**Access:** `http://flask.localhost`

**Traefik Labels:**
- Enables Traefik routing
- Routes requests with hostname `flask.localhost`
- Application runs on internal port 5000

### 3. Node.js Application

```yaml
nodejs-app:
    build: ./app2-nodejs
    container_name: nodejs-app
```

**Access:** `http://nodejs.localhost`

**Traefik Labels:**
- Enables Traefik routing
- Routes requests with hostname `nodejs.localhost`
- Application runs on internal port 3000

### 4. Static Website

```yaml
static-app:
    build: ./app3-static
    container_name: static-app
```

**Access:** `http://static.localhost`

**Traefik Labels:**
- Enables Traefik routing
- Routes requests with hostname `static.localhost`
- Nginx serves content on internal port 80

### 5. Laravel Application

```yaml
laravel-app:
    build: ./app11-laravel
    container_name: laravel-app
```

**Access:** `http://laravel.localhost` or `http://localhost:8000`

**Special Configuration:**
- Also exposed directly on host port 8000
- Volume mounts source code for development
- Application runs on internal port 80

## Network Configuration

```yaml
networks:
    traefik-network:
        driver: bridge
```

All services are connected to a shared `traefik-network` bridge network, which:
- Allows all services to communicate with each other
- Enables Traefik to discover and route to backend services
- Provides network isolation from other Docker networks

## Why This File is Required

Without this docker-compose.yml file, you would need to:

1. **Manually start each container individually** with complex `docker run` commands
2. **Manually configure networking** between containers
3. **Manually set up routing rules** for each application
4. **Manually manage container dependencies** and startup order
5. **Manually configure environment variables** and volume mounts

The docker-compose.yml file provides:

- **Single command deployment**: `docker-compose up -d`
- **Automatic service discovery**: Traefik finds containers automatically
- **Declarative configuration**: Infrastructure defined as code
- **Easy scaling and updates**: Modify the file and redeploy
- **Consistent development environment**: Same setup across different machines

## Usage

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down

# Rebuild and restart
docker-compose up -d --build
```

## Key Takeaways

This docker-compose.yml is the **foundation of the entire infrastructure**. It defines how multiple applications coexist and are accessed through a single reverse proxy (Traefik), making it easy to:

- Run multiple applications on the same host
- Access each application via a friendly hostname
- Manage all services with simple commands
- Scale or modify the infrastructure by editing one file
