#!/usr/bin/env bash
# One-time bootstrap of a fresh Ubuntu server (run as a sudo-capable user, e.g. "ubuntu").
#   sudo bash server-setup.sh
set -euo pipefail

APP_NAME="nest-app"
APP_BASE="/opt/${APP_NAME}"
APP_USER="${APP_USER:-ubuntu}"
NODE_MAJOR="${NODE_MAJOR:-20}"

echo ">> Installing Node.js ${NODE_MAJOR}.x"
if ! command -v node >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash -
  apt-get install -y nodejs
fi
node -v

echo ">> Adding 1G swap (protects a 1 GB RAM box)"
if [ ! -f /swapfile ]; then
  fallocate -l 1G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

echo ">> Creating release layout under ${APP_BASE}"
mkdir -p "${APP_BASE}/releases" "${APP_BASE}/shared" "${APP_BASE}/bin"
if [ ! -f "${APP_BASE}/shared/.env" ]; then
  printf 'PORT=3000\nNODE_ENV=production\n' > "${APP_BASE}/shared/.env"
fi
touch "${APP_BASE}/deploy.log"
chown -R "${APP_USER}:${APP_USER}" "${APP_BASE}"

echo ">> Installing systemd unit"
cat > /etc/systemd/system/${APP_NAME}.service <<EOF
[Unit]
Description=Nest.js release demo (served from ${APP_BASE}/current)
After=network.target

[Service]
Type=simple
User=${APP_USER}
WorkingDirectory=${APP_BASE}/current
EnvironmentFile=${APP_BASE}/shared/.env
ExecStart=/usr/bin/node ${APP_BASE}/current/dist/main.js
Restart=on-failure
RestartSec=3
MemoryMax=600M

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ${APP_NAME}

echo ">> Done. Layout:"
ls -la "${APP_BASE}"
