#!/usr/bin/env bash
#
# Fomo London — one-shot VM provisioning (Ubuntu 22.04/24.04, root/sudo).
#
# Brings up the whole stack on a single box, keeping the upstream architecture:
#   MariaDB  +  PHP (api/admin) via php-fpm  +  nginx  +  Python pipeline on cron.
#
# Idempotent: safe to re-run. Designed for Oracle Always-Free ARM or Hetzner.
#
# Usage:
#   git clone <your-fork> /opt/fomo_london && cd /opt/fomo_london
#   sudo DOMAIN=your.temp.domain GEMINI_API_KEY=xxxx bash deploy/setup_vm.sh
#
# After it finishes: browse to http://<server-ip>/ (or your DOMAIN).
set -euo pipefail

# ----------------------------------------------------------------------------
# Config (override via env: DOMAIN=... GEMINI_API_KEY=... bash deploy/setup_vm.sh)
# ----------------------------------------------------------------------------
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
FOMO_CITY="${FOMO_CITY:-london}"
DOMAIN="${DOMAIN:-_}"                       # nginx server_name; "_" = match any host/IP
DB_NAME="${DB_NAME:-fomo}"
DB_APP_USER="${DB_APP_USER:-fomo_app}"      # PHP api/admin connect as this
DB_APP_PASS="${DB_APP_PASS:-$(openssl rand -hex 16)}"
GEMINI_API_KEY="${GEMINI_API_KEY:-}"        # required for the Extract step
GEMINI_MODEL="${GEMINI_MODEL:-gemini-3.1-flash-lite}"
RUN_USER="${SUDO_USER:-$(whoami)}"          # own the repo / run cron as the invoking user
CRON_HOUR="${CRON_HOUR:-4}"                 # daily pipeline run, local server time

echo "==> Fomo London VM setup"
echo "    repo=$REPO_DIR  city=$FOMO_CITY  domain=$DOMAIN  run_user=$RUN_USER"
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo/root."; exit 1; }

# ----------------------------------------------------------------------------
# 1. System packages
# ----------------------------------------------------------------------------
echo "==> [1/8] apt packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y \
  mariadb-server \
  nginx \
  php-fpm php-mysql php-cli php-mbstring php-xml php-curl \
  python3 python3-venv python3-pip \
  nodejs npm \
  git curl openssl ca-certificates

PHP_VER="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
PHP_SOCK="/run/php/php${PHP_VER}-fpm.sock"
echo "    detected PHP ${PHP_VER} (fpm sock: ${PHP_SOCK})"

# ----------------------------------------------------------------------------
# 2. MariaDB: database, users, schema, seed
# ----------------------------------------------------------------------------
echo "==> [2/8] MariaDB database + users"
systemctl enable --now mariadb
# MariaDB binds to 127.0.0.1 only by default, so root@127.0.0.1 is not remotely
# reachable. The pipeline (db.py, FOMO_ENV=local) connects as root over TCP with
# an empty password — we grant exactly that, localhost-only, to avoid a code change.
# PHP connects as a password-protected app user.
#
# --default-character-set=utf8mb4 is REQUIRED on every load: the mariadb client's
# connection charset defaults to utf8mb3 on a stock Ubuntu box, which rejects the
# 4-byte emoji in the seed/config data ("ERROR 1366 Incorrect string value").
mariadb --default-character-set=utf8mb4 <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'root'@'127.0.0.1' IDENTIFIED BY '';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO 'root'@'127.0.0.1';
CREATE USER IF NOT EXISTS '${DB_APP_USER}'@'localhost' IDENTIFIED BY '${DB_APP_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_APP_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL

# Load schema + London seed (schema uses CREATE TABLE IF NOT EXISTS; seed is idempotent)
echo "    loading schema.sql + seed_london_websites.sql"
mariadb --default-character-set=utf8mb4 "${DB_NAME}" < "${REPO_DIR}/database/schema.sql"
mariadb --default-character-set=utf8mb4 "${DB_NAME}" < "${REPO_DIR}/database/seed_london_websites.sql"

# ----------------------------------------------------------------------------
# 3. Python venv + pipeline deps + Playwright browser
# ----------------------------------------------------------------------------
echo "==> [3/8] Python venv + pipeline dependencies"
sudo -u "$RUN_USER" python3 -m venv "${REPO_DIR}/.venv"
sudo -u "$RUN_USER" "${REPO_DIR}/.venv/bin/pip" install --upgrade pip
# No requirements.txt upstream — explicit dep set (see pipeline/*.py imports):
sudo -u "$RUN_USER" "${REPO_DIR}/.venv/bin/pip" install \
  crawl4ai mysql-connector-python python-dotenv httpx pydantic regex pyyaml pillow google-genai
