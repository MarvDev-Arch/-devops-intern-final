#!/usr/bin/env bash
set -euo pipefail

URL="${1:-http://localhost:8080/healthz}"

echo "Checking application health: $URL"

if curl --fail --silent --show-error "$URL"; then
    echo
    echo "SUCCESS: Application is healthy."
else
    echo
    echo "ERROR: Application health check failed."
    exit 1
fi