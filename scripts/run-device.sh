#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(realpath "$SCRIPT_DIR/..")"
API_PORT="${PINSHOP_API_PORT:-8080}"

# Find adb
ADB=""
if command -v adb &>/dev/null; then
  ADB="$(command -v adb)"
elif [[ -x "$HOME/Android/Sdk/platform-tools/adb" ]]; then
  ADB="$HOME/Android/Sdk/platform-tools/adb"
fi

USE_ADB_REVERSE=false
if [[ -n "$ADB" && -z "${PINSHOP_USE_LAN:-}" ]]; then
  DEVICES=$("$ADB" devices 2>/dev/null | grep -cP '\tdevice$' || true)
  if [[ "$DEVICES" -gt 0 ]]; then
    "$ADB" reverse "tcp:$API_PORT" "tcp:$API_PORT" &>/dev/null || true
    "$ADB" reverse tcp:9000 tcp:9000 &>/dev/null || true
    USE_ADB_REVERSE=true
  fi
fi

if [[ "$USE_ADB_REVERSE" == true ]]; then
  API_URL="http://127.0.0.1:${API_PORT}"
  echo "Using ADB reverse: device tcp:$API_PORT -> host tcp:$API_PORT"
else
  # Get LAN IP of the default route interface
  HOST_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \K[\d.]+' || true)
  if [[ -z "$HOST_IP" ]]; then
    echo "Error: No active LAN/Wi-Fi IPv4 address found. Connect this PC and phone to the same network." >&2
    exit 1
  fi
  API_URL="http://${HOST_IP}:${API_PORT}"
fi

echo "Using API_URL=$API_URL"

# Health check (non-fatal)
if curl -sf --max-time 5 "$API_URL/health" -o /dev/null 2>/dev/null; then
  HEALTH=$(curl -sf --max-time 5 "$API_URL/health" 2>/dev/null || true)
  echo "API health: $HEALTH"
else
  echo "Warning: API did not answer at $API_URL/health. Check Docker and firewall." >&2
fi

# Run Flutter
FLUTTER_ARGS=(run "--dart-define=API_URL=$API_URL")
if [[ "$USE_ADB_REVERSE" == false ]]; then
  FLUTTER_ARGS+=('--dart-define=ENABLE_DEV_IMAGE_REWRITE=true')
fi

cd "$REPO_ROOT"
flutter "${FLUTTER_ARGS[@]}"
