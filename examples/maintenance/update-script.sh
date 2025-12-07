#!/bin/bash

# Application Update Script
# Usage: ./update-script.sh <service-name>
# Example: ./update-script.sh flask-app

set -e

APP_NAME=$1

if [ -z "$APP_NAME" ]; then
    echo "Error: Please provide service name"
    echo "Usage: ./update-script.sh <service-name>"
    echo "Example: ./update-script.sh flask-app"
    exit 1
fi

echo "========================================="
echo "Starting update for: $APP_NAME"
echo "========================================="

# Step 1: Pull latest code (if using git)
echo "[1/6] Pulling latest code..."
# git pull origin main

# Step 2: Backup current version
echo "[2/6] Tagging current version as backup..."
docker tag $APP_NAME:latest $APP_NAME:backup || true

# Step 3: Build new image
echo "[3/6] Building new image..."
docker-compose build $APP_NAME

# Step 4: Stop and remove old container
echo "[4/6] Stopping old container..."
docker-compose stop $APP_NAME

# Step 5: Start new container
echo "[5/6] Starting updated container..."
docker-compose up -d --no-deps $APP_NAME

# Step 6: Health check
echo "[6/6] Performing health check..."
sleep 5

STATUS=$(docker-compose ps $APP_NAME | grep -c "Up" || true)
if [ $STATUS -eq 1 ]; then
    echo "========================================="
    echo "✓ Update successful!"
    echo "Service $APP_NAME is running"
    echo "========================================="
    docker-compose ps $APP_NAME
else
    echo "========================================="
    echo "✗ Update failed! Rolling back..."
    echo "========================================="
    docker tag $APP_NAME:backup $APP_NAME:latest
    docker-compose up -d --no-deps $APP_NAME
    exit 1
fi

# View logs
echo ""
echo "Recent logs:"
docker-compose logs --tail=20 $APP_NAME
