#!/bin/bash

# Zero-Trust Router Demo Launcher
# This script sets up and runs the complete demo

set -e

echo "=========================================="
echo "  Zero-Trust Boot Protocol Demo"
echo "=========================================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running"
    echo "Please start Docker and try again"
    exit 1
fi

echo "✓ Docker is running"
echo ""

# Clean up any existing demo
echo "Cleaning up previous demo..."
docker-compose down -v 2>/dev/null || true
echo "✓ Cleanup complete"
echo ""

# Build and start containers
echo "Building demo environment..."
docker-compose build --no-cache
echo "✓ Build complete"
echo ""

echo "Starting demo containers..."
docker-compose up -d
echo "✓ Containers started"
echo ""

# Wait for services to be ready
echo "Waiting for services to initialize..."
sleep 5
echo "✓ Services ready"
echo ""

echo "=========================================="
echo "  Demo is Ready!"
echo "=========================================="
echo ""
echo "🌐 Router Interface: http://localhost:8080"
echo ""
echo "What to do:"
echo "1. Open http://localhost:8080 in your browser"
echo "2. You'll see the provisioning page (State 0)"
echo "3. Create a password (try: SecurePass123!)"
echo "4. Watch the router transition to secure state"
echo ""
echo "To test security features:"
echo "  ./test-attacks.sh"
echo ""
echo "To stop demo:"
echo "  docker-compose down"
echo ""
echo "To view logs:"
echo "  docker-compose logs -f router"
echo ""