# Playwright: system libs need root; the browser is installed for the run user.
"${REPO_DIR}/.venv/bin/python" -m playwright install-deps chromium
sudo -u "$RUN_USER" "${REPO_DIR}/.venv/bin/python" -m playwright install chromium

# ----------------------------------------------------------------------------
# 4. .env for the pipeline
# ----------------------------------------------------------------------------
echo "==> [4/8] .env"
if [ ! -f "${REPO_DIR}/.env" ]; then
  cat > "${REPO_DIR}/.env" <<ENV
FOMO_CITY="${FOMO_CITY}"
FOMO_ENV="local"
GEMINI_API_KEY="${GEMINI_API_KEY}"
GEMINI_MODEL="${GEMINI_MODEL}"
GEMINI_TIMEOUT=300
ENV
  chown "$RUN_USER":"$RUN_USER" "${REPO_DIR}/.env"
  echo "    wrote .env (edit GEMINI_API_KEY if you left it blank)"
else
  echo "    .env already exists — leaving it untouched"
fi

# ----------------------------------------------------------------------------
# 5. PHP api/admin DB config (gitignored; copied into dist/ by the build)
# ----------------------------------------------------------------------------
echo "==> [5/8] src/api/config.php"
cat > "${REPO_DIR}/src/api/config.php" <<PHP
<?php
// Generated by deploy/setup_vm.sh — single-box deploy, DB on localhost.
define('DB_HOST', 'localhost');
define('DB_NAME', '${DB_NAME}');
define('DB_USER', '${DB_APP_USER}');
define('DB_PASS', '${DB_APP_PASS}');
PHP
chown "$RUN_USER":"$RUN_USER" "${REPO_DIR}/src/api/config.php"

# ----------------------------------------------------------------------------
# 6. Frontend build (esbuild) with London config
# ----------------------------------------------------------------------------
echo "==> [6/8] npm install + build"
cd "${REPO_DIR}"
sudo -u "$RUN_USER" npm install --no-audit --no-fund
sudo -u "$RUN_USER" env FOMO_CITY="${FOMO_CITY}" npm run build

# ----------------------------------------------------------------------------
# 7. nginx
# ----------------------------------------------------------------------------
echo "==> [7/8] nginx site"
cat > /etc/nginx/sites-available/fomo <<NGINX
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN};
    root ${REPO_DIR}/dist;
    index index.html;

    # sw.js must not be long-cached (see .htaccess note in build-system.md)
    location = /sw.js { add_header Cache-Control "no-cache"; }

    location / { try_files \$uri \$uri/ =404; }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }
}
NGINX
ln -sf /etc/nginx/sites-available/fomo /etc/nginx/sites-enabled/fomo
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# ----------------------------------------------------------------------------
# 8. Firewall (Oracle images ship restrictive iptables) + daily cron
# ----------------------------------------------------------------------------
echo "==> [8/8] firewall + cron"
# ufw (Hetzner/generic). Harmless if ufw is inactive.
if command -v ufw >/dev/null; then ufw allow 80/tcp || true; ufw allow 443/tcp || true; fi
# Oracle Ubuntu images DROP inbound by default in iptables — open 80/443 explicitly.
if iptables -L INPUT -n | grep -q "policy DROP\|REJECT"; then
  iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT || true
  iptables -I INPUT 1 -p tcp --dport 443 -j ACCEPT || true
  command -v netfilter-persistent >/dev/null && netfilter-persistent save || \
    (apt-get install -y iptables-persistent && netfilter-persistent save) || true
  echo "    NOTE: also open 80/443 ingress in your cloud console's Security List / firewall."
fi

# Daily pipeline via cron, as the run user.
CRON_LINE="0 ${CRON_HOUR} * * * ${REPO_DIR}/deploy/run_pipeline.sh >> /var/log/fomo-pipeline.log 2>&1"
touch /var/log/fomo-pipeline.log && chown "$RUN_USER":"$RUN_USER" /var/log/fomo-pipeline.log
( sudo -u "$RUN_USER" crontab -l 2>/dev/null | grep -v 'deploy/run_pipeline.sh' ; echo "$CRON_LINE" ) \
  | sudo -u "$RUN_USER" crontab -

echo
echo "==> DONE."
echo "    Site:     http://${DOMAIN} (or the server's public IP)"
echo "    DB app pw: ${DB_APP_PASS}  (also written into src/api/config.php)"
echo "    Pipeline:  runs daily at ${CRON_HOUR}:00; run now with:"
echo "               sudo -u ${RUN_USER} ${REPO_DIR}/deploy/run_pipeline.sh"
[ -z "${GEMINI_API_KEY}" ] && echo "    ⚠  GEMINI_API_KEY is blank in .env — set it before the Extract step will work."
echo "    ⚠  If the page doesn't load, open 80/443 in your cloud provider's console firewall too."
