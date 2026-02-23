#!/usr/bin/env bash
set -euo pipefail

# Install Docker Engine on Ubuntu/Debian.

usage() {
    echo "Usage: $0 [-h|--help]"
    echo ""
    echo "Installs Docker Engine (if not already installed) using the official"
    echo "Docker apt repository on Ubuntu/Debian systems."
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

if command -v docker &>/dev/null; then
    echo "Docker is already installed ($(docker --version)), skipping installation."
    exit 0
fi

echo "Installing Docker Engine..."

# Install dependencies
apt-get update
apt-get install -y ca-certificates curl gnupg

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg \
    -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the Docker apt repository
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list

# Install Docker packages
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Docker installed successfully ($(docker --version))."
