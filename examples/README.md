# Traefik Examples

This directory contains practical examples for the three main use cases documented in [USECASES.md](../USECASES.md).

## Directory Structure

```
examples/
├── maintenance/          # Application updates and maintenance
├── ssl-domains/         # Multiple domains with SSL
└── load-balancing/      # Load balancing strategies
```

## Use Case 1: Maintenance & Updates

**Directory:** `maintenance/`

Learn how to:
- Update applications without downtime
- Implement blue-green deployments
- Rollback failed updates
- Use health checks for safe deployments

**Files:**
- `docker-compose.maintenance.yml` - Configuration with health checks
- `update-script.sh` - Automated update script

**Try it:**
```bash
cd maintenance
docker-compose -f docker-compose.maintenance.yml up -d
./update-script.sh flask-app
```

## Use Case 2: Multiple Domains & SSL

**Directory:** `ssl-domains/`

Learn how to:
- Configure multiple domains for different apps
- Set up automatic SSL with Let's Encrypt
- Handle www and non-www domains
- Secure admin panels with basic auth

**Files:**
- `docker-compose.production.yml` - Multi-domain production setup
- `traefik.production.yml` - Production Traefik config with SSL
- `.env.example` - Environment variables template
- `setup-ssl.sh` - Automated SSL setup script

**Try it locally:**
```bash
cd ssl-domains
# Edit .env.example and save as .env
docker-compose -f docker-compose.production.yml up -d
```

**For VPS:**
```bash
cd ssl-domains
cp .env.example .env
# Edit .env with your domains
./setup-ssl.sh
```

## Use Case 3: Load Balancing

**Directory:** `load-balancing/`

Learn how to:
- Scale applications to multiple instances
- Implement weighted load balancing
- Use sticky sessions for stateful apps
- Add rate limiting and circuit breakers

**Files:**
- `docker-compose.loadbalancing.yml` - Basic load balancing
- `docker-compose.advanced-lb.yml` - Advanced features
- `traefik.advanced.yml` - Configuration with metrics
- `test-loadbalancing.sh` - Test script
- `README.md` - Detailed guide

**Try it:**
```bash
cd load-balancing
docker-compose -f docker-compose.loadbalancing.yml up -d --scale flask-app=3
./test-loadbalancing.sh
```

## Quick Reference

### Start an Example

```bash
# Navigate to example directory
cd examples/<use-case>/

# Start services
docker-compose -f <compose-file> up -d

# View logs
docker-compose -f <compose-file> logs -f

# Stop services
docker-compose -f <compose-file> down
```

### Common Commands

```bash
# Check running containers
docker-compose ps

# Scale a service
docker-compose up -d --scale service-name=3

# Restart specific service
docker-compose restart service-name

# View service logs
docker-compose logs -f service-name

# Execute command in container
docker-compose exec service-name sh
```

## Learning Path

1. **Start with basic setup**
   - Run the main docker-compose.yml in root directory
   - Get familiar with Traefik dashboard

2. **Try maintenance example**
   - Practice updating services
   - Test rollback procedures

3. **Explore load balancing**
   - Scale services up and down
   - Test different strategies

4. **Set up SSL (locally or VPS)**
   - Configure domains
   - Test HTTPS setup

## Production Checklist

Before deploying to VPS:

- [ ] DNS records configured and propagated
- [ ] Firewall allows ports 80, 443, and 8080
- [ ] `.env` file configured with real domains
- [ ] Email address set for Let's Encrypt
- [ ] Health checks enabled on all services
- [ ] Resource limits configured
- [ ] Backup strategy in place
- [ ] Monitoring set up
- [ ] Secure Traefik dashboard (disable insecure mode)

## Troubleshooting

### Can't start services

```bash
# Check for port conflicts
netstat -ano | findstr :80
netstat -ano | findstr :8080

# Check Docker is running
docker ps

# View detailed logs
docker-compose logs
```

### SSL certificates not generating

1. Verify DNS records point to your server
2. Check Let's Encrypt rate limits
3. Ensure ports 80/443 are accessible
4. Check traefik logs: `docker-compose logs traefik`

### Load balancing not working

1. Check all replicas are running: `docker-compose ps`
2. Verify health checks are passing (Traefik dashboard)
3. Test with: `curl -s http://your-app | grep host`

## Resources

- Main documentation: [../README.md](../README.md)
- Quick start: [../QUICK-START.md](../QUICK-START.md)
- Use cases: [../USECASES.md](../USECASES.md)
- Official Traefik docs: https://doc.traefik.io/traefik/

## Need Help?

1. Check the Traefik dashboard at http://localhost:8080
2. View container logs
3. Review main documentation
4. Check official Traefik documentation
