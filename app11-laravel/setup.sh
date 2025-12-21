#!/bin/bash

echo "🚀 Setting up Laravel application..."

# Navigate to root directory
cd "$(dirname "$0")/.."

# Build and start the Laravel container
echo "📦 Building and starting Laravel container..."
docker-compose up -d --build laravel-app

# Wait for container to be ready
echo "⏳ Waiting for container to be ready..."
sleep 5

# Install Composer dependencies
echo "📚 Installing Composer dependencies..."
docker exec -it laravel-app composer install

# Generate application key
echo "🔑 Generating application key..."
docker exec -it laravel-app php artisan key:generate

# Set permissions
echo "🔒 Setting proper permissions..."
docker exec -it laravel-app chown -R www-data:www-data /var/www/storage
docker exec -it laravel-app chmod -R 775 /var/www/storage

echo "✅ Setup complete!"
echo ""
echo "🌐 Application is available at: http://laravel.localhost"
echo "📊 Traefik dashboard: http://localhost:8080"
echo ""
echo "📝 Test the API:"
echo "   curl http://laravel.localhost/api/health"
echo "   curl http://laravel.localhost/api/users"
