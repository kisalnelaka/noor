#!/bin/bash

# NOOR AI Isolated Deployment Script (V6.3)
# Live at: noor.tenancyos.com

echo "🚀 Starting NOOR AI Deployment Sync..."

# 1. Pull latest code
echo "📡 Pulling latest changes from GitHub..."
git pull origin main

# 2. Rebuild and Restart Containers
echo "🏗️  Rebuilding NOOR Backend..."
docker compose -f deployment/docker-compose.vps.yml build
docker compose -f deployment/docker-compose.vps.yml up -d

# 3. Apply Nginx Configuration
# We mount the config into the existing tenancyos nginx container
echo "🌐 Syncing Proxy Configuration..."
sudo cp deployment/nginx/noor.conf /home/ubuntu/apps/tenancyos/deployment/nginx/noor.conf
docker exec deployment-nginx-1 nginx -s reload

echo "✅ NOOR AI is now live at noor.tenancyos.com"
docker ps | grep noor
