# Quick Start Guide

Get up and running with Traefik in under 5 minutes!

## Prerequisites

- Docker Desktop installed and running
- Terminal/Command Prompt

## Step 1: Navigate to Project

```bash
cd xxx\learning\traefik
```

## Step 2: Start Everything

```bash
docker-compose up -d --build
```

This command will:
- Build 3 application images (Flask, Node.js, Static)
- Start Traefik reverse proxy
- Configure automatic routing

Wait 30-60 seconds for everything to start.

## Step 3: Verify Services Are Running

```bash
docker-compose ps
```

You should see all services in "Up" state:
```
NAME          STATUS
traefik       Up
flask-app     Up
nodejs-app    Up
static-app    Up
```

## Step 4: Test Your Applications

### Option 1: Using Browser

Open these URLs in your browser:

- http://static.localhost - Landing page with all links
- http://flask.localhost - Flask API
- http://nodejs.localhost - Node.js API
- http://localhost:8080 - Traefik Dashboard

### Option 2: Using curl

```bash
# Test Flask API
curl http://flask.localhost

# Test Node.js API
curl http://nodejs.localhost

# Test specific endpoints
curl http://flask.localhost/api/users
curl http://nodejs.localhost/api/products
```

## Step 5: Explore Traefik Dashboard

Visit http://localhost:8080

You'll see:
- All active services
- Routing rules
- Entry points
- Real-time request stats

## Common Issues

### Issue: Can't access *.localhost domains

**Solution**: Add to your hosts file

Windows: `C:\Windows\System32\drivers\etc\hosts`
```
127.0.0.1 flask.localhost
127.0.0.1 nodejs.localhost
127.0.0.1 static.localhost
```

### Issue: Port 80 already in use

**Solution**: Stop other services using port 80
```bash
# Find what's using port 80
netstat -ano | findstr :80

# Or change Traefik port in docker-compose.yml
ports:
  - "8000:80"  # Use port 8000 instead
```

### Issue: Containers not starting

**Solution**: Check logs
```bash
docker-compose logs
```

## Stopping Everything

```bash
# Stop services
docker-compose down

# Stop and remove everything including volumes
docker-compose down -v
```

## What's Next?

1. Check the main [README.md](README.md) for detailed explanations
2. Experiment with adding your own service
3. Try different routing rules
4. Learn about HTTPS setup for production

## Quick Reference

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild after changes
docker-compose up -d --build

# View running containers
docker-compose ps

# Restart specific service
docker-compose restart flask-app
```

## Success Checklist

- [ ] All 4 containers running
- [ ] Can access http://static.localhost
- [ ] Can access http://flask.localhost
- [ ] Can access http://nodejs.localhost
- [ ] Can see services in Traefik dashboard at http://localhost:8080
- [ ] API endpoints return JSON data

If all boxes are checked, you're ready to start learning Traefik!

## Need Help?

- Check [README.md](README.md) for detailed documentation
- View container logs: `docker-compose logs -f`
- Restart everything: `docker-compose down && docker-compose up -d --build`
