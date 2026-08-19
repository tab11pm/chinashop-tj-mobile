#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(realpath "$SCRIPT_DIR/..")"

# Parse arguments
PORT=""
DEVICE_ID=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --port|-p) PORT="$2"; shift 2 ;;
    --device|-d) DEVICE_ID="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

PORT="${PORT:-${PINSHOP_API_PORT:-8080}}"

# Get LAN IP of the default route interface
HOST_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \K[\d.]+' || true)
if [[ -z "$HOST_IP" ]]; then
  echo "Error: No active Wi-Fi/LAN IPv4 address found. Connect this PC to the same Wi-Fi/LAN as the phone." >&2
  exit 1
fi

INTERFACE=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'dev \K\S+' || echo "unknown")
API_URL="http://${HOST_IP}:${PORT}"

echo "Interface: $INTERFACE"
echo "Host IP:   $HOST_IP"
echo "API_URL:   $API_URL"

# Health check (non-fatal)
if curl -sf --max-time 5 "$API_URL/health" -o /dev/null 2>/dev/null; then
  HEALTH=$(curl -sf --max-time 5 "$API_URL/health" 2>/dev/null || true)
  echo "API health: $HEALTH"
else
  echo "Warning: API did not answer at $API_URL/health." >&2
  echo "Check: docker compose is up, firewall allows TCP $PORT, and VPN does not capture the local subnet." >&2
fi

# Build flutter args
FLUTTER_ARGS=(
  run
  "--dart-define=API_URL=$API_URL"
  '--dart-define=ENABLE_DEV_IMAGE_REWRITE=true'
)
if [[ -n "$DEVICE_ID" ]]; then
  FLUTTER_ARGS+=(-d "$DEVICE_ID")
fi

cd "$REPO_ROOT"
echo "Running: flutter ${FLUTTER_ARGS[*]}"
flutter "${FLUTTER_ARGS[@]}"
