#!/bin/bash
#===============================================================================
# ex10x - Ubuntu Server Installation Script
#
# This script installs and configures the ex10x Astro website on Ubuntu 22.04+
# Run as root or with sudo
#===============================================================================

set -e  # Exit on any error

#-------------------------------------------------------------------------------
# Configuration - EDIT THESE VALUES
#-------------------------------------------------------------------------------
DOMAIN="example.com"           # Your domain name (e.g., ex10x.com)
GIT_REPO=""                    # Your git repository URL
APP_DIR="/var/www/ex10x"       # Where to install the app
APP_USER="www-data"            # User to run the app as
NODE_VERSION="20"              # Node.js major version

#-------------------------------------------------------------------------------
# Colors for output
#-------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}===========================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}===========================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

#-------------------------------------------------------------------------------
# Pre-flight checks
#-------------------------------------------------------------------------------
print_header "Pre-flight Checks"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script as root or with sudo"
    exit 1
fi

# Check Ubuntu version
if ! grep -q "Ubuntu" /etc/os-release; then
    print_warning "This script is designed for Ubuntu. Proceed with caution."
fi

print_success "Running as root"

# Check for required configuration
if [ -z "$GIT_REPO" ]; then
    echo -e "${YELLOW}No GIT_REPO configured. You have two options:${NC}"
    echo "  1. Enter a git repository URL now"
    echo "  2. Copy files manually to $APP_DIR later"
    echo ""
    read -p "Enter git repository URL (or press Enter to skip): " GIT_REPO
fi

#-------------------------------------------------------------------------------
# System Update
#-------------------------------------------------------------------------------
print_header "Updating System Packages"

apt-get update
apt-get upgrade -y
print_success "System packages updated"

#-------------------------------------------------------------------------------
# Install Dependencies
#-------------------------------------------------------------------------------
print_header "Installing Dependencies"

apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    nginx \
    certbot \
    python3-certbot-nginx \
    ufw

print_success "Dependencies installed"

#-------------------------------------------------------------------------------
# Install Node.js
#-------------------------------------------------------------------------------
print_header "Installing Node.js $NODE_VERSION"

# Check if Node.js is already installed
if command -v node &> /dev/null; then
    CURRENT_NODE=$(node -v)
    print_warning "Node.js $CURRENT_NODE is already installed"
    read -p "Do you want to reinstall/upgrade? (y/N): " REINSTALL_NODE
    if [ "$REINSTALL_NODE" != "y" ] && [ "$REINSTALL_NODE" != "Y" ]; then
        print_success "Keeping existing Node.js installation"
    else
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
        apt-get install -y nodejs
    fi
else
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
    apt-get install -y nodejs
fi

print_success "Node.js $(node -v) installed"
print_success "npm $(npm -v) installed"

#-------------------------------------------------------------------------------
# Create Application Directory
#-------------------------------------------------------------------------------
print_header "Setting Up Application Directory"

mkdir -p $APP_DIR
chown -R $APP_USER:$APP_USER $APP_DIR

print_success "Created $APP_DIR"

#-------------------------------------------------------------------------------
# Clone/Copy Application
#-------------------------------------------------------------------------------
print_header "Deploying Application"

if [ -n "$GIT_REPO" ]; then
    # Clone from git
    if [ -d "$APP_DIR/.git" ]; then
        print_warning "Git repository already exists. Pulling latest changes..."
        cd $APP_DIR
        git pull
    else
        # Clone to temp and move (in case APP_DIR has files)
        rm -rf /tmp/ex10x-clone
        git clone $GIT_REPO /tmp/ex10x-clone
        cp -r /tmp/ex10x-clone/. $APP_DIR/
        rm -rf /tmp/ex10x-clone
    fi
    print_success "Application cloned from git"
else
    print_warning "No git repository configured."
    echo "Please copy your application files to: $APP_DIR"
    echo "Then run: $APP_DIR/deploy/build.sh"
    echo ""
    read -p "Press Enter to continue with nginx setup, or Ctrl+C to exit..."
fi

#-------------------------------------------------------------------------------
# Install npm Dependencies & Build
#-------------------------------------------------------------------------------
print_header "Building Application"

