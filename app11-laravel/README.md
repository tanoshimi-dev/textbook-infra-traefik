# Laravel API with Traefik

A simple Laravel API application managed by Traefik reverse proxy.

## Setup Instructions

### 1. Build and Start the Application

From the root directory (`textbook-infra-traefik`):

```bash
# Build and start all services (including Laravel)
docker-compose up -d --build

# Or just rebuild and start Laravel
docker-compose up -d --build laravel-app
```

### 2. Install Laravel Dependencies

After the container is running, install Composer dependencies:

```bash
docker exec -it laravel-app composer install
```

### 3. Generate Application Key

```bash
docker exec -it laravel-app php artisan key:generate
```

### 4. Set Permissions

```bash
docker exec -it laravel-app chown -R www-data:www-data /var/www/storage
docker exec -it laravel-app chmod -R 775 /var/www/storage
```

## Access the Application

The Laravel app is accessible via:
- **Traefik (recommended):** http://laravel.localhost
- **Direct access:** http://localhost:8000

## API Endpoints

### Health Check
```bash
# Root endpoint
curl http://laravel.localhost/

# API health check
curl http://laravel.localhost/api/health
```

### User Management API

**Get all users:**
```bash
curl http://laravel.localhost/api/users
```

**Get a single user:**
```bash
curl http://laravel.localhost/api/users/1
```

**Create a new user:**
```bash
curl -X POST http://laravel.localhost/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "New User", "email": "newuser@example.com"}'
```

**Update a user:**
```bash
curl -X PUT http://laravel.localhost/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{"name": "Updated Name", "email": "updated@example.com"}'
```

**Delete a user:**
```bash
curl -X DELETE http://laravel.localhost/api/users/1
```

**Get current user:**
```bash
curl http://laravel.localhost/api/me
```

## Traefik Dashboard

Access the Traefik dashboard at: **http://localhost:8080**

You should see the `laravel-app` service registered with the route rule `Host(laravel.localhost)`.

## Development

### View Logs
```bash
docker logs -f laravel-app
```

### Access Container Shell
```bash
docker exec -it laravel-app bash
```

### Run Artisan Commands
```bash
docker exec -it laravel-app php artisan list
docker exec -it laravel-app php artisan route:list
```

## Troubleshooting

### If you get "Permission Denied" errors:
```bash
docker exec -it laravel-app chown -R www-data:www-data /var/www
docker exec -it laravel-app chmod -R 775 /var/www/storage
```

### If vendor directory is missing:
```bash
docker exec -it laravel-app composer install
```

### Restart the service:
```bash
docker-compose restart laravel-app
```

## Notes

- This is a minimal Laravel setup for API development
- Users are stored in-memory (not persisted to a database)
- For production use, you would need to add a database service and configure Laravel accordingly
- CORS middleware may need to be configured for frontend applications
