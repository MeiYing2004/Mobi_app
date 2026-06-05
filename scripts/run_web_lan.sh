#!/usr/bin/env bash
# Single command: Flutter Web on LAN (0.0.0.0) + auto port + phone URL.
set -euo pipefail

EXTERNAL_PROXY="${EXTERNAL_PROXY:-0}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# shellcheck source=port_utils.sh
source "$(dirname "$0")/port_utils.sh"

get_lan_ip() {
  if command -v ipconfig >/dev/null 2>&1; then
    ipconfig 2>/dev/null | grep -Eo 'IPv4[^:]*:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' \
      | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' \
      | grep -vE '^127\.|^169\.254\.' | head -1
    return
  fi
  hostname -I 2>/dev/null | awk '{print $1}'
}

LAN_IP="$(get_lan_ip || true)"
if [[ -z "${LAN_IP:-}" ]]; then
  echo "No LAN IPv4 address found." >&2
  exit 1
fi

lan_load_config "$ROOT"

WEB_PORT="$(lan_find_free_port "$LAN_PREFERRED_WEB" "$LAN_SCAN_RANGE")"
PORT_CHANGED=0
[[ "$WEB_PORT" != "$LAN_PREFERRED_WEB" ]] && PORT_CHANGED=1

PROXY_PORT=0
PROXY_PID=""
if [[ "$EXTERNAL_PROXY" == "1" ]]; then
  PROXY_PORT="$(lan_find_free_port "$LAN_PREFERRED_PROXY" "$LAN_SCAN_RANGE")"
  dart run tool/dev_cors_proxy.dart "$PROXY_PORT" &
  PROXY_PID=$!
  trap 'kill "$PROXY_PID" 2>/dev/null || true' EXIT
  sleep 1
fi

lan_firewall_hint
lan_print_banner "$LAN_IP" "$WEB_PORT" "$LAN_PREFERRED_WEB" "$PORT_CHANGED" "$EXTERNAL_PROXY" "$PROXY_PORT"

WEB_URL="http://${LAN_IP}:${WEB_PORT}"
FLUTTER_ARGS=(
  run -d web-server
  --web-hostname=0.0.0.0
  "--web-port=${WEB_PORT}"
  "--web-launch-url=${WEB_URL}"
  "--dart-define=WEB_LAN_HOST=${LAN_IP}"
  "--dart-define=WEB_LAN_PORT=${WEB_PORT}"
  "--dart-define=WEB_CORS_MODE=builtin"
)

if [[ "$EXTERNAL_PROXY" == "1" ]]; then
  FLUTTER_ARGS+=(
    "--dart-define=OSM_DEV_PROXY=http://${LAN_IP}:${PROXY_PORT}"
    "--dart-define=WEB_CORS_MODE=external"
  )
fi

flutter "${FLUTTER_ARGS[@]}"
