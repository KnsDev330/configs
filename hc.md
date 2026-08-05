# hc

Idempotent **Apache** reverse-proxy helper with **Let's Encrypt** SSL and an optional cookie gate. Aimed at Node (and similar) apps behind Cloudflare.

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
sudo hc uninstall           # remove binary, keep /etc/hc
sudo hc uninstall --purge   # also delete /etc/hc
```

## Quick start

```bash
# save certbot email once (stored in /etc/hc/config)
sudo hc -e admin@example.com -a app.example.com -p 3000

# with cookie gate
sudo hc -a app.example.com -p 3000 -g

# API sibling
sudo hc -a api.example.com -p 8080 -g

sudo hc -l
sudo hc -s app.example.com
sudo hc -d app.example.com
```

Re-running `-a` for the same host updates the backend/port/gate and refreshes certs safely.

## Cookie gate (`-g`)

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
| `-p PORT` | Backend port |
| `-b ADDR` | Backend address (default `127.0.0.1`) |
| `-e EMAIL` | Certbot email |
| `-g` / `-G` | Gate on / off |
| `-k SECRET` | Gate secret |
| `-c NAME` | Cookie name |
| `-C DOMAIN` | Cookie domain (default: parent of host) |
| `-n` | Dry-run |
| `-w` | No WebSocket proxy |
| `-y` | Non-interactive |

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
- Backend process listening on the given port (or start it after)

## License

Use freely with the rest of this repository.
