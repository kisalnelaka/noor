#!/bin/bash
set -e

APP_DIR="/home/ubuntu/apps/noor"
NGINX_CONF="/home/ubuntu/apps/tenancyos/deployment/nginx/default.conf"

echo "🚀 Synchronizing NOOR AI..."

# 1. Deploy/Update Containers FIRST
# This ensures "noor-backend" exists on the network before Nginx tries to find it.
echo "🏗️ Starting NOOR Backend Services..."
cd "$APP_DIR"

if [ -f "backend/deployment/docker-compose.vps.yml" ]; then
    docker compose -f backend/deployment/docker-compose.vps.yml build
    docker compose -f backend/deployment/docker-compose.vps.yml up -d
    echo "✅ Containers are up."
else
    echo "⚠️ backend/deployment/docker-compose.vps.yml missing. Please ensure code is pushed/uploaded."
    exit 1
fi

# 2. Wait 3 seconds for network registration
sleep 3

# 3. Update Nginx Configuration safely
if ! grep -q "noor.tenancyos.com" "$NGINX_CONF"; then
    echo "🌐 Injecting NOOR proxy into main Nginx config..."
    sudo bash -c "cat $APP_DIR/noor-proxy.conf >> $NGINX_CONF"
    docker exec deployment-nginx-1 nginx -s reload
else
    echo "🔄 Reloading Nginx..."
    docker exec deployment-nginx-1 nginx -s reload
fi

echo "✨ NOOR is now available at https://noor.tenancyos.com"
docker ps | grep noor
