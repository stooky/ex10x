# ex10x Ubuntu Server Deployment Guide

This guide walks you through deploying the ex10x Astro website on an Ubuntu server (22.04 LTS recommended).

## Prerequisites

- Ubuntu 22.04 LTS server (Vultr, DigitalOcean, AWS, etc.)
- Root or sudo access
- Domain name pointed to your server's IP (optional but recommended)
- SSH access to your server

## Quick Start

### Option 1: Automated Installation

1. SSH into your server:
   ```bash
   ssh root@your-server-ip
   ```

2. Clone the repo and run the installer:
   ```bash
   git clone https://github.com/stooky/ex10x.git
   cd ex10x/deploy
   ```

3. Run the installer:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

### Option 2: Manual Installation

Follow the steps below if you prefer manual control.

---

## Manual Installation Steps

### Step 1: Update System

```bash
sudo apt update && sudo apt upgrade -y
```

### Step 2: Install Node.js 20

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

Verify installation:
```bash
node -v  # Should show v20.x.x
npm -v   # Should show 10.x.x
```

### Step 3: Install Nginx

```bash
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
```

### Step 4: Install Certbot (for SSL)

```bash
sudo apt install -y certbot python3-certbot-nginx
```

### Step 5: Clone the Repository

```bash
sudo mkdir -p /var/www/ex10x
cd /var/www
sudo git clone https://github.com/stooky/ex10x.git ex10x
cd ex10x
```

### Step 6: Install Dependencies & Build

```bash
sudo npm ci
sudo npm run build
```

### Step 7: Set Permissions

```bash
sudo chown -R www-data:www-data /var/www/ex10x
```

### Step 8: Configure Nginx

Create the site configuration:

```bash
sudo nano /etc/nginx/sites-available/ex10x
```

Paste this configuration:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name ex10x.com www.ex10x.com;

    root /var/www/ex10x/dist;
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

    # Handle Astro routing
    location / {
        try_files $uri $uri/ $uri.html =404;
    }

    # Custom 404
    error_page 404 /404.html;

    # Deny hidden files
    location ~ /\. {
        deny all;
    }
}
```

Enable the site:

```bash
sudo ln -sf /etc/nginx/sites-available/ex10x /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

### Step 9: Configure Firewall

```bash
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

### Step 10: Set Up SSL (Recommended)

Make sure your domain is pointing to your server, then:

```bash
sudo certbot --nginx -d ex10x.com -d www.ex10x.com
```

Follow the prompts. Certbot will automatically configure nginx for HTTPS.

---

## Updating the Site

After making changes to the site:

### Using the rebuild script (recommended):

```bash
sudo /var/www/ex10x/deploy/rebuild.sh
```

### Manual update:

```bash
cd /var/www/ex10x
sudo git pull
sudo npm ci
sudo npm run build
sudo chown -R www-data:www-data /var/www/ex10x
```

---

## Troubleshooting

### Site not loading

1. Check nginx status:
   ```bash
   sudo systemctl status nginx
   ```

2. Check nginx error logs:
   ```bash
   sudo tail -f /var/log/nginx/error.log
   ```

3. Verify the dist folder exists:
   ```bash
   ls -la /var/www/ex10x/dist
   ```

### Permission errors

```bash
sudo chown -R www-data:www-data /var/www/ex10x
sudo chmod -R 755 /var/www/ex10x
```

### Build fails

1. Check Node.js version:
   ```bash
   node -v
   ```

2. Clear npm cache and reinstall:
   ```bash
   cd /var/www/ex10x
   sudo rm -rf node_modules
   sudo npm cache clean --force
   sudo npm ci
   ```

### SSL certificate issues

Renew certificates manually:
```bash
sudo certbot renew --dry-run
```

Check certificate status:
```bash
sudo certbot certificates
```

### Repair: Installed with wrong domain (example.com)

If you ran the installer with `example.com` as the domain and need to fix it:

```bash
# 1. Update the nginx config
sudo nano /etc/nginx/sites-available/ex10x
```

Change the `server_name` line from:
```nginx
server_name example.com www.example.com;
```
To:
```nginx
server_name ex10x.com www.ex10x.com;
```

```bash
# 2. Test and reload nginx
sudo nginx -t
sudo systemctl reload nginx

# 3. Set up SSL for the correct domain
sudo certbot --nginx -d ex10x.com -d www.ex10x.com

# 4. (Optional) Remove old example.com SSL cert if created
sudo certbot delete --cert-name example.com
```

**One-liner fix** (if no SSL was set up yet):
```bash
sudo sed -i 's/example\.com/ex10x.com/g' /etc/nginx/sites-available/ex10x && sudo nginx -t && sudo systemctl reload nginx
```

---

## Server Maintenance

### View access logs
```bash
sudo tail -f /var/log/nginx/access.log
```

### View error logs
```bash
sudo tail -f /var/log/nginx/error.log
```

### Restart nginx
```bash
sudo systemctl restart nginx
```

### Check disk space
```bash
df -h
```

### Check memory usage
```bash
free -m
```

---

## Directory Structure on Server

```
/var/www/ex10x/
├── dist/           # Built static files (served by nginx)
├── src/            # Source files
├── deploy/         # Deployment scripts
│   ├── install.sh
│   ├── rebuild.sh
│   └── INSTALL.md
├── node_modules/   # npm dependencies
├── package.json
└── ...
```

---

## Security Recommendations

1. **Keep system updated:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Set up automatic security updates:**
   ```bash
   sudo apt install -y unattended-upgrades
   sudo dpkg-reconfigure -plow unattended-upgrades
   ```

3. **Disable root SSH login** (after creating a regular user):
   ```bash
   sudo nano /etc/ssh/sshd_config
   # Set: PermitRootLogin no
   sudo systemctl restart sshd
   ```

4. **Use SSH keys instead of passwords**

5. **Install fail2ban:**
   ```bash
   sudo apt install -y fail2ban
   sudo systemctl enable fail2ban
   ```

---

## Vultr-Specific Notes

1. **Firewall:** Vultr has its own firewall. Make sure to allow ports 22, 80, and 443 in the Vultr dashboard under "Firewall".

2. **DNS:** Point your domain to the Vultr server's IP address:
   - A record: `@` → `YOUR_SERVER_IP`
   - A record: `www` → `YOUR_SERVER_IP`

3. **Backups:** Consider enabling Vultr's automatic backups for your instance.

---

## Quick Reference Commands

| Action | Command |
|--------|---------|
| Rebuild site | `sudo /var/www/ex10x/deploy/rebuild.sh` |
| Restart nginx | `sudo systemctl restart nginx` |
| View logs | `sudo tail -f /var/log/nginx/access.log` |
| Test nginx config | `sudo nginx -t` |
| Check SSL cert | `sudo certbot certificates` |
| Renew SSL | `sudo certbot renew` |
