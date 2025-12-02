#!/bin/bash
#===============================================================================
# ex10x - Rebuild Script
#
# Run this script after pulling new changes to rebuild the site
# Usage: sudo ./rebuild.sh
#===============================================================================

set -e

APP_DIR="/var/www/ex10x"
APP_USER="www-data"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== ex10x Rebuild Script ===${NC}\n"

cd $APP_DIR

echo "Pulling latest changes..."
git pull

echo "Installing dependencies..."
npm ci --production=false

echo "Building site..."
npm run build

echo "Setting permissions..."
chown -R $APP_USER:$APP_USER $APP_DIR

echo -e "\n${GREEN}✓ Done! Site has been rebuilt.${NC}"
echo "Clear your browser cache if changes don't appear immediately."
