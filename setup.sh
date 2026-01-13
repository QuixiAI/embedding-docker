#!/bin/bash

set -e

cd "$(dirname "$0")"

echo "Starting embedding service..."
docker compose up -d

echo "Waiting for service to be ready..."

max_attempts=60
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if curl -sf http://localhost:8080/health > /dev/null 2>&1; then
        echo "Service is ready!"
        exit 0
    fi

    attempt=$((attempt + 1))
    printf "."
    sleep 2
done

echo ""
echo "Service failed to become ready after $((max_attempts * 2)) seconds"
docker compose logs --tail=20
exit 1
