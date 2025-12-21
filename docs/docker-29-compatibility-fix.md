# Traefik Docker 29.x Compatibility Fix

## Issue Summary

When running Traefik with Docker Engine 29.0.1 (Docker Desktop 4.53.0), you may encounter the following error:

```
time="2025-12-21T03:45:10Z" level=error msg="Failed to retrieve information of the docker client and server host: Error response from daemon: " providerName=docker
```

This error appears continuously in the logs and prevents Traefik from discovering and routing to Docker containers.

## Root Cause

This is a **known incompatibility between Traefik v3.x and Docker Engine 29.x**. Docker 29 introduced breaking changes to the API version negotiation that affects how Traefik v3 queries the Docker daemon's `/info` endpoint.

Key technical details:
- Docker Engine 29.x uses API version 1.52
- Docker 29 increased minimum API version to 1.44
- Traefik v3.x has compatibility issues with the new API response format
- The error message is empty because the daemon returns an unexpected response format

## Solution

**Downgrade to Traefik v2.11** which has better compatibility with Docker Engine 29.x.

### Updated docker-compose.yml Configuration

```yaml
services:
    traefik:
        image: traefik:v2.11  # Changed from v3.x
        container_name: traefik
        command:
            - "--api.insecure=true"
            - "--api.dashboard=true"
            - "--providers.docker=true"
            - "--providers.docker.exposedbydefault=false"
            - "--providers.docker.endpoint=unix:///var/run/docker.sock"
            - "--providers.docker.network=traefik-network"
            - "--entrypoints.web.address=:80"
            - "--log.level=INFO"
        ports:
            - "80:80"
            - "8080:8080"
        volumes:
            - /var/run/docker.sock:/var/run/docker.sock:ro
        environment:
            - DOCKER_API_VERSION=1.44
        networks:
            - traefik-network
        restart: unless-stopped
```

### Key Changes Applied

1. **Image Version**: Changed from `traefik:v3.2` to `traefik:v2.11`
2. **Removed**: `traefik.yml` config file mount (using command-line configuration instead)
3. **Added**: `DOCKER_API_VERSION=1.44` environment variable to pin API version
4. **Added**: Explicit command-line flags for all configuration
5. **Removed**: Obsolete `version: '3.8'` from docker-compose.yml

## Verification Steps

After applying the fix, verify that Traefik is working correctly:

### 1. Check for errors in logs
```bash
docker compose logs traefik | grep -i error
```
Expected: No "Error response from daemon" messages

### 2. Verify container discovery
```bash
curl -s http://localhost:8080/api/http/routers | python3 -m json.tool | grep '"name":'
```
Expected: Should show your application routers (e.g., `flask@docker`, `nodejs@docker`)

### 3. Test routing
```bash
curl -H "Host: flask.localhost" http://localhost/
curl -H "Host: nodejs.localhost" http://localhost/
curl -H "Host: static.localhost" http://localhost/
```
Expected: Each should return the appropriate application response

### 4. Access Traefik dashboard
```
http://localhost:8080
```
Expected: Dashboard loads and shows all discovered services

## Production Deployment Notes

### For Production Environments

When deploying to production, you'll likely encounter the same issue if your server has:
- Docker Engine 29.x or newer
- Traefik v3.x

**Recommendations for production:**

1. **Use Traefik v2.11** until Traefik v3.x fully supports Docker Engine 29.x
2. **Pin the Traefik version** explicitly (don't use `:latest`)
3. **Set DOCKER_API_VERSION=1.44** in environment variables
4. **Enable proper logging** to catch issues early
5. **Test thoroughly** after any Docker or Traefik version updates

### Alternative Solutions (If you must use Traefik v3.x)

If you require Traefik v3.x features, consider these workarounds:

1. **Downgrade Docker Engine** to version 27.x (not recommended for production)
2. **Wait for a Traefik update** that fixes the compatibility issue
3. **Use file-based provider** instead of Docker provider (requires manual configuration)

### Monitoring for Future Fixes

Track these resources for updates:
- [Traefik GitHub Issues](https://github.com/traefik/traefik/issues)
- [Traefik Community Forum - Docker Provider Issues](https://community.traefik.io/c/traefik/traefik-v3)
- Release notes for Traefik v3.3+ versions

## Environment Information

This fix was tested and confirmed working with:
- **OS**: Linux 6.6.87.2-microsoft-standard-WSL2 (WSL2 on Windows)
- **Docker Engine**: 29.0.1
- **Docker API Version**: 1.52
- **Docker Desktop**: 4.53.0
- **Traefik**: v2.11 (working) vs v3.2/v3.3 (broken)

## Additional Resources

- [Traefik v3.x Docker Provider fails on macOS Docker Desktop](https://community.traefik.io/t/traefik-v3-x-docker-provider-fails-with-empty-error-response-from-daemon-on-macos-docker-desktop/29454)
- [Docker 29 increased minimum API version, breaks Traefik](https://forums.docker.com/t/docker-29-increased-minimum-api-version-breaks-traefik-reverse-proxy/150384)
- [Traefik GitHub Issue #12253](https://github.com/traefik/traefik/issues/12253)

## Troubleshooting

### If you still see errors after applying the fix:

1. **Completely remove and recreate containers:**
   ```bash
   docker compose down -v
   docker compose pull
   docker compose up -d
   ```

2. **Check Docker socket permissions:**
   ```bash
   ls -la /var/run/docker.sock
   # Should show: srw-rw---- 1 root docker
   ```

3. **Verify user is in docker group:**
   ```bash
   groups
   # Should include "docker"
   ```

4. **Check Docker daemon is healthy:**
   ```bash
   docker info
   ```

## Date
Fixed: 2025-12-21
