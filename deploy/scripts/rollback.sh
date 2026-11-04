#!/usr/bin/env bash
# Roll back by re-pointing the "current" symlink.
#   rollback.sh            -> previous release (by modification time)
#   rollback.sh v1.0.0     -> a specific release
set -euo pipefail

APP_NAME="nest-app"
APP_BASE="/opt/${APP_NAME}"
RELEASES="${APP_BASE}/releases"
CURRENT="${APP_BASE}/current"
PORT="${PORT:-3000}"

log() { echo "[$(date -u +%FT%TZ)] $*" | tee -a "${APP_BASE}/deploy.log"; }

ACTIVE="$(basename "$(readlink -f "${CURRENT}")")"
TARGET="${1:-}"

if [ -z "${TARGET}" ]; then
  TARGET="$(ls -1t "${RELEASES}" | grep -vx "${ACTIVE}" | head -n 1 || true)"
  [ -n "${TARGET}" ] || { echo "No previous release to roll back to"; exit 1; }
fi

[ -d "${RELEASES}/${TARGET}" ] || {
  echo "Release '${TARGET}' not found. Available:"; ls -1 "${RELEASES}"; exit 1;
}

log "Rolling back ${ACTIVE} -> ${TARGET}"
ln -sfn "${RELEASES}/${TARGET}" "${APP_BASE}/current_tmp"
mv -Tf "${APP_BASE}/current_tmp" "${CURRENT}"
sudo systemctl restart "${APP_NAME}"

for i in $(seq 1 15); do
  if curl -fsS "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1; then
    log "Rollback OK: $(curl -s http://127.0.0.1:${PORT}/version)"
    exit 0
  fi
  sleep 2
done
log "Rollback health check FAILED"; exit 1
