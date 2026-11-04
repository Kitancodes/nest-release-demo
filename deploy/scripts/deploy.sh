#!/usr/bin/env bash
# Deploy a packaged release to /opt/nest-app/releases/<version> and switch the
# "current" symlink to it. Old releases are kept so we can roll back.
#
#   deploy.sh <version> <path-to-tarball>
#   e.g. deploy.sh v1.0.0 /tmp/nest-app-v1.0.0.tar.gz
set -euo pipefail

VERSION="${1:?usage: deploy.sh <version> <tarball>}"
TARBALL="${2:?usage: deploy.sh <version> <tarball>}"

APP_NAME="nest-app"
APP_BASE="/opt/${APP_NAME}"
RELEASES="${APP_BASE}/releases"
CURRENT="${APP_BASE}/current"
RELEASE_DIR="${RELEASES}/${VERSION}"
KEEP_RELEASES="${KEEP_RELEASES:-5}"
PORT="${PORT:-3000}"

log() { echo "[$(date -u +%FT%TZ)] $*" | tee -a "${APP_BASE}/deploy.log"; }

health_check() {
  for i in $(seq 1 15); do
    if curl -fsS "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1; then return 0; fi
    sleep 2
  done
  return 1
}

PREVIOUS=""
if [ -L "${CURRENT}" ]; then PREVIOUS="$(readlink -f "${CURRENT}")"; fi

# 1. Unpack into its own directory (never overwrite an existing release)
if [ -d "${RELEASE_DIR}" ]; then
  log "Release ${VERSION} already exists - redeploying into ${RELEASE_DIR}.$(date +%s)"
  RELEASE_DIR="${RELEASE_DIR}.$(date +%s)"
fi
log "Unpacking ${TARBALL} -> ${RELEASE_DIR}"
mkdir -p "${RELEASE_DIR}"
tar -xzf "${TARBALL}" -C "${RELEASE_DIR}"
ln -sfn "${APP_BASE}/shared/.env" "${RELEASE_DIR}/.env"

# 2. Atomically switch the symlink (ln to temp name, then mv -T is atomic)
log "Switching current -> ${RELEASE_DIR}"
ln -sfn "${RELEASE_DIR}" "${APP_BASE}/current_tmp"
mv -Tf "${APP_BASE}/current_tmp" "${CURRENT}"

# 3. Restart and verify
sudo systemctl restart "${APP_NAME}"
if health_check; then
  log "Deploy OK: $(curl -s http://127.0.0.1:${PORT}/version)"
else
  log "Health check FAILED for ${VERSION}"
  if [ -n "${PREVIOUS}" ]; then
    log "Auto-rollback to ${PREVIOUS}"
    ln -sfn "${PREVIOUS}" "${APP_BASE}/current_tmp"
    mv -Tf "${APP_BASE}/current_tmp" "${CURRENT}"
    sudo systemctl restart "${APP_NAME}"
  fi
  exit 1
fi

# 4. Prune old releases, never removing the one in use
cd "${RELEASES}"
ACTIVE="$(basename "$(readlink -f "${CURRENT}")")"
ls -1t | { grep -vx "${ACTIVE}" || true; } | tail -n +"${KEEP_RELEASES}" | while read -r old; do
  log "Pruning old release ${old}"
  rm -rf "${RELEASES:?}/${old}"
done

rm -f "${TARBALL}"
log "Releases on server: $(ls -1 "${RELEASES}" | tr '\n' ' ')"
