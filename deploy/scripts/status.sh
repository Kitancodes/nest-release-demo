#!/usr/bin/env bash
# Show which version is running and which releases exist on the server.
APP_BASE="/opt/nest-app"
PORT="${PORT:-3000}"
ACTIVE="$(readlink -f "${APP_BASE}/current" 2>/dev/null || echo none)"

echo "Symlink : ${APP_BASE}/current -> ${ACTIVE}"
echo "Service : $(systemctl is-active nest-app)"
echo "Running : $(curl -s http://127.0.0.1:${PORT}/version || echo 'not responding')"
echo "Releases:"
for r in $(ls -1t "${APP_BASE}/releases"); do
  if [ "${APP_BASE}/releases/${r}" = "${ACTIVE}" ]; then echo "  * ${r}   <- current"; else echo "    ${r}"; fi
done
