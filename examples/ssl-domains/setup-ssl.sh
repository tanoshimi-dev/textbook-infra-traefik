#!/bin/bash

# SSL Setup Script for Production
# This script helps you set up SSL certificates with Let's Encrypt

set -e

echo "========================================="
echo "Traefik SSL Setup Script"
echo "========================================="

# Check if .env exists
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo ""
    echo "Please edit .env file and update with your domain and email:"
    echo "  - DOMAIN_* variables"
    echo "  - LETSENCRYPT_EMAIL"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Create letsencrypt directory
echo "[1/4] Creating letsencrypt directory..."
mkdir -p letsencrypt
touch letsencrypt/acme.json
chmod 600 letsencrypt/acme.json

# Check if domains are configured
source .env
if [ "$LETSENCRYPT_EMAIL" = "your-email@example.com" ]; then
    echo ""
    echo "Error: Please update .env file with your actual email and domains!"
    exit 1
fi

# Verify DNS records
echo ""
echo "[2/4] DNS Records Check"
echo "Please verify these DNS records point to your server:"
echo "  A    $DOMAIN_API      -> YOUR_SERVER_IP"
echo "  A    $DOMAIN_SHOP     -> YOUR_SERVER_IP"
echo "  A    $DOMAIN_MAIN     -> YOUR_SERVER_IP"
echo "  A    $DOMAIN_WWW      -> YOUR_SERVER_IP"
echo ""
read -p "Have you configured DNS records? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please configure DNS records first!"
    exit 1
fi

# Start Traefik and apps
echo ""
echo "[3/4] Starting services..."
docker-compose -f docker-compose.production.yml up -d

# Wait for certificates
echo ""
echo "[4/4] Waiting for SSL certificates..."
echo "This may take 1-2 minutes..."
sleep 30

# Check certificate status
echo ""
echo "Checking certificate status..."
if [ -f letsencrypt/acme.json ]; then
    CERT_COUNT=$(cat letsencrypt/acme.json | grep -o "\"domain\"" | wc -l)
    echo "Certificates obtained: $CERT_COUNT domains"
else
    echo "Warning: acme.json not found"
fi

echo ""
echo "========================================="
echo "SSL Setup Complete!"
echo "========================================="
echo ""
echo "Your sites should now be available at:"
echo "  https://$DOMAIN_API"
echo "  https://$DOMAIN_SHOP"
echo "  https://$DOMAIN_MAIN"
echo "  https://$DOMAIN_WWW"
echo ""
echo "Traefik Dashboard:"
echo "  http://YOUR_SERVER_IP:8080"
echo ""
echo "To check logs:"
echo "  docker-compose -f docker-compose.production.yml logs -f traefik"
echo ""
