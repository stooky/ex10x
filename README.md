# ex10x

Personal brand website for Chris Fossenier focused on teaching AI productivity techniques, specifically "vibe coding" and AI automation.

**Live site:** https://ex10x.com

## Tech Stack

- **Framework:** [Astro](https://astro.build/) 5.x (static site generation)
- **Styling:** [Tailwind CSS](https://tailwindcss.com/) 4.x with Typography plugin
- **Build:** Vite (via Astro)
- **Language:** TypeScript
- **Hosting:** Vultr Ubuntu server with nginx

## Project Structure

```
ex10x/
├── src/
│   ├── components/
│   │   ├── Navigation.astro
│   │   └── Footer.astro
│   ├── content/
│   │   └── blog/              # Markdown blog posts
│   ├── layouts/
│   │   └── Layout.astro
│   ├── pages/
│   │   ├── index.astro        # Home page
│   │   ├── about.astro
│   │   ├── book.astro
│   │   ├── videos.astro
│   │   └── blog/
│   │       ├── index.astro    # Blog listing
│   │       └── [...slug].astro # Individual posts
│   ├── styles/
│   │   └── global.css
│   └── content.config.ts      # Blog content schema
├── public/                    # Static assets
├── dist/                      # Built output (generated)
├── deploy/                    # Server deployment scripts
│   ├── install.sh
│   ├── rebuild.sh
│   ├── nginx.conf.template
│   └── INSTALL.md
├── docs/
│   └── captains_log/          # Development session logs
└── startup.bat                # Windows dev server script
```

## Local Development (Windows)

### Quick Start

```bash
# Install dependencies
npm install

# Start dev server (recommended method)
startup.bat
```

The `startup.bat` script automatically:
1. Kills any existing process on port 4321
2. Starts the Astro dev server
3. Opens http://localhost:4321

### Manual Start

```bash
npm run dev
```

### All Commands

| Command | Action |
|---------|--------|
| `startup.bat` | Kill existing processes and start dev server |
| `npm install` | Install dependencies |
| `npm run dev` | Start dev server at localhost:4321 |
| `npm run build` | Build production site to `./dist/` |
| `npm run preview` | Preview production build locally |

## Production Server (Ubuntu)

The site is deployed on a Vultr Ubuntu server running nginx.

### Server Details

- **URL:** https://ex10x.com
- **Server:** Vultr Ubuntu 22.04 LTS
- **Web Server:** nginx (static file serving)
- **SSL:** Let's Encrypt (auto-renewal)
- **App Directory:** `/var/www/ex10x`
- **Web Root:** `/var/www/ex10x/dist`

### Deployment

See [`deploy/INSTALL.md`](deploy/INSTALL.md) for complete setup instructions.

**Quick deploy after code changes:**

```bash
# SSH to server
ssh root@your-server-ip

# Run rebuild script
sudo /var/www/ex10x/deploy/rebuild.sh
```

The rebuild script:
1. Pulls latest from GitHub
2. Installs dependencies (`npm ci`)
3. Builds the site (`npm run build`)
4. Sets correct permissions

### Server Commands

| Action | Command |
|--------|---------|
| Rebuild site | `sudo /var/www/ex10x/deploy/rebuild.sh` |
| Restart nginx | `sudo systemctl restart nginx` |
| Reload nginx (no downtime) | `sudo systemctl reload nginx` |
| Check nginx status | `sudo systemctl status nginx` |
| Test nginx config | `sudo nginx -t` |
| View access logs | `sudo tail -f /var/log/nginx/access.log` |
| View error logs | `sudo tail -f /var/log/nginx/error.log` |
| Check SSL certificate | `sudo certbot certificates` |
| Renew SSL | `sudo certbot renew` |

### Server Files

| File | Purpose |
|------|---------|
| `/var/www/ex10x/` | Application directory |
| `/var/www/ex10x/dist/` | Built static files (served by nginx) |
| `/etc/nginx/sites-available/ex10x` | Nginx configuration |
| `/etc/letsencrypt/live/ex10x.com/` | SSL certificates |

## Deployment Scripts

Located in the `deploy/` directory:

| File | Purpose |
|------|---------|
| `install.sh` | Full server setup script (Node.js, nginx, SSL, firewall) |
| `rebuild.sh` | Quick rebuild after pulling changes |
| `nginx.conf.template` | Reference nginx config with security headers |
| `INSTALL.md` | Comprehensive deployment documentation |

## Captain's Logs

Development session logs are stored in `docs/captains_log/`. These serve as:

- **Handoff documents** for resuming work between sessions
- **Decision records** explaining why things were built a certain way
- **Progress tracking** across work sessions
- **Context for AI assistants** to understand project history

### Log Files

```
docs/captains_log/
├── caplog-20251201-215525-beginning-of-ex10x.txt
├── caplog-20251201-221500-added-startup-script.txt
└── caplog-20251201-223000-deployed-to-the-cloud.txt
```

Read the most recent log to understand current project state and next steps.

## Architecture Notes

### Static Site (No SSR)

This is a **static site** - Astro builds HTML/CSS/JS files that nginx serves directly. There is no Node.js process running in production.

Benefits:
- Fast page loads (no server rendering)
- Simple deployment (just serve files)
- Secure (no server-side code execution)
- No process manager needed (no PM2)

### Blog System

Blog posts use Astro's [Content Collections](https://docs.astro.build/en/guides/content-collections/):

1. Add markdown files to `src/content/blog/`
2. Frontmatter defines title, date, description
3. Build generates static HTML pages

### Styling

- Tailwind CSS 4 with Vite plugin (not PostCSS)
- Typography plugin for blog post formatting
- Utility classes in components
- Global styles in `src/styles/global.css`

## Git Workflow

```bash
# Make changes locally
npm run dev

# Test build
npm run build

# Commit and push
git add .
git commit -m "Description of changes"
git push origin main

# Deploy to server
ssh root@server-ip
sudo /var/www/ex10x/deploy/rebuild.sh
```

## Repository

- **GitHub:** https://github.com/stooky/ex10x

## License

Private project - All rights reserved.
