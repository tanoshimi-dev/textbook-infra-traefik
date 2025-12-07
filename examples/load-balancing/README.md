# Load Balancing Examples

This directory contains practical examples of load balancing with Traefik.

## Examples Included

### 1. Basic Load Balancing (`docker-compose.loadbalancing.yml`)

Demonstrates:
- Auto-scaling with `--scale` flag
- Weighted load balancing
- Sticky sessions
- Health checks

**Start:**
```bash
docker-compose -f docker-compose.loadbalancing.yml up -d --scale flask-app=3
```

**Test:**
```bash
./test-loadbalancing.sh
```

### 2. Advanced Load Balancing (`docker-compose.advanced-lb.yml`)

Demonstrates:
- Rate limiting
- Circuit breaker
- Retry logic
- Compression
- Prometheus metrics

**Start:**
```bash
docker-compose -f docker-compose.advanced-lb.yml up -d
```

## Quick Test Commands

### Test Round-Robin Distribution

```bash
# Make 10 requests and see different hosts
for i in {1..10}; do
  curl -s http://flask.localhost | grep -o '"host":"[^"]*"'
  sleep 0.2
done
```

### Test Weighted Load Balancing

```bash
# Instance 1 should get ~2x more requests than Instance 2
for i in {1..20}; do
  curl -s http://nodejs.localhost | grep -o '"host":"[^"]*"'
done | sort | uniq -c
```

### Test Sticky Sessions

```bash
# All requests should go to same server
for i in {1..5}; do
  curl -s -c cookies.txt -b cookies.txt http://static.localhost
done
```

### Test Rate Limiting

```bash
# Should get rate limited after ~100 requests/second
for i in {1..200}; do
  curl -s -o /dev/null -w "%{http_code}\n" http://flask.localhost
done
# You'll see some 429 (Too Many Requests) responses
```

## Scaling Commands

### Scale Up
```bash
# Scale Flask to 5 instances
docker-compose -f docker-compose.loadbalancing.yml up -d --scale flask-app=5
```

### Scale Down
```bash
# Scale Flask to 2 instances
docker-compose -f docker-compose.loadbalancing.yml up -d --scale flask-app=2
```

### Check Running Instances
```bash
docker-compose -f docker-compose.loadbalancing.yml ps
```

## Monitoring

### Traefik Dashboard
Visit http://localhost:8080 to see:
- All backend servers
- Health status
- Request distribution
- Real-time metrics

### Prometheus Metrics
```bash
curl http://localhost:8080/metrics
```

### View Logs
```bash
# All services
docker-compose -f docker-compose.loadbalancing.yml logs -f

# Specific service
docker-compose -f docker-compose.loadbalancing.yml logs -f flask-app
```

## Load Balancing Strategies

### Round-Robin (Default)
- Distributes requests evenly across all servers
- Good for stateless applications
- Example: Flask app

### Weighted Round-Robin
- Give different weights to different servers
- Use when servers have different capacities
- Example: Node.js app (weight 2:1)

### Sticky Sessions
- Same user always goes to same server
- Needed for stateful applications
- Example: Static app with cookies

## Production Tips

1. **Always use health checks**
   - Traefik won't send traffic to unhealthy containers
   - Define health check path and interval

2. **Set resource limits**
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '0.5'
         memory: 512M
   ```

3. **Use circuit breakers**
   - Prevent cascading failures
   - Automatically stop sending traffic to failing services

4. **Implement rate limiting**
   - Protect against traffic spikes
   - Prevent abuse

5. **Monitor metrics**
   - Use Prometheus + Grafana
   - Track response times and error rates

## Troubleshooting

### Requests going to one server only

Check:
- Are all containers running? `docker-compose ps`
- Are health checks passing?
- Is sticky sessions enabled when it shouldn't be?

### Some containers not receiving traffic

Check:
- Container health status in Traefik dashboard
- Container logs for errors
- Port configuration in labels

### Rate limiting not working

Check:
- Middleware is applied in router labels
- Rate limit values are appropriate
- Test with enough requests

## Next Steps

1. Test each example
2. Modify parameters (replicas, weights, limits)
3. Monitor dashboard while making requests
4. Try breaking a container (kill it) and watch Traefik adapt
5. Implement in your production setup
