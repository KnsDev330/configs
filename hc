#!/usr/bin/env bash
# hc — Apache reverse-proxy / static vhost + Let's Encrypt helper (idempotent)
#
# Install (once, as root):
#   sudo ./hc install          # → /usr/local/bin/hc
#   sudo hc -e you@domain.tld  # optional: save default certbot email
#
# Usage (any user with sudo):
#   sudo hc -a app.example.com -p 3000
#   sudo hc -a app.example.com -p 3000 -g
#   sudo hc -a site.example.com -S -g          # DocumentRoot (no proxy)
#   sudo hc -a site.example.com -S -R /var/www/html -g
#   sudo hc -d app.example.com
#   sudo hc -l
#   sudo hc -s app.example.com
#   sudo hc -r app.example.com
#   sudo hc update             # refresh installed binary (GitHub or local)
#   sudo hc uninstall
#   hc version
#
# Cookie gate (-g): cookie or ?cookie=secret unlocks; else 403.
# ACME HTTP-01 bypasses the gate. Safe behind Cloudflare Full (strict).
#
set -euo pipefail

HC_VERSION="1.2.1"
HC_INSTALL_PATH="${HC_INSTALL_PATH:-/usr/local/bin/hc}"
HC_UPDATE_URL="${HC_UPDATE_URL:-https://raw.githubusercontent.com/KnsDev330/configs/main/hc}"
HC_SELF="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"

SITES_AVAILABLE="/etc/apache2/sites-available"
SITES_ENABLED="/etc/apache2/sites-enabled"
HC_STATE_DIR="/etc/hc"
HC_CONFIG="${HC_STATE_DIR}/config"

BACKEND_DEFAULT="127.0.0.1"
DOCROOT_DEFAULT="/var/www/html"
CERTBOT_EMAIL="${CERTBOT_EMAIL:-}"
BACKEND="${BACKEND_DEFAULT}"
DOCROOT=""

ACTION=""
HOSTNAME=""
PORT=""
DRY_RUN=0
NO_WS=0
NO_PROMPT=0
GATE_MODE="preserve"   # preserve | on | off
GATE_SECRET="${GATE_SECRET:-}"
COOKIE_NAME=""
COOKIE_DOMAIN=""
GATE_ENABLED=0
SITE_MODE=""           # "" | proxy | static  ("" = infer / preserve)

log()  { printf '\n\033[1;32m==>\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<EOF
hc ${HC_VERSION} — idempotent Apache reverse-proxy / static vhost + Let's Encrypt

Install:
  sudo ./hc install              install to ${HC_INSTALL_PATH}
  sudo hc update                 update installed hc (from GitHub)
  sudo ./hc update               update from this local file
  sudo hc update --remote        force download from GitHub
  sudo hc update --local         force install from this file
  sudo hc uninstall              remove ${HC_INSTALL_PATH} (keeps /etc/hc)
  sudo hc uninstall --purge      also remove /etc/hc state
  hc version

Manage hosts:
  sudo hc -a HOST [-p PORT] [-b ADDR] [-e EMAIL] [-g] [-k SECRET] …
  sudo hc -a HOST -S [-R DIR] [-e EMAIL] [-g] [-k SECRET] …
  sudo hc -d HOST
  sudo hc -l
  sudo hc -s HOST
  sudo hc -r HOST
  hc -q HOST                 print yes/no (exit 0/1) if site is configured & running

Options:
  -a HOST     Add or update vhost (+ SSL)
  -d HOST     Delete HTTP/HTTPS vhosts for HOST
  -l          List hc-managed vhosts
  -s HOST     Show Apache config, gate, backend/docroot, cert
  -r HOST     Force-renew / reinstall SSL for HOST
  -q HOST     Check: print "yes" if vhost exists, enabled, and ready; else "no"
  -p PORT     Backend port (proxy mode; prompted if omitted on -a)
  -b ADDR     Backend address (default: ${BACKEND_DEFAULT})
  -S          Static mode: serve DocumentRoot (no reverse proxy)
  -R DIR      DocumentRoot for -S (default: ${DOCROOT_DEFAULT})
  -e EMAIL    Certbot contact email (saved to ${HC_CONFIG})
  -g          Enable cookie gate
  -G          Disable cookie gate
  -k SECRET   Gate secret (default: reuse saved or generate)
  -c NAME     Gate cookie name (default: hc_gate)
  -C DOMAIN   Cookie Domain attribute (default: parent of HOST)
  -n          Dry-run
  -w          Disable WebSocket proxy rules (proxy mode only)
  -y          Non-interactive (no prompts)
  -h          Help

Examples:
  sudo hc -a api.example.com -p 8080 -e admin@example.com
  sudo hc -a app.example.com -p 3000 -g
  sudo hc -a badsha.example.com -S -g -k pass123 -c p
  sudo hc -a docs.example.com -S -R /var/www/docs -g
  hc -q app.example.com && echo already up
  sudo hc -d app.example.com

Notes:
  • Idempotent: re-run -a to change port/gate/SSL/mode safely
  • Do NOT proxy to Apache itself (-p 80/-p 443 on localhost) — use -S instead
  • Cloudflare: SSL/TLS mode Full or Full (strict), not Flexible
  • Gate secrets: ${HC_STATE_DIR}/<host>.env (mode 600)
EOF
}

need_root() {
  [[ ${EUID} -eq 0 ]] || die "root required — try: sudo hc ${*:-…}"
}

load_config() {
  mkdir -p "${HC_STATE_DIR}" 2>/dev/null || true
  if [[ -f "${HC_CONFIG}" ]]; then
    # shellcheck disable=SC1090
    set -a
    # shellcheck source=/dev/null
    source "${HC_CONFIG}"
    set +a
  fi
  CERTBOT_EMAIL="${CERTBOT_EMAIL:-}"
}

