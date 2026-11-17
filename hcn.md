# hcn

Idempotent **Nginx** helper with **Let's Encrypt** SSL and an optional cookie gate.

Two site modes:

1. **Proxy** (default) — reverse-proxy to a local Node (or similar) backend  
2. **Static** (`-S`) — serve a `root` directory directly (no proxy; use this instead of `-p 80`)

Aimed at apps behind Cloudflare.

## Install

```bash
# from this configs repo
sudo ./hcn install

# or one-liner (fresh VPS)
curl -fsSL https://raw.githubusercontent.com/KnsDev330/configs/main/hcn \
  | sudo tee /usr/local/bin/hcn >/dev/null \
  && sudo chmod 755 /usr/local/bin/hcn

# anywhere afterwards
sudo hcn -h
hcn version
```

Installs to `/usr/local/bin/hcn` (on the default `sudo` secure path). Any user can run `sudo hcn …`.

```bash
sudo hcn update              # refresh binary from GitHub (when run as installed hcn)
sudo ./hcn update            # install this local checkout over /usr/local/bin/hcn
sudo hcn update --remote     # force GitHub download
sudo hcn update --local      # force install from the file you invoked
sudo hcn uninstall           # remove binary, keep /etc/hcn
sudo hcn uninstall --purge   # also delete /etc/hcn
```

Override download URL with `HC_UPDATE_URL` if needed.

## Quick start

```bash
# save certbot email once (stored in /etc/hcn/config; falls back to /etc/hc/config)
sudo hcn -e admin@example.com -a app.example.com -p 3000

# with cookie gate
sudo hcn -a app.example.com -p 3000 -g

# API sibling
sudo hcn -a api.example.com -p 8080 -g

# Static / default root site (NOT -p 80 — that loops)
sudo hcn -a badsha.example.com -S -g -k pass123 -c p -y
sudo hcn -a docs.example.com -S -R /var/www/docs -g

sudo hcn -l
sudo hcn -s app.example.com
sudo hcn -d app.example.com
```

Re-running `-a` for the same host updates the backend/port/root/gate and refreshes certs safely.

## Check site (`-q`)

```bash
hcn -q app.example.com
# yes  → server block exists, enabled, SSL configured, nginx up, and ready
#        proxy: backend port listening
#        static: root directory exists
# no   → otherwise (exit 1)

if hcn -q app.example.com; then
  echo already running
else
  sudo hcn -a app.example.com -p 3000 -g -y
fi
```

## Cookie gate (`-g`)

| | |
|--|--|
| Allow | Cookie `hc_gate=<secret>` **or** query `?hc_gate=<secret>` (sets cookie) |
| Deny | HTTP **403** |
| Bypass | `/.well-known/acme-challenge/` (Let's Encrypt) |

Secret file: `/etc/hcn/<host>.env` (mode `600`). Unlock URL is printed after `-a -g`.

```bash
sudo hcn -a app.example.com -p 3000 -G    # disable gate on update
```

## Cloudflare

Use SSL/TLS **Full** or **Full (strict)** — not **Flexible** (Flexible + origin HTTPS redirects causes redirect loops). DNS may be orange-cloud proxied.

## Options

| Flag | Meaning |
|------|---------|
| `-a HOST` | Add / update |
| `-d HOST` | Delete |
| `-l` | List managed hosts |
| `-s HOST` | Show config |
| `-r HOST` | Renew SSL |
| `-q HOST` | Check if configured & running (`yes`/`no`) |
| `-p PORT` | Backend port (proxy mode) |
| `-b ADDR` | Backend address (default `127.0.0.1`) |
| `-S` | Static mode — `root` directory, no reverse proxy |
| `-R DIR` | Root directory for `-S` (default `/var/www/html`) |
| `-e EMAIL` | Certbot email |
| `-g` / `-G` | Gate on / off |
| `-k SECRET` | Gate secret |
| `-c NAME` | Cookie name |
| `-C DOMAIN` | Cookie domain (default: parent of host) |
| `-n` | Dry-run |
| `-w` | No WebSocket upgrade headers |
| `-y` | Non-interactive |

## Why not `-p 80`?

`hcn` is a reverse proxy by default. Pointing it at Nginx itself:

```bash
# WRONG — ERR_TOO_MANY_REDIRECTS
sudo hcn -a site.example.com -p 80 -b 0.0.0.0 -g
```

…proxies HTTPS → HTTP `:80` → HTTPS redirect → loop.

For a plain Nginx/static site (default web root, landing page, etc.):

```bash
sudo hcn -a site.example.com -S -g -k pass123 -c p -y
# optional custom root:
sudo hcn -a site.example.com -S -R /var/www/site -g -y
```

`hcn` also **refuses** proxy targets like `127.0.0.1:80` / `0.0.0.0:80` and tells you to use `-S`.

## Layout

| Path | Purpose |
|------|---------|
| `/usr/local/bin/hcn` | Installed command |
| `/etc/hcn/config` | Default certbot email (falls back to `/etc/hc/config`) |
| `/etc/hcn/<host>.env` | Per-host gate secrets |
| `/etc/nginx/sites-available/<host>.conf` | HTTP (`:80`) + HTTPS (`:443`) server blocks |
| `/etc/nginx/sites-enabled/<host>.conf` | Symlink enabling the site |
| `/etc/nginx/conf.d/hcn-common.conf` | Shared WebSocket `map` |
| `/etc/nginx/conf.d/hcn-gate-<host>.conf` | HTTP-level `map` rules for the host's gate |
| `/etc/nginx/snippets/hcn-gate-<host>.conf` | Gate check + `Set-Cookie` snippet (included in `location /` only) |
| `/etc/nginx/snippets/hcn-ssl-params.conf` | Fallback TLS params (used if certbot's `options-ssl-nginx.conf` is absent) |

Site configs are tagged `# Managed-by: hcn` so `-d` / `-l` only touch sites this tool owns (unless you confirm).

## Requirements

- Debian/Ubuntu-style Nginx (`sites-available` / `sites-enabled` / `conf.d` / `snippets`)
- `certbot` + `python3-certbot-nginx` (auto-installed if missing)
- DNS for `HOST` pointing at the server
- Proxy mode: backend process listening on the given port (or start it after)
- Static mode: root directory (created on request if missing)

## License

Use freely with the rest of this repository.
