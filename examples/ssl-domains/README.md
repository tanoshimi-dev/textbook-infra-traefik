# Multiple Domains & SSL Examples

This directory demonstrates how to manage multiple domains with automatic SSL certificates.

## Files

- `docker-compose.production.yml` - Multi-domain production setup
- `traefik.production.yml` - Traefik configuration with Let's Encrypt
- `.env.example` - Environment variables template
- `setup-ssl.sh` - Automated setup script

## Quick Start

### Local Testing (without real SSL)

```bash
docker-compose -f docker-compose.production.yml up -d
```

Access via:
- http://api.localhost
- http://shop.localhost
- http://www.localhost

### VPS Production Setup

```bash
# 1. Copy environment file
cp .env.example .env

# 2. Edit with your domains
nano .env

# 3. Run setup script
chmod +x setup-ssl.sh
./setup-ssl.sh
```

## Scenarios Covered

### 1. Different Apps on Different Domains

```yaml
# API on api.example.com
flask-app:
  labels:
    - "traefik.http.routers.flask.rule=Host(`api.example.com`)"
    - "traefik.http.routers.flask.tls.certresolver=letsencrypt"

# Shop on shop.example.com  
nodejs-app:
  labels:
    - "traefik.http.routers.nodejs.rule=Host(`shop.example.com`)"
    - "traefik.http.routers.nodejs.tls.certresolver=letsencrypt"
```

### 2. Multiple Domains for Same App

```yaml
static-app:
  labels:
    # Both www and non-www
    - "traefik.http.routers.static.rule=Host(`www.example.com`) || Host(`example.com`)"
    - "traefik.http.routers.static.tls.certresolver=letsencrypt"
```

### 3. Subdomain Routing

```yaml
blog-app:
  labels:
    - "traefik.http.routers.blog.rule=Host(`blog.example.com`)"
    - "traefik.http.routers.blog.tls.certresolver=letsencrypt"

admin-app:
  labels:
    - "traefik.http.routers.admin.rule=Host(`admin.example.com`)"
    - "traefik.http.routers.admin.tls.certresolver=letsencrypt"
```

### 4. Secured Admin Panel

```yaml
admin-app:
  labels:
    # Basic authentication
    - "traefik.http.middlewares.admin-auth.basicauth.users=admin:$$apr1$$..."
    - "traefik.http.routers.admin.middlewares=admin-auth"
```

## SSL Certificate Setup

### HTTP Challenge (Recommended for most cases)

Used in `traefik.production.yml`:

```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: your-email@example.com
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
```

**Requirements:**
- Ports 80 and 443 accessible
- DNS points to your server
- One certificate per domain

### DNS Challenge (For wildcard certificates)

For `*.example.com`:

```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: your-email@example.com
      storage: /letsencrypt/acme.json
      dnsChallenge:
        provider: cloudflare
```

**Environment variables needed:**
```bash
export CF_API_EMAIL=your-email@example.com
export CF_API_KEY=your-cloudflare-api-key
```

## Prerequisites for Production

### 1. DNS Configuration

Configure A records pointing to your VPS IP:

```
A    example.com          -> YOUR_VPS_IP
A    www.example.com      -> YOUR_VPS_IP
A    api.example.com      -> YOUR_VPS_IP
A    shop.example.com     -> YOUR_VPS_IP
A    blog.example.com     -> YOUR_VPS_IP
A    admin.example.com    -> YOUR_VPS_IP
```

Verify DNS propagation:
```bash
nslookup api.example.com
dig api.example.com
```

### 2. Firewall Configuration

Allow required ports:

```bash
# UFW (Ubuntu)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8080/tcp  # Traefik dashboard (or restrict to your IP)

# Or iptables
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

### 3. Configure Environment Variables

Edit `.env` file:

```bash
DOMAIN_API=api.example.com
DOMAIN_SHOP=shop.example.com
DOMAIN_MAIN=example.com
DOMAIN_WWW=www.example.com
LETSENCRYPT_EMAIL=your-email@example.com
```

## SSL Certificate Management

### Check Certificate Status

```bash
# View certificates
docker exec traefik cat /letsencrypt/acme.json | jq

# Or check in Traefik dashboard
# Visit https://your-domain:8080 (after securing it)
```

### Certificate Auto-Renewal

- Certificates valid for 90 days
- Traefik automatically renews at 30 days before expiry
- No manual intervention needed

### Force Certificate Regeneration

If certificates fail to generate:

```bash
# Stop Traefik
docker-compose -f docker-compose.production.yml stop traefik

