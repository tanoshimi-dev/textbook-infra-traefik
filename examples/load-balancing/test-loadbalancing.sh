#!/bin/bash

# Load Balancing Test Script
# This script helps you verify load balancing is working

echo "========================================="
echo "Traefik Load Balancing Test"
echo "========================================="

# Function to test a service
test_service() {
    local URL=$1
    local NAME=$2

    echo ""
    echo "Testing $NAME at $URL"
    echo "Making 10 requests to see distribution..."
    echo "----------------------------------------"

    for i in {1..10}; do
        RESPONSE=$(curl -s $URL)
        HOST=$(echo $RESPONSE | grep -o '"host":"[^"]*"' | cut -d'"' -f4)
        echo "Request $i: $HOST"
        sleep 0.5
    done
}

# Test Flask (scaled instances)
echo ""
echo "[1/3] Testing Flask Load Balancing"
echo "Make sure you started with: docker-compose up -d --scale flask-app=3"
test_service "http://flask.localhost" "Flask API"

# Test Node.js (weighted)
echo ""
echo "[2/3] Testing Node.js Weighted Load Balancing"
echo "Instance 1 has weight=2, Instance 2 has weight=1"
echo "You should see roughly 2:1 ratio"
test_service "http://nodejs.localhost" "Node.js API"

# Test Static (sticky sessions)
echo ""
echo "[3/3] Testing Static with Sticky Sessions"
echo "All requests should go to the same server (because of sticky sessions)"
echo "----------------------------------------"

for i in {1..5}; do
    curl -s -c cookies.txt -b cookies.txt http://static.localhost > /dev/null
    COOKIE=$(cat cookies.txt | grep server_id | awk '{print $7}')
    echo "Request $i: Cookie = $COOKIE"
    sleep 0.5
done

rm -f cookies.txt

echo ""
echo "========================================="
echo "Test Complete!"
echo "========================================="
echo ""
echo "Check Traefik Dashboard for more details:"
echo "  http://localhost:8080"
echo ""
echo "To see which containers are running:"
echo "  docker-compose ps"
echo ""
