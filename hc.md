# hc

Idempotent **Apache** helper with **Let's Encrypt** SSL and an optional cookie gate.

Two site modes:

1. **Proxy** (default) — reverse-proxy to a local Node (or similar) backend  
2. **Static** (`-S`) — serve a `DocumentRoot` directly (no proxy; use this instead of `-p 80`)

Aimed at apps behind Cloudflare.

## Install

```bash
# from this configs repo
sudo ./hc install

# or one-liner (fresh VPS)
curl -fsSL https://raw.githubusercontent.com/KnsDev330/configs/main/hc \
  | sudo tee /usr/local/bin/hc >/dev/null \
  && sudo chmod 755 /usr/local/bin/hc

# anywhere afterwards
sudo hc -h
hc version
```

Installs to `/usr/local/bin/hc` (on the default `sudo` secure path). Any user can run `sudo hc …`.

```bash
sudo hc update              # refresh binary from GitHub (when run as installed hc)
sudo ./hc update            # install this local checkout over /usr/local/bin/hc
sudo hc update --remote     # force GitHub download
sudo hc update --local      # force install from the file you invoked
sudo hc uninstall           # remove binary, keep /etc/hc
sudo hc uninstall --purge   # also delete /etc/hc
```

Override download URL with `HC_UPDATE_URL` if needed.

## Quick start

```bash
# save certbot email once (stored in /etc/hc/config)
sudo hc -e admin@example.com -a app.example.com -p 3000

# with cookie gate
sudo hc -a app.example.com -p 3000 -g

# API sibling
sudo hc -a api.example.com -p 8080 -g

# Static / default DocumentRoot site (NOT -p 80 — that loops)
sudo hc -a badsha.example.com -S -g -k pass123 -c p -y
sudo hc -a docs.example.com -S -R /var/www/docs -g

sudo hc -l
sudo hc -s app.example.com
sudo hc -d app.example.com
```

Re-running `-a` for the same host updates the backend/port/docroot/gate and refreshes certs safely.

## Check site (`-q`)

```bash
hc -q app.example.com
# yes  → vhost exists, enabled, apache up, and ready
#        proxy: backend port listening
#        static: DocumentRoot directory exists
# no   → otherwise (exit 1)

if hc -q app.example.com; then
  echo already running
else
  sudo hc -a app.example.com -p 3000 -g -y
fi
```


| | |
|--|--|
| Allow | Cookie `hc_gate=<secret>` **or** query `?hc_gate=<secret>` (sets cookie) |
| Deny | HTTP **403** |
| Bypass | `/.well-known/acme-challenge/` (Let's Encrypt) |

Secret file: `/etc/hc/<host>.env` (mode `600`). Unlock URL is printed after `-a -g`.

```bash
sudo hc -a app.example.com -p 3000 -G    # disable gate on update
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
| `-p PORT` | Backend port (proxy mode) |
| `-b ADDR` | Backend address (default `127.0.0.1`) |
| `-S` | Static mode — DocumentRoot, no reverse proxy |
| `-R DIR` | DocumentRoot for `-S` (default `/var/www/html`) |
| `-e EMAIL` | Certbot email |
| `-g` / `-G` | Gate on / off |
| `-k SECRET` | Gate secret |
| `-c NAME` | Cookie name |
| `-C DOMAIN` | Cookie domain (default: parent of host) |
| `-n` | Dry-run |
| `-w` | No WebSocket proxy |
| `-y` | Non-interactive |

## Why not `-p 80`?

`hc` is a reverse proxy by default. Pointing it at Apache itself:

```bash
# WRONG — ERR_TOO_MANY_REDIRECTS
sudo hc -a site.example.com -p 80 -b 0.0.0.0 -g
```

…proxies HTTPS → HTTP `:80` → HTTPS redirect → loop.

For a plain Apache/static site (default web root, landing page, etc.):

```bash
sudo hc -a site.example.com -S -g -k pass123 -c p -y
# optional custom root:
sudo hc -a site.example.com -S -R /var/www/site -g -y
```

`hc` also **refuses** proxy targets like `127.0.0.1:80` / `0.0.0.0:80` and tells you to use `-S`.

## Layout

| Path | Purpose |
|------|---------|
| `/usr/local/bin/hc` | Installed command |
| `/etc/hc/config` | Default certbot email |
| `/etc/hc/<host>.env` | Per-host gate secrets |
| `/etc/apache2/sites-available/<host>.conf` | HTTP vhost |
| `/etc/apache2/sites-available/<host>-le-ssl.conf` | HTTPS vhost |
| `/etc/apache2/conf-available/hc-gate-<host>.conf` | Gate snippet (included per vhost only) |

Vhosts are tagged `# Managed-by: hc` so `-d` / `-l` only touch sites this tool owns (unless you confirm).

## Requirements

- Debian/Ubuntu-style Apache 2 (`a2enmod`, `a2ensite`)
- `certbot` + `python3-certbot-apache` (auto-installed if missing)
- DNS for `HOST` pointing at the server
- Proxy mode: backend process listening on the given port (or start it after)
- Static mode: DocumentRoot directory (created on request if missing)

## License

Use freely with the rest of this repository.