# Remove acme.json
rm letsencrypt/acme.json

# Create new acme.json
touch letsencrypt/acme.json
chmod 600 letsencrypt/acme.json

# Restart Traefik
docker-compose -f docker-compose.production.yml up -d traefik

# Check logs
docker-compose -f docker-compose.production.yml logs -f traefik
```

## Security Best Practices

### 1. Secure Traefik Dashboard

Change in `traefik.production.yml`:

```yaml
api:
  dashboard: true
  insecure: false  # Disable insecure access
```

Add basic auth:

```bash
# Generate password
htpasswd -nb admin yourpassword

# Add to docker-compose.yml
traefik:
  labels:
    - "traefik.http.routers.api.rule=Host(`traefik.example.com`)"
    - "traefik.http.routers.api.service=api@internal"
    - "traefik.http.routers.api.middlewares=auth"
    - "traefik.http.middlewares.auth.basicauth.users=admin:$$apr1$$..."
```

### 2. Redirect HTTP to HTTPS

Already configured in `traefik.production.yml`:

```yaml
entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
          permanent: true
```

### 3. Admin Panel Protection

```bash
# Generate password hash
htpasswd -nb admin yourpassword

# Output: admin:$apr1$H6uskkkW$IgXLP6ewTrSuBkTrqE8wj/

# Add to .env
ADMIN_AUTH_USER=admin:$$apr1$$H6uskkkW$$IgXLP6ewTrSuBkTrqE8wj/
```

### 4. HSTS Headers

Add to labels:

```yaml
- "traefik.http.middlewares.hsts.headers.stsSeconds=31536000"
- "traefik.http.middlewares.hsts.headers.stsIncludeSubdomains=true"
- "traefik.http.routers.flask.middlewares=hsts"
```

## Testing

### Test SSL Configuration

```bash
# Check certificate
openssl s_client -connect api.example.com:443 -servername api.example.com

# Test SSL rating
# Visit: https://www.ssllabs.com/ssltest/
```

### Test Redirects

```bash
# Should redirect to HTTPS
curl -I http://api.example.com

# Should return 301 or 308
```

### Verify All Domains

```bash
# Test each domain
curl -I https://api.example.com
curl -I https://shop.example.com
curl -I https://www.example.com
curl -I https://example.com
```

## Troubleshooting

### Certificates not generating

**Check:**
1. DNS records are correct and propagated
2. Ports 80/443 are accessible from internet
3. Email address is valid
4. No rate limiting from Let's Encrypt

**Debug:**
```bash
# Check Traefik logs
docker-compose logs traefik | grep -i acme

# Test port accessibility
curl -I http://api.example.com

# Verify DNS
nslookup api.example.com
```

### Let's Encrypt rate limits

- 50 certificates per registered domain per week
- 5 duplicate certificates per week
- Use staging for testing:

```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      caServer: https://acme-staging-v02.api.letsencrypt.org/directory
```

### Wrong certificate issued

```bash
# Clear cache and regenerate
rm letsencrypt/acme.json
docker-compose restart traefik
```

### Mixed content warnings

Ensure all assets use HTTPS:
```html
<!-- Wrong -->
<script src="http://example.com/script.js"></script>

<!-- Correct -->
<script src="https://example.com/script.js"></script>
<!-- Or use protocol-relative -->
<script src="//example.com/script.js"></script>
```

## Production Deployment Checklist

- [ ] DNS records configured and propagated
- [ ] Firewall allows ports 80 and 443
- [ ] `.env` file with real domains
- [ ] Valid email for Let's Encrypt
- [ ] acme.json created with chmod 600
- [ ] Dashboard secured or firewalled
- [ ] HTTPS redirect enabled
- [ ] Test all domains accessible
- [ ] SSL certificates generated successfully
- [ ] Set up monitoring for certificate expiry

## Next Steps

1. Secure the Traefik dashboard
2. Set up monitoring (certificate expiry alerts)
3. Implement HSTS headers
4. Configure CSP headers
5. Set up log aggregation
6. Plan backup strategy for acme.json

## Additional Resources

- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Traefik ACME](https://doc.traefik.io/traefik/https/acme/)
- [SSL Labs Test](https://www.ssllabs.com/ssltest/)
