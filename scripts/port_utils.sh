#!/usr/bin/env bash
# Port + LAN helpers (source from run_web_lan.sh).

lan_load_config() {
  local root="$1"
  LAN_PREFERRED_WEB=8080
  LAN_PREFERRED_PROXY=8765
  LAN_SCAN_RANGE=30

  local cfg="${root}/config/lan_web.json"
  if [[ -f "$cfg" ]] && command -v python3 >/dev/null 2>&1; then
    eval "$(python3 - <<'PY' "$cfg"
import json, sys
with open(sys.argv[1]) as f:
    c = json.load(f)
print(f"LAN_PREFERRED_WEB={c.get('preferredWebPort', 8080)}")
print(f"LAN_PREFERRED_PROXY={c.get('preferredProxyPort', 8765)}")
print(f"LAN_SCAN_RANGE={c.get('portScanRange', 30)}")
PY
)"
  fi

  local yaml="${root}/web_dev_config.yaml"
  if [[ -f "$yaml" ]]; then
    local yp
    yp="$(grep -E '^[[:space:]]*port:[[:space:]]*[0-9]+' "$yaml" | head -1 | grep -Eo '[0-9]+')"
    [[ -n "$yp" ]] && LAN_PREFERRED_WEB="$yp"
  fi

  [[ -n "${LAN_WEB_PORT:-}" ]] && LAN_PREFERRED_WEB="$LAN_WEB_PORT"
  [[ -n "${LAN_PROXY_PORT:-}" ]] && LAN_PREFERRED_PROXY="$LAN_PROXY_PORT"
  [[ -n "${LAN_PORT_SCAN_RANGE:-}" ]] && LAN_SCAN_RANGE="$LAN_PORT_SCAN_RANGE"
}

lan_port_in_use() {
  local port="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -ltn 2>/dev/null | grep -qE ":${port}([^0-9]|$)"
    return $?
  fi
  if command -v netstat >/dev/null 2>&1; then
    netstat -an 2>/dev/null | grep -qE "[.:]${port}[[:space:]].*LISTEN"
    return $?
  fi
  (echo >/dev/tcp/127.0.0.1/"$port") >/dev/null 2>&1
}

lan_find_free_port() {
  local preferred="$1"
  local range="$2"
  local offset candidate
  for ((offset = 0; offset < range; offset++)); do
    candidate=$((preferred + offset))
    if ! lan_port_in_use "$candidate"; then
      echo "$candidate"
      return 0
    fi
  done
  echo "No free TCP port in range ${preferred}..$((preferred + range - 1))" >&2
  return 1
}

lan_firewall_hint() {
  echo ""
  echo "[Firewall] If the phone cannot connect, allow inbound TCP on the printed port"
  echo "  (ufw / firewalld / Windows Defender Firewall — Private network)."
  echo ""
}

lan_print_banner() {
  local lan_ip="$1"
  local web_port="$2"
  local preferred_web="$3"
  local port_changed="$4"
  local external_proxy="${5:-0}"
  local proxy_port="${6:-0}"
  local web_url="http://${lan_ip}:${web_port}"
  local local_url="http://127.0.0.1:${web_port}"

  echo ""
  echo "========================================"
  echo " Fuel Tracker - Flutter Web (LAN)"
  echo "========================================"
  echo " LAN IP          : ${lan_ip}"
  echo " Bind address    : 0.0.0.0"
  echo -n " Web port        : ${web_port}"
  if [[ "$port_changed" == "1" ]]; then
    echo " (preferred ${preferred_web} was busy)"
  else
    echo ""
  fi
  if [[ "$external_proxy" == "1" ]]; then
    echo " CORS proxy port : ${proxy_port}"
    echo " CORS proxy URL  : http://${lan_ip}:${proxy_port}"
  else
    echo " CORS            : built-in (web_dev_config.yaml)"
  fi
  echo ""
  echo " Local (this PC):"
  echo "   ${local_url}"
  echo ""
  echo " Phone (same Wi-Fi):"
  echo "   ${web_url}"
  echo "========================================"
  echo ""
}
