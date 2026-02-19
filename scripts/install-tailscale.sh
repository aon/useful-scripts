#!/usr/bin/env bash
set -euo pipefail

# Install Tailscale and start it with SSH enabled.

usage() {
    echo "Usage: $0 [-h|--help]"
    echo ""
    echo "Installs Tailscale (if not already installed) and runs"
    echo "'tailscale up --ssh' to authenticate and enable Tailscale SSH."
    echo ""
    echo "A browser URL will open for authentication."
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

if command -v tailscale &>/dev/null; then
    echo "Tailscale is already installed, skipping installation."
else
    echo "Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
fi

echo "Starting Tailscale with SSH enabled..."
tailscale up --ssh