save_config_email() {
  local email="$1"
  [[ -n "${email}" ]] || return 0
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "(dry-run) would save CERTBOT_EMAIL to ${HC_CONFIG}"
    return 0
  fi
  mkdir -p "${HC_STATE_DIR}"
  if [[ -f "${HC_CONFIG}" ]] && grep -q '^CERTBOT_EMAIL=' "${HC_CONFIG}"; then
    sed -i "s/^CERTBOT_EMAIL=.*/CERTBOT_EMAIL=${email}/" "${HC_CONFIG}"
  else
    printf 'CERTBOT_EMAIL=%s\n' "${email}" >> "${HC_CONFIG}"
  fi
  chmod 600 "${HC_CONFIG}"
}

require_email() {
  if [[ -n "${CERTBOT_EMAIL}" ]]; then
    save_config_email "${CERTBOT_EMAIL}"
    return 0
  fi
  if [[ "${NO_PROMPT}" -eq 1 ]]; then
    die "Certbot email required: -e you@example.com (or set CERTBOT_EMAIL / ${HC_CONFIG})"
  fi
  local answer=""
  read -r -p "Certbot email: " answer
  CERTBOT_EMAIL="${answer}"
  [[ -n "${CERTBOT_EMAIL}" ]] || die "email required"
  save_config_email "${CERTBOT_EMAIL}"
}

valid_hostname() {
  [[ "$1" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$ ]]
}

valid_port() {
  [[ "$1" =~ ^[0-9]+$ ]] && (( "$1" >= 1 && "$1" <= 65535 ))
}

site_http()     { echo "${SITES_AVAILABLE}/${1}.conf"; }
site_ssl()      { echo "${SITES_AVAILABLE}/${1}-le-ssl.conf"; }
gate_snippet()  { echo "/etc/apache2/conf-available/hc-gate-${1}.conf"; }
gate_env_file() { echo "${HC_STATE_DIR}/${1}.env"; }

is_managed() {
  local f
  f="$(site_http "$1")"
  [[ -f "${f}" ]] && grep -qE 'Managed-by: (hc|hc\.sh|vhost-proxy\.sh)' "${f}"
}

host_has_gate() {
  local f
  f="$(site_http "$1")"
  [[ -f "${f}" ]] && grep -q '^# Gate: on' "${f}"
}

host_is_static() {
  local f
  f="$(site_http "$1")"
  [[ -f "${f}" ]] && grep -qE '^# Mode:[[:space:]]*static' "${f}"
}

host_docroot() {
  local f
  f="$(site_http "$1")"
  [[ -f "${f}" ]] || return 0
  grep -m1 '^# DocumentRoot:' "${f}" 2>/dev/null | sed 's/^# DocumentRoot:[[:space:]]*//' || true
}

# Proxying to Apache's own :80/:443 on a local catch-all address causes redirect loops.
is_self_proxy_target() {
  local addr="$1" port="$2"
  case "${port}" in
    80|443) ;;
    *) return 1 ;;
  esac
  case "${addr}" in
    0.0.0.0|127.0.0.1|localhost|::|::1|\*|\[::\]) return 0 ;;
    *) return 1 ;;
  esac
}

refuse_self_proxy() {
  if is_self_proxy_target "${BACKEND}" "${PORT}"; then
    die "Refusing proxy to ${BACKEND}:${PORT} (Apache would loop on itself). Use: sudo hc -a ${HOSTNAME} -S … for a DocumentRoot site, or -p <app-port> for a real backend."
  fi
}

ensure_docroot() {
  local dir="$1"
  [[ -n "${dir}" ]] || die "DocumentRoot required"
  [[ "${dir}" == /* ]] || die "DocumentRoot must be absolute: ${dir}"
  if [[ ! -d "${dir}" ]]; then
    if [[ "${NO_PROMPT}" -eq 1 || "${DRY_RUN}" -eq 1 ]]; then
      log "Creating DocumentRoot ${dir}"
      [[ "${DRY_RUN}" -eq 1 ]] || mkdir -p "${dir}"
    else
      local ans=""
      read -r -p "DocumentRoot ${dir} missing. Create it? [Y/n] " ans
      [[ "${ans}" =~ ^[Nn]$ ]] && die "DocumentRoot missing: ${dir}"
      mkdir -p "${dir}"
    fi
  fi
  [[ "${DRY_RUN}" -eq 1 ]] || chmod 755 "${dir}" 2>/dev/null || true
}

derive_cookie_domain() {
  local host="$1"
  local rest="${host#*.}"
  if [[ "${rest}" == "${host}" || "${rest}" != *.* ]]; then
    echo ".${host}"
  else
    echo ".${rest}"
  fi
}

ensure_apache_bits() {
  export DEBIAN_FRONTEND=noninteractive
  if ! command -v apache2ctl >/dev/null 2>&1; then
    log "Installing apache2"
    apt-get update -qq
    apt-get install -y -qq apache2
  fi
  if ! command -v certbot >/dev/null 2>&1; then
    log "Installing certbot"
    apt-get update -qq
    apt-get install -y -qq certbot python3-certbot-apache
  fi
  local m
  for m in ssl rewrite headers proxy proxy_http proxy_wstunnel; do
    a2enmod -q "${m}" 2>/dev/null || a2enmod "${m}"
  done
}

prompt_port() {
  if [[ -n "${PORT}" ]]; then
    valid_port "${PORT}" || die "Invalid port: ${PORT}"
    return 0
  fi
  if [[ "${NO_PROMPT}" -eq 1 ]]; then
    die "Port required: -p PORT (or use -S for static DocumentRoot)"
  fi
  local answer=""
  read -r -p "Backend port for ${HOSTNAME} (on ${BACKEND}): " answer
  PORT="${answer}"
  valid_port "${PORT}" || die "Invalid port: ${PORT}"
}

resolve_site_mode() {
  local host="$1"
  if [[ "${SITE_MODE}" == "static" || "${SITE_MODE}" == "proxy" ]]; then
    return 0
  fi
  if host_is_static "${host}"; then
    SITE_MODE="static"
  else
    SITE_MODE="proxy"
  fi
}

resolve_docroot() {
  local host="$1"
  if [[ -n "${DOCROOT}" ]]; then
    return 0
  fi
  local existing=""
  existing="$(host_docroot "${host}")"
  if [[ -n "${existing}" ]]; then
    DOCROOT="${existing}"
  else
    DOCROOT="${DOCROOT_DEFAULT}"
  fi
}

resolve_gate() {
  local host="$1"
  local envf
  envf="$(gate_env_file "${host}")"
  GATE_ENABLED=0

  local cli_secret="${GATE_SECRET}"
  local cli_cookie="${COOKIE_NAME}"
  local cli_domain="${COOKIE_DOMAIN}"

  case "${GATE_MODE}" in
    off) GATE_ENABLED=0; return 0 ;;
    on)  GATE_ENABLED=1 ;;
    preserve)
      if host_has_gate "${host}" || [[ -f "${envf}" ]]; then
        GATE_ENABLED=1
      else
        GATE_ENABLED=0
        return 0
      fi
      ;;
  esac

  if [[ -f "${envf}" ]]; then
    # shellcheck disable=SC1090
    set -a
    # shellcheck source=/dev/null
    source "${envf}"
    set +a
  fi

  [[ -n "${cli_secret}" ]] && GATE_SECRET="${cli_secret}"
  [[ -n "${cli_cookie}" ]] && COOKIE_NAME="${cli_cookie}"
  [[ -n "${cli_domain}" ]] && COOKIE_DOMAIN="${cli_domain}"

  COOKIE_NAME="${COOKIE_NAME:-hc_gate}"
  COOKIE_DOMAIN="${COOKIE_DOMAIN:-$(derive_cookie_domain "${host}")}"
  if [[ -z "${GATE_SECRET}" ]]; then
    GATE_SECRET="$(openssl rand -hex 16)"
    log "Generated new GATE_SECRET for ${host}"
  fi

  [[ "${GATE_SECRET}" =~ ^[A-Za-z0-9_-]+$ ]] || die "GATE_SECRET must be [A-Za-z0-9_-]+"
  [[ "${COOKIE_NAME}" =~ ^[A-Za-z0-9_]+$ ]] || die "Invalid cookie name: ${COOKIE_NAME}"
}

save_gate_env() {
  local host="$1"
  local envf
  envf="$(gate_env_file "${host}")"
  [[ "${DRY_RUN}" -eq 1 ]] && { echo "(dry-run) save ${envf}"; return 0; }
  mkdir -p "${HC_STATE_DIR}"
  cat > "${envf}" <<EOF
# Managed by hc — keep private
GATE_SECRET=${GATE_SECRET}
COOKIE_NAME=${COOKIE_NAME}
COOKIE_DOMAIN=${COOKIE_DOMAIN}
EOF
  chmod 600 "${envf}"
}

write_gate_snippet() {
  local host="$1"
  local path
  path="$(gate_snippet "${host}")"

  if [[ "${GATE_ENABLED}" -ne 1 ]]; then
    if [[ -f "${path}" ]]; then
      log "Removing gate snippet ${path}"
      [[ "${DRY_RUN}" -eq 1 ]] || rm -f "${path}"
    fi
    if [[ -L "/etc/apache2/conf-enabled/hc-gate-${host}.conf" ]]; then
      a2disconf -q "hc-gate-${host}" 2>/dev/null || true
    fi
    return 0
  fi

  log "Writing gate snippet ${path}"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "(dry-run) gate cookie=${COOKIE_NAME} domain=${COOKIE_DOMAIN}"
    return 0
  fi

  cat > "${path}" <<EOF
# Managed-by: hc — Include from ${host} VirtualHosts only (do not a2enconf)
# Allow: cookie ${COOKIE_NAME}=SECRET or ?${COOKIE_NAME}=SECRET; else 403

<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteRule ^/\.well-known/acme-challenge/ - [L]
  RewriteCond %{HTTP_COOKIE} (?:^|;\s*)${COOKIE_NAME}=${GATE_SECRET}(?:;|$) [NC]
  RewriteRule ^ - [S=2]
  RewriteCond %{QUERY_STRING} (?:^|&)${COOKIE_NAME}=${GATE_SECRET}(?:&|$) [NC]
  RewriteRule ^ - [CO=${COOKIE_NAME}:${GATE_SECRET}:${COOKIE_DOMAIN}:10080:/:Secure:HttpOnly:SameSite=Lax,S=1]
  RewriteRule ^ - [F,L]
</IfModule>
EOF
  chmod 640 "${path}"

  if [[ -L "/etc/apache2/conf-enabled/hc-gate-${host}.conf" ]]; then
    a2disconf -q "hc-gate-${host}" 2>/dev/null || a2disconf "hc-gate-${host}" || true
  fi
  save_gate_env "${host}"
}

gate_include_block() {
  local host="$1"
  if [[ "${GATE_ENABLED}" -eq 1 ]]; then
    echo "    Include conf-available/hc-gate-${host}.conf"
  fi
}

gate_meta_comments() {
  local host="$1"
  if [[ "${GATE_ENABLED}" -eq 1 ]]; then
    cat <<EOF
# Gate: on
# Gate-cookie: ${COOKIE_NAME}
# Gate-domain: ${COOKIE_DOMAIN}
# Gate-secret-file: $(gate_env_file "${host}")
EOF
  else
    echo "# Gate: off"
  fi
}

cloudflare_safe_https_block() {
  cat <<'EOF'
    # Skip redirect when Cloudflare already terminated TLS (X-Forwarded-Proto)
    RewriteEngine On
    RewriteCond %{REQUEST_URI} !^/\.well-known/acme-challenge/
    RewriteCond %{HTTP:X-Forwarded-Proto} !https [NC]
    RewriteCond %{HTTPS} !=on
    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301,QSA]
EOF
}

ws_block() {
  local port="$1"
  [[ "${NO_WS}" -eq 1 ]] && return 0
  cat <<EOF
    RewriteEngine On
    RewriteCond %{HTTP:Upgrade} =websocket [NC]
    RewriteRule /(.*) ws://${BACKEND}:${port}/\$1 [P,L]
EOF
}

docroot_block() {
  local dir="$1"
  cat <<EOF
    DocumentRoot ${dir}
    <Directory ${dir}>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
EOF
}

site_meta_comments() {
  local host="$1"
  if [[ "${SITE_MODE}" == "static" ]]; then
    cat <<EOF
# Mode: static
# DocumentRoot: ${DOCROOT}
EOF
  else
    cat <<EOF
# Mode: proxy
# Backend: ${BACKEND}:${PORT}
EOF
  fi
  gate_meta_comments "${host}"
}

write_http_vhost() {
  local host="$1"
  local conf
  conf="$(site_http "${host}")"
  log "Writing ${conf}"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    if [[ "${SITE_MODE}" == "static" ]]; then
      echo "(dry-run) HTTP ${host} → DocumentRoot ${DOCROOT}"
    else
      echo "(dry-run) HTTP ${host} → ${BACKEND}:${PORT}"
    fi
    return 0
  fi

  if [[ "${SITE_MODE}" == "static" ]]; then
    cat > "${conf}" <<EOF
# Managed-by: hc
$(site_meta_comments "${host}")
# Updated: $(date -u +%Y-%m-%dT%H:%M:%SZ)

<VirtualHost *:80>
    ServerName ${host}
$(cloudflare_safe_https_block)
$(gate_include_block "${host}")
$(docroot_block "${DOCROOT}")
    ErrorLog \${APACHE_LOG_DIR}/${host}-error.log
    CustomLog \${APACHE_LOG_DIR}/${host}-access.log combined
</VirtualHost>
EOF
  else
    cat > "${conf}" <<EOF
# Managed-by: hc
$(site_meta_comments "${host}")
# Updated: $(date -u +%Y-%m-%dT%H:%M:%SZ)

<VirtualHost *:80>
    ServerName ${host}
$(cloudflare_safe_https_block)
$(gate_include_block "${host}")
    ProxyPreserveHost On
    ProxyRequests Off
    RequestHeader set X-Forwarded-Proto "http" early
$(ws_block "${PORT}")
    ProxyPass / http://${BACKEND}:${PORT}/
    ProxyPassReverse / http://${BACKEND}:${PORT}/
    ErrorLog \${APACHE_LOG_DIR}/${host}-error.log
    CustomLog \${APACHE_LOG_DIR}/${host}-access.log combined
</VirtualHost>
EOF
  fi
  a2ensite -q "${host}.conf" 2>/dev/null || a2ensite "${host}.conf"
}

write_ssl_vhost() {
  local host="$1" cert_name="$2"
  local conf live
  conf="$(site_ssl "${host}")"
  live="/etc/letsencrypt/live/${cert_name}"
  [[ -f "${live}/fullchain.pem" ]] || die "Cert missing: ${live}/fullchain.pem"
  log "Writing ${conf}"
  [[ "${DRY_RUN}" -eq 1 ]] && { echo "(dry-run) SSL ${host}"; return 0; }

  if [[ "${SITE_MODE}" == "static" ]]; then
    cat > "${conf}" <<EOF
# Managed-by: hc
$(site_meta_comments "${host}")
# Cert: ${cert_name}
# Updated: $(date -u +%Y-%m-%dT%H:%M:%SZ)

<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName ${host}
$(gate_include_block "${host}")
$(docroot_block "${DOCROOT}")
    SSLEngine on
    SSLCertificateFile ${live}/fullchain.pem
    SSLCertificateKeyFile ${live}/privkey.pem
    Include /etc/letsencrypt/options-ssl-apache.conf
    ErrorLog \${APACHE_LOG_DIR}/${host}-ssl-error.log
    CustomLog \${APACHE_LOG_DIR}/${host}-ssl-access.log combined
</VirtualHost>
</IfModule>
EOF
  else
    cat > "${conf}" <<EOF
# Managed-by: hc
$(site_meta_comments "${host}")
# Cert: ${cert_name}
# Updated: $(date -u +%Y-%m-%dT%H:%M:%SZ)

<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName ${host}
$(gate_include_block "${host}")
    ProxyPreserveHost On
    ProxyRequests Off
    RequestHeader set X-Forwarded-Proto "https" early
$(ws_block "${PORT}")
    ProxyPass / http://${BACKEND}:${PORT}/
    ProxyPassReverse / http://${BACKEND}:${PORT}/
    SSLEngine on
    SSLCertificateFile ${live}/fullchain.pem
    SSLCertificateKeyFile ${live}/privkey.pem
    Include /etc/letsencrypt/options-ssl-apache.conf
    ErrorLog \${APACHE_LOG_DIR}/${host}-ssl-error.log
    CustomLog \${APACHE_LOG_DIR}/${host}-ssl-access.log combined
</VirtualHost>
</IfModule>
EOF
  fi
  a2ensite -q "${host}-le-ssl.conf" 2>/dev/null || a2ensite "${host}-le-ssl.conf"
}

resolve_or_issue_cert() {
  local host="$1"
  local live="/etc/letsencrypt/live/${host}"

  if [[ -f "${live}/fullchain.pem" ]]; then
    log "Cert already present: ${live}"
    if [[ "${DRY_RUN}" -eq 0 ]]; then
      certbot certonly --apache \
        --non-interactive --agree-tos \
        --email "${CERTBOT_EMAIL}" \
        --no-redirect \
        --keep-until-expiring \
        --cert-name "${host}" \
        -d "${host}" \
        >&2 \
        || warn "certbot keep-until-expiring reported an issue (continuing)"
    fi
    printf '%s\n' "${host}"
    return 0
  fi

  log "Issuing Let's Encrypt certificate for ${host}"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "(dry-run) certbot certonly -d ${host}" >&2
    printf '%s\n' "${host}"
    return 0
  fi

  certbot certonly --apache \
    --non-interactive --agree-tos \
    --email "${CERTBOT_EMAIL}" \
    --no-redirect \
    --keep-until-expiring \
    --cert-name "${host}" \
    -d "${host}" \
    >&2 \
    || die "certbot failed for ${host} — check DNS, port 80, and Cloudflare SSL mode"

  printf '%s\n' "${host}"
}

reload_apache() {
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "(dry-run) apache2ctl configtest && reload"
    return 0
  fi
  apache2ctl configtest
  systemctl reload apache2
}

backend_listening() {
  local port="$1"
  ss -tln | awk -v p=":${port}" '$4 ~ p"$" { found=1 } END { exit !found }'
}

load_site_from_vhost() {
  local http backend_line
  http="$(site_http "${HOSTNAME}")"
  [[ -f "${http}" ]] || die "Missing ${http}"

  if host_is_static "${HOSTNAME}"; then
    SITE_MODE="static"
    DOCROOT="$(host_docroot "${HOSTNAME}")"
    DOCROOT="${DOCROOT:-${DOCROOT_DEFAULT}}"
    return 0
  fi

  SITE_MODE="proxy"
  backend_line="$(grep -m1 '^# Backend:' "${http}" || true)"
  # Legacy vhosts may omit "# Mode: proxy"
  if [[ -z "${backend_line}" ]]; then
    die "Could not read Backend/DocumentRoot from ${http}"
  fi
  PORT="$(echo "${backend_line}" | sed -E 's/.*:([0-9]+)$/\1/')"
  BACKEND="$(echo "${backend_line}" | sed -E 's/^# Backend:[[:space:]]*([^:]+):.*/\1/')"
  [[ -n "${PORT}" ]] || die "Could not read backend from ${http}"
  BACKEND="${BACKEND:-127.0.0.1}"
}

is_same_path() {
  local a="$1" b="$2"
  [[ -e "${a}" && -e "${b}" ]] || return 1
  [[ "${a}" -ef "${b}" ]] 2>/dev/null && return 0
  [[ "$(readlink -f "${a}" 2>/dev/null || true)" == "$(readlink -f "${b}" 2>/dev/null || true)" ]]
}

installed_version() {
  if [[ -x "${HC_INSTALL_PATH}" ]]; then
    "${HC_INSTALL_PATH}" version 2>/dev/null | awk '/^hc /{print $2; exit}'
  fi
}

parse_version_file() {
  local file="$1"
  sed -n 's/^HC_VERSION="\([^"]*\)".*/\1/p' "${file}" | head -1
}

cmd_install() {
  need_root "install"
  if is_same_path "${HC_SELF}" "${HC_INSTALL_PATH}"; then
    log "Already installed at ${HC_INSTALL_PATH} (v${HC_VERSION})"
    echo "  Tip: sudo hc update   # pull latest from GitHub"
    return 0
  fi
  install -d -m 755 "$(dirname "${HC_INSTALL_PATH}")"
  install -m 755 "${HC_SELF}" "${HC_INSTALL_PATH}"
  mkdir -p "${HC_STATE_DIR}"
  chmod 755 "${HC_STATE_DIR}"
  log "Installed hc ${HC_VERSION} → ${HC_INSTALL_PATH}"
  echo
  echo "  sudo hc -e you@example.com -a app.example.com -p 3000"
  echo "  sudo hc -a site.example.com -S -g"
  echo "  sudo hc update"
  echo "  sudo hc -l"
  command -v hc >/dev/null 2>&1 || warn "${HC_INSTALL_PATH} may not be on PATH for this shell — open a new shell or use full path"
}

# Replace ${HC_INSTALL_PATH} with a newer hc.
#   sudo hc update            → download from GitHub (when run from installed path)
#   sudo ./hc update          → install this local file (when run from a checkout)
#   sudo hc update --remote   → always GitHub
#   sudo hc update --local    → always this file (HC_SELF)
cmd_update() {
  local mode="" arg="${1:-}"
  case "${arg}" in
    "" ) mode="" ;;
    --remote|remote) mode="remote" ;;
    --local|local) mode="local" ;;
    -h|--help|help)
      echo "usage: sudo hc update [--remote|--local]"
      echo "  --remote  download ${HC_UPDATE_URL}"
      echo "  --local   install from ${HC_SELF}"
      return 0
      ;;
    *) die "usage: sudo hc update [--remote|--local]" ;;
  esac
  need_root "update"

  if [[ -z "${mode}" ]]; then
    if is_same_path "${HC_SELF}" "${HC_INSTALL_PATH}"; then
      mode="remote"
    else
      mode="local"
    fi
  fi

  local old_ver tmp new_ver
  old_ver="$(installed_version || true)"
  old_ver="${old_ver:-none}"
  tmp="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '${tmp}'" RETURN

  if [[ "${mode}" == "local" ]]; then
    log "Updating ${HC_INSTALL_PATH} from local ${HC_SELF}"
    [[ -f "${HC_SELF}" ]] || die "local source missing: ${HC_SELF}"
    if is_same_path "${HC_SELF}" "${HC_INSTALL_PATH}"; then
      die "already running the installed binary — use: sudo hc update --remote"
    fi
    cp -f "${HC_SELF}" "${tmp}"
  else
    log "Updating ${HC_INSTALL_PATH} from ${HC_UPDATE_URL}"
    command -v curl >/dev/null 2>&1 || die "curl required for remote update"
    curl -fsSL "${HC_UPDATE_URL}" -o "${tmp}" \
      || die "download failed — check network / ${HC_UPDATE_URL}"
  fi

  head -1 "${tmp}" | grep -qE '^#!' || die "update source is not a script"
  grep -q '^HC_VERSION=' "${tmp}" || die "update source does not look like hc"
  new_ver="$(parse_version_file "${tmp}")"
  [[ -n "${new_ver}" ]] || die "could not parse HC_VERSION from update source"

  # Quick syntax check before replacing the live binary
  bash -n "${tmp}" || die "update source failed bash -n"

  install -d -m 755 "$(dirname "${HC_INSTALL_PATH}")"
  install -m 755 "${tmp}" "${HC_INSTALL_PATH}"
  mkdir -p "${HC_STATE_DIR}"
  chmod 755 "${HC_STATE_DIR}"

  log "Updated hc ${old_ver} → ${new_ver} (${mode})"
  "${HC_INSTALL_PATH}" version
}

cmd_uninstall() {
  need_root "uninstall"
  local purge=0
  [[ "${1:-}" == "--purge" ]] && purge=1

  if [[ -e "${HC_INSTALL_PATH}" ]]; then
    rm -f "${HC_INSTALL_PATH}"
    log "Removed ${HC_INSTALL_PATH}"
  else
    warn "Not installed at ${HC_INSTALL_PATH}"
  fi

  if [[ "${purge}" -eq 1 ]]; then
    if [[ -d "${HC_STATE_DIR}" ]]; then
      rm -rf "${HC_STATE_DIR}"
      log "Purged ${HC_STATE_DIR}"
    fi
  else
    echo "  State kept in ${HC_STATE_DIR} (use: sudo hc uninstall --purge)"
  fi
}

cmd_add() {
  need_root "-a"
  valid_hostname "${HOSTNAME}" || die "Invalid hostname: ${HOSTNAME}"
  load_config
  require_email
  resolve_site_mode "${HOSTNAME}"
  ensure_apache_bits
  resolve_gate "${HOSTNAME}"

  if [[ "${SITE_MODE}" == "static" ]]; then
    resolve_docroot "${HOSTNAME}"
    ensure_docroot "${DOCROOT}"
    log "Static site: DocumentRoot ${DOCROOT}"
  else
    prompt_port
    refuse_self_proxy
    if backend_listening "${PORT}"; then
      log "Backend OK: ${BACKEND}:${PORT}"
    else
      warn "Nothing listening on ${BACKEND}:${PORT} yet — creating vhost anyway"
    fi
  fi

  write_gate_snippet "${HOSTNAME}"
  write_http_vhost "${HOSTNAME}"
  reload_apache

  resolve_or_issue_cert "${HOSTNAME}" >/dev/null
  write_ssl_vhost "${HOSTNAME}" "${HOSTNAME}"
  reload_apache

  if [[ "${SITE_MODE}" == "static" ]]; then
    log "https://${HOSTNAME}/ → DocumentRoot ${DOCROOT}"
  else
    log "https://${HOSTNAME}/ → http://${BACKEND}:${PORT}/"
  fi
  if [[ "${GATE_ENABLED}" -eq 1 ]]; then
    echo "  Gate:   on (${COOKIE_NAME} @ ${COOKIE_DOMAIN})"
    echo "  Unlock: https://${HOSTNAME}/?${COOKIE_NAME}=${GATE_SECRET}"
    echo "  Secret: $(gate_env_file "${HOSTNAME}")"
  else
    echo "  Gate:   off"
  fi
  if [[ "${DRY_RUN}" -eq 0 ]]; then
    echo | openssl s_client -connect 127.0.0.1:443 -servername "${HOSTNAME}" 2>/dev/null \
      | openssl x509 -noout -subject -dates 2>/dev/null || true
  fi
}

cmd_delete() {
  need_root "-d"
  valid_hostname "${HOSTNAME}" || die "Invalid hostname: ${HOSTNAME}"

  local http ssl gconf genv
  http="$(site_http "${HOSTNAME}")"
  ssl="$(site_ssl "${HOSTNAME}")"
  gconf="$(gate_snippet "${HOSTNAME}")"
  genv="$(gate_env_file "${HOSTNAME}")"

  if [[ ! -f "${http}" && ! -f "${ssl}" && ! -L "${SITES_ENABLED}/${HOSTNAME}.conf" ]]; then
    warn "No vhost for ${HOSTNAME}"
    return 0
  fi

  if [[ -f "${http}" ]] && ! is_managed "${HOSTNAME}"; then
    if [[ "${NO_PROMPT}" -eq 1 ]]; then
      die "${http} is not managed by hc (refusing -y)"
    fi
    local ans=""
    read -r -p "${HOSTNAME} is not tagged Managed-by hc. Delete anyway? [y/N] " ans
    [[ "${ans}" =~ ^[Yy]$ ]] || die "Aborted"
  fi

  log "Removing ${HOSTNAME}"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "(dry-run) delete sites + gate"
    return 0
  fi

  a2dissite -q "${HOSTNAME}.conf" 2>/dev/null || a2dissite "${HOSTNAME}.conf" 2>/dev/null || true
  a2dissite -q "${HOSTNAME}-le-ssl.conf" 2>/dev/null || a2dissite "${HOSTNAME}-le-ssl.conf" 2>/dev/null || true
  rm -f "${http}" "${ssl}"
  rm -f "${SITES_ENABLED}/${HOSTNAME}.conf" "${SITES_ENABLED}/${HOSTNAME}-le-ssl.conf"
  rm -f "${gconf}" "${genv}"
  reload_apache

  warn "Let's Encrypt files kept. To remove: sudo certbot delete --cert-name ${HOSTNAME}"
  log "Deleted ${HOSTNAME}"
}

cmd_list() {
  need_root "-l"
  printf '%-32s %-28s %-5s %s\n' "HOST" "TARGET" "SSL" "GATE"
  printf '%-32s %-28s %-5s %s\n' "----" "------" "---" "----"
  local f host target ssl gate docroot
  shopt -s nullglob
  for f in "${SITES_AVAILABLE}"/*.conf; do
    [[ "${f}" == *"-le-ssl.conf" ]] && continue
    grep -qE 'Managed-by: (hc|hc\.sh|vhost-proxy\.sh)' "${f}" 2>/dev/null || continue
    host="$(basename "${f}" .conf)"
    if grep -qE '^# Mode:[[:space:]]*static' "${f}"; then
      docroot="$(grep -m1 '^# DocumentRoot:' "${f}" | sed 's/^# DocumentRoot:[[:space:]]*//')"
      target="static:${docroot:-?}"
    else
      target="$(grep -m1 '^# Backend:' "${f}" | sed 's/^# Backend:[[:space:]]*//')"
      target="${target:-?}"
    fi
    if [[ -f "$(site_ssl "${host}")" ]] || [[ -L "${SITES_ENABLED}/${host}-le-ssl.conf" ]]; then
      ssl="yes"
    else
      ssl="no"
    fi
    if grep -q '^# Gate: on' "${f}"; then
      gate="on"
    else
      gate="off"
    fi
    printf '%-32s %-28s %-5s %s\n' "${host}" "${target}" "${ssl}" "${gate}"
  done
}

cmd_show() {
  need_root "-s"
  valid_hostname "${HOSTNAME}" || die "Invalid hostname: ${HOSTNAME}"
  local http ssl genv
  http="$(site_http "${HOSTNAME}")"
  ssl="$(site_ssl "${HOSTNAME}")"
  genv="$(gate_env_file "${HOSTNAME}")"

  echo "=== Apache ==="
  apache2ctl -S 2>/dev/null | grep -E "${HOSTNAME}" || warn "Not in apache2ctl -S"
  echo
  [[ -f "${http}" ]] && { echo "=== ${http} ==="; cat "${http}"; echo; } || warn "Missing ${http}"
  [[ -f "${ssl}" ]] && { echo "=== ${ssl} ==="; cat "${ssl}"; echo; } || warn "Missing ${ssl}"

  if [[ -f "${genv}" ]]; then
    echo "=== Gate ${genv} ==="
    # shellcheck disable=SC1090
    set -a
    # shellcheck source=/dev/null
    source "${genv}"
    set +a
    echo "COOKIE_NAME=${COOKIE_NAME:-}"
    echo "COOKIE_DOMAIN=${COOKIE_DOMAIN:-}"
    if [[ -n "${GATE_SECRET:-}" ]]; then
      echo "GATE_SECRET=${GATE_SECRET:0:4}… (${#GATE_SECRET} chars)"
      echo "Unlock: https://${HOSTNAME}/?${COOKIE_NAME}=<secret>"
      echo "Full:   sudo grep GATE_SECRET ${genv}"
    fi
    echo
  elif host_has_gate "${HOSTNAME}"; then
    warn "Gate on in vhost but missing ${genv}"
  fi

  if host_is_static "${HOSTNAME}"; then
    local docroot
    docroot="$(host_docroot "${HOSTNAME}")"
    docroot="${docroot:-${DOCROOT_DEFAULT}}"
    echo "=== DocumentRoot ${docroot} ==="
    if [[ -d "${docroot}" ]]; then
      echo "present"
    else
      warn "missing ${docroot}"
    fi
    echo
  else
    local port
    port="$(grep -m1 '^# Backend:' "${http}" 2>/dev/null | sed -E 's/.*:([0-9]+)$/\1/' || true)"
    if [[ -n "${port}" ]]; then
      echo "=== Backend :${port} ==="
      backend_listening "${port}" && echo "listening" || warn "nothing listening on :${port}"
      echo
    fi
  fi

  echo "=== Origin cert (SNI ${HOSTNAME}) ==="
  echo | openssl s_client -connect 127.0.0.1:443 -servername "${HOSTNAME}" 2>/dev/null \
    | openssl x509 -noout -subject -issuer -dates 2>/dev/null || warn "no cert presented"
}

cmd_renew_ssl() {
  need_root "-r"
  valid_hostname "${HOSTNAME}" || die "Invalid hostname: ${HOSTNAME}"
  [[ -f "$(site_http "${HOSTNAME}")" ]] || die "No HTTP vhost for ${HOSTNAME} — run -a first"
  load_config
  require_email
  ensure_apache_bits
  load_site_from_vhost
  resolve_gate "${HOSTNAME}"

  resolve_or_issue_cert "${HOSTNAME}" >/dev/null
  if [[ "${DRY_RUN}" -eq 0 ]]; then
    certbot renew --cert-name "${HOSTNAME}" --force-renewal >&2 2>/dev/null \
      || certbot certonly --apache --non-interactive --agree-tos \
           --email "${CERTBOT_EMAIL}" --cert-name "${HOSTNAME}" -d "${HOSTNAME}" \
           --force-renewal >&2 || warn "renew returned non-zero"
  fi
  write_gate_snippet "${HOSTNAME}"
  write_http_vhost "${HOSTNAME}"
  write_ssl_vhost "${HOSTNAME}" "${HOSTNAME}"
  reload_apache
  log "SSL refreshed for ${HOSTNAME}"
}

