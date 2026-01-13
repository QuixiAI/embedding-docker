#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./wait-for-tei.sh http://X.X.X.X:8080
# or
#   ./wait-for-tei.sh X.X.X.X:8080

TARGET="${1:-}"
TIMEOUT=300   # 5 minutes in seconds
INTERVAL=1    # seconds

if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 <host:port | url>"
  exit 2
fi

# Normalize input
if [[ "$TARGET" != http* ]]; then
  BASE_URL="http://$TARGET"
else
  BASE_URL="$TARGET"
fi

ENDPOINT="$BASE_URL/health"
START_TIME=$(date +%s)

echo "Waiting for TEI health at $ENDPOINT (timeout: ${TIMEOUT}s)"

while true; do
  NOW=$(date +%s)
  ELAPSED=$((NOW - START_TIME))

  if (( ELAPSED >= TIMEOUT )); then
    echo "❌ Timed out after ${TIMEOUT}s waiting for TEI health"
    exit 1
  fi

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$ENDPOINT" || true)

  if [[ "$HTTP_CODE" == "200" ]]; then
    echo "✅ TEI is healthy (HTTP 200)"
    exit 0
  fi

  echo "⏳ Not ready yet (HTTP $HTTP_CODE) — ${ELAPSED}s elapsed"
  sleep "$INTERVAL"
done