if [ -f "$APP_DIR/package.json" ]; then
    cd $APP_DIR

    # Install dependencies
    npm ci --production=false
    print_success "npm dependencies installed"

    # Build the site
    npm run build
    print_success "Site built successfully"

    # Set permissions
    chown -R $APP_USER:$APP_USER $APP_DIR
else
    print_warning "No package.json found. Skipping build step."
fi

#-------------------------------------------------------------------------------
# Configure Nginx
#-------------------------------------------------------------------------------
print_header "Configuring Nginx"

# Create nginx config
cat > /etc/nginx/sites-available/ex10x << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;

    root $APP_DIR/dist;
    index index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/json application/xml+rss;

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Handle SPA routing (if needed)
    location / {
        try_files \$uri \$uri/ \$uri.html =404;
    }

    # Custom 404 page
    error_page 404 /404.html;

    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/ex10x /etc/nginx/sites-enabled/

# Remove default site
rm -f /etc/nginx/sites-enabled/default

# Test nginx config
nginx -t

# Reload nginx
systemctl reload nginx

print_success "Nginx configured"

#-------------------------------------------------------------------------------
# Configure Firewall
#-------------------------------------------------------------------------------
print_header "Configuring Firewall"

ufw allow ssh
ufw allow 'Nginx Full'

# Enable firewall if not already enabled
if ! ufw status | grep -q "Status: active"; then
    echo "y" | ufw enable
fi

print_success "Firewall configured"
ufw status

#-------------------------------------------------------------------------------
# SSL Certificate (Optional)
#-------------------------------------------------------------------------------
print_header "SSL Certificate Setup"

if [ "$DOMAIN" != "example.com" ]; then
    echo "Would you like to set up SSL with Let's Encrypt?"
    echo "Make sure your domain ($DOMAIN) is pointing to this server first."
    echo ""
    read -p "Set up SSL now? (y/N): " SETUP_SSL

    if [ "$SETUP_SSL" = "y" ] || [ "$SETUP_SSL" = "Y" ]; then
        read -p "Enter your email for SSL notifications: " SSL_EMAIL
        certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email $SSL_EMAIL
        print_success "SSL certificate installed"

        # Set up auto-renewal
        systemctl enable certbot.timer
        systemctl start certbot.timer
        print_success "SSL auto-renewal configured"
    else
        print_warning "Skipping SSL setup. Run 'certbot --nginx' later to set up SSL."
    fi
else
    print_warning "Domain is set to 'example.com'. Update DOMAIN variable and run certbot manually."
fi

#-------------------------------------------------------------------------------
# Create Update Script
#-------------------------------------------------------------------------------
print_header "Creating Utility Scripts"

# Create update/rebuild script
cat > $APP_DIR/deploy/rebuild.sh << 'EOF'
#!/bin/bash
# Rebuild script for ex10x
# Run this after pulling new changes

set -e

cd /var/www/ex10x

echo "Pulling latest changes..."
git pull

echo "Installing dependencies..."
npm ci --production=false

echo "Building site..."
npm run build

echo "Setting permissions..."
chown -R www-data:www-data /var/www/ex10x

echo "Done! Site has been rebuilt."
EOF

chmod +x $APP_DIR/deploy/rebuild.sh

print_success "Created $APP_DIR/deploy/rebuild.sh"

#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------
print_header "Installation Complete!"

echo -e "${GREEN}ex10x has been installed successfully!${NC}\n"
echo "Summary:"
echo "  - Application directory: $APP_DIR"
echo "  - Web root: $APP_DIR/dist"
echo "  - Nginx config: /etc/nginx/sites-available/ex10x"
echo "  - Domain: $DOMAIN"
echo ""
echo "Useful commands:"
echo "  - Rebuild site:    $APP_DIR/deploy/rebuild.sh"
echo "  - View nginx logs: tail -f /var/log/nginx/access.log"
echo "  - Nginx status:    systemctl status nginx"
echo "  - Test nginx:      nginx -t"
echo ""

if [ "$DOMAIN" = "example.com" ]; then
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Update DOMAIN in this script or nginx config"
    echo "  2. Run: certbot --nginx -d yourdomain.com"
    echo ""
fi

echo -e "${GREEN}Your site should now be accessible at: http://$DOMAIN${NC}"