# Print "yes" or "no" — exit 0 if configured + enabled + backend listening, else 1.
# Safe for scripts:  if hc -q app.example.com; then …; fi
cmd_check() {
  valid_hostname "${HOSTNAME}" || die "Invalid hostname: ${HOSTNAME}"

  local http ssl
  http="$(site_http "${HOSTNAME}")"
  ssl="$(site_ssl "${HOSTNAME}")"

  if [[ ! -f "${http}" ]] || ! is_managed "${HOSTNAME}"; then
    echo "no"
    return 1
  fi

  if [[ ! -L "${SITES_ENABLED}/${HOSTNAME}.conf" && ! -e "${SITES_ENABLED}/${HOSTNAME}.conf" ]]; then
    echo "no"
    return 1
  fi

  # Prefer SSL site enabled when present
  if [[ -f "${ssl}" ]] && [[ ! -L "${SITES_ENABLED}/${HOSTNAME}-le-ssl.conf" && ! -e "${SITES_ENABLED}/${HOSTNAME}-le-ssl.conf" ]]; then
    echo "no"
    return 1
  fi

  if command -v systemctl >/dev/null 2>&1; then
    if ! systemctl is-active --quiet apache2 2>/dev/null && ! systemctl is-active --quiet httpd 2>/dev/null; then
      echo "no"
      return 1
    fi
  fi

  if host_is_static "${HOSTNAME}"; then
    local docroot
    docroot="$(host_docroot "${HOSTNAME}")"
    docroot="${docroot:-${DOCROOT_DEFAULT}}"
    if [[ ! -d "${docroot}" ]]; then
      echo "no"
      return 1
    fi
    echo "yes"
    return 0
  fi

  local backend_line port addr
  backend_line="$(grep -m1 '^# Backend:' "${http}" 2>/dev/null || true)"
  port="$(echo "${backend_line}" | sed -E 's/.*:([0-9]+)$/\1/')"
  addr="$(echo "${backend_line}" | sed -E 's/^# Backend:[[:space:]]*([^:]+):.*/\1/')"
  addr="${addr:-127.0.0.1}"

  if [[ -z "${port}" ]] || ! backend_listening "${port}"; then
    echo "no"
    return 1
  fi

  echo "yes"
  return 0
}

# --- entry: subcommands before getopts ---
case "${1:-}" in
  install)
    shift
    cmd_install
    exit 0
    ;;
  update)
    shift
    cmd_update "${1:-}"
    exit 0
    ;;
  uninstall)
    shift
    cmd_uninstall "${1:-}"
    exit 0
    ;;
  version|--version|-V)
    echo "hc ${HC_VERSION}"
    echo "path: ${HC_SELF}"
    exit 0
    ;;
  help|--help)
    usage
    exit 0
    ;;
esac

while getopts ':a:d:ls:r:q:p:b:e:k:c:C:R:gGnwySh' opt; do
  case "${opt}" in
    a) ACTION="add"; HOSTNAME="${OPTARG}" ;;
    d) ACTION="delete"; HOSTNAME="${OPTARG}" ;;
    l) ACTION="list" ;;
    s) ACTION="show"; HOSTNAME="${OPTARG}" ;;
    r) ACTION="renew"; HOSTNAME="${OPTARG}" ;;
    q) ACTION="check"; HOSTNAME="${OPTARG}" ;;
    p) PORT="${OPTARG}"; [[ -z "${SITE_MODE}" ]] && SITE_MODE="proxy" ;;
    b) BACKEND="${OPTARG}"; [[ -z "${SITE_MODE}" ]] && SITE_MODE="proxy" ;;
    S) SITE_MODE="static" ;;
    R) DOCROOT="${OPTARG}"; [[ -z "${SITE_MODE}" ]] && SITE_MODE="static" ;;
    e) CERTBOT_EMAIL="${OPTARG}" ;;
    g) GATE_MODE="on" ;;
    G) GATE_MODE="off" ;;
    k) GATE_SECRET="${OPTARG}" ;;
    c) COOKIE_NAME="${OPTARG}" ;;
    C) COOKIE_DOMAIN="${OPTARG}" ;;
    n) DRY_RUN=1 ;;
    w) NO_WS=1 ;;
    y) NO_PROMPT=1 ;;
    h) usage; exit 0 ;;
    :) die "Option -${OPTARG} requires an argument" ;;
    \?) die "Unknown option -${OPTARG} (try: hc -h)" ;;
  esac
done
shift $((OPTIND - 1)) || true

if [[ "${ACTION}" == "add" && "${SITE_MODE}" != "static" && -z "${PORT}" && ${#} -ge 1 ]]; then
  PORT="$1"
  [[ -z "${SITE_MODE}" ]] && SITE_MODE="proxy"
fi

if [[ "${SITE_MODE}" == "static" && -n "${PORT}" ]]; then
  warn "-S (static) ignores -p ${PORT}"
fi
if [[ "${SITE_MODE}" == "proxy" && -n "${DOCROOT}" ]]; then
  warn "proxy mode ignores -R ${DOCROOT} (use -S for DocumentRoot)"
fi

[[ -n "${ACTION}" ]] || { usage; exit 1; }

case "${ACTION}" in
  add)    cmd_add ;;
  delete) cmd_delete ;;
  list)   cmd_list ;;
  show)   cmd_show ;;
  renew)  cmd_renew_ssl ;;
  check)
    if cmd_check; then
      exit 0
    fi
    exit 1
    ;;
  *) die "Unknown action" ;;
esac
