# Maintenance & Updates Examples

This directory demonstrates how to update and maintain applications with zero downtime.

## Files

- `docker-compose.maintenance.yml` - Setup with health checks and version management
- `update-script.sh` - Automated update script with rollback

## Scenarios Covered

### 1. Zero-Downtime Updates

Run old and new versions simultaneously, then switch:

```bash
# Start with current version
docker-compose -f docker-compose.maintenance.yml up -d

# Deploy new version (disabled initially)
# Edit app code, then:
docker-compose -f docker-compose.maintenance.yml build flask-app-new
docker-compose -f docker-compose.maintenance.yml up -d flask-app-new

# Test new version at http://flask-new.localhost

# Switch traffic by updating labels
# Change flask-app-new traefik.enable=true
# Change flask-app traefik.enable=false
docker-compose -f docker-compose.maintenance.yml up -d

# If all good, remove old version
docker-compose -f docker-compose.maintenance.yml stop flask-app
```

### 2. Simple Rolling Update

Use the update script:

```bash
chmod +x update-script.sh
./update-script.sh flask-app
```

The script:
- Creates backup of current version
- Builds new image
- Stops old container
- Starts new container
- Performs health check
- Rolls back if health check fails

### 3. Manual Update Process

```bash
# Stop service
docker-compose -f docker-compose.maintenance.yml stop flask-app

# Rebuild
docker-compose -f docker-compose.maintenance.yml build flask-app

# Start updated service
docker-compose -f docker-compose.maintenance.yml up -d flask-app

# Check logs
docker-compose -f docker-compose.maintenance.yml logs -f flask-app
```

## Health Checks

Both Docker and Traefik health checks are configured:

**Docker health check:**
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

**Traefik health check:**
```yaml
labels:
  - "traefik.http.services.flask.loadbalancer.healthcheck.path=/health"
  - "traefik.http.services.flask.loadbalancer.healthcheck.interval=10s"
  - "traefik.http.services.flask.loadbalancer.healthcheck.timeout=3s"
```

## Rollback Strategy

### Quick Rollback (using image tags)

```bash
# Before update, tag current version
docker tag flask-app:latest flask-app:backup

# If update fails, rollback
docker tag flask-app:backup flask-app:latest
docker-compose -f docker-compose.maintenance.yml up -d flask-app
```

### Using update script

The script automatically handles rollback if health check fails.

## Best Practices

1. **Always test locally first**
   ```bash
   # Test in development
   docker-compose up -d
   # Verify everything works
   # Then deploy to production
   ```

2. **Use health checks**
   - Ensures Traefik only sends traffic to healthy containers
   - Automatic failover if container becomes unhealthy

3. **Monitor during updates**
   ```bash
   # Watch logs in real-time
   docker-compose logs -f flask-app
   
   # Monitor Traefik dashboard
   # http://localhost:8080
   ```

4. **Keep backup images**
   ```bash
   # Tag versions
   docker tag flask-app:latest flask-app:v1.0
   docker tag flask-app:latest flask-app:v1.1
   ```

5. **Database migrations**
   ```bash
   # Run migrations before updating app
   docker-compose exec flask-app python manage.py migrate
   
   # Then update app
   ./update-script.sh flask-app
   ```

## Testing Updates

### Simulate a failed update

1. Break the application code intentionally
2. Run update script
3. Health check should fail
4. Script should rollback automatically

### Test update workflow

```bash
# Start services
docker-compose -f docker-compose.maintenance.yml up -d

# Make a change to app1-flask/app.py
# For example, add a new endpoint

# Update the service
./update-script.sh flask-app

# Verify change is live
curl http://flask.localhost
```

## Production Workflow

1. **Prepare**
   - Review changes
   - Test in staging environment
   - Plan rollback strategy

2. **Backup**
   ```bash
   # Backup database
   docker-compose exec db pg_dump > backup.sql
   
   # Tag current version
   docker tag myapp:latest myapp:backup
   ```

3. **Deploy**
   ```bash
   ./update-script.sh myapp
   ```

4. **Verify**
   - Check health endpoints
   - Monitor error logs
   - Test critical functionality

5. **Monitor**
   - Watch metrics for 15-30 minutes
   - Check error rates
   - Monitor response times

## Troubleshooting

### Update fails immediately

```bash
# Check build logs
docker-compose build flask-app

# Check if service starts
docker-compose up flask-app

# View startup logs
docker-compose logs flask-app
```

### Health check keeps failing

```bash
# Test health endpoint manually
curl http://localhost:5000/health

# Check container logs
docker-compose logs -f flask-app

# Exec into container
docker-compose exec flask-app sh
curl localhost:5000/health
```

### Old version still responding

```bash
# Verify container is updated
docker-compose ps

# Check image ID
docker images | grep flask-app

# Force recreate
docker-compose up -d --force-recreate flask-app
```

## Advanced: Blue-Green Deployment

For critical applications:

```yaml
# Keep both versions running
flask-app-blue:   # Current production
  traefik.enable=true
  
flask-app-green:  # New version
  traefik.enable=false  # Test first
```

Switch traffic by toggling `traefik.enable` labels.

## Next Steps

1. Practice the update workflow locally
2. Implement automated testing before updates
3. Set up monitoring and alerting
4. Create runbooks for your team
5. Automate with CI/CD pipelines
