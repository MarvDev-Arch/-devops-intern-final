#!/usr/bin/env bash
set -euo pipefail

echo "===== SYSTEM INFORMATION ====="

echo "Hostname: $(hostname)"
echo "Operating System:"
uname -a

echo "Current User: $(whoami)"

echo "Current Date: $(date)"

echo "Disk Usage:"
df -h /

echo "Memory Information:"
free -h

echo "Docker Version:"
if docker --version >/dev/null 2>&1; then
    docker --version
else
    echo "Docker CLI is unavailable or not connected in this environment."
fi

echo "===== SYSTEM INFORMATION COMPLETE ====="