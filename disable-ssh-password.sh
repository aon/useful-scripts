#!/usr/bin/env bash
set -euo pipefail

# Disable SSH password authentication, enforcing key-based login only.

usage() {
    echo "Usage: $0 [-h|--help]"
    echo ""
    echo "Disables password-based SSH login by configuring sshd to reject"
    echo "password authentication. Restarts the SSH service to apply changes."
    echo ""
    echo "Must be run as root."
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

if [[ "$(id -u)" -ne 0 ]]; then
    echo "Error: this script must be run as root." >&2
    exit 1
fi

SSHD_CONFIG="/etc/ssh/sshd_config"

if [[ ! -f "$SSHD_CONFIG" ]]; then
    echo "Error: $SSHD_CONFIG not found." >&2
    exit 1
fi

backup="${SSHD_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
cp "$SSHD_CONFIG" "$backup"
echo "Backed up $SSHD_CONFIG"

settings="
PasswordAuthentication=no
ChallengeResponseAuthentication=no
KbdInteractiveAuthentication=no
UsePAM=no
PermitRootLogin=prohibit-password
"

for entry in $settings; do
    key="${entry%%=*}"
    value="${entry#*=}"
    if grep -qE "^\s*#?\s*${key}\b" "$SSHD_CONFIG"; then
        sed -E "s/^\s*#?\s*${key}\b.*/${key} ${value}/" "$SSHD_CONFIG" > "${SSHD_CONFIG}.tmp" \
            && mv "${SSHD_CONFIG}.tmp" "$SSHD_CONFIG"
    else
        echo "${key} ${value}" >> "$SSHD_CONFIG"
    fi
done

if ! sshd -t 2>/dev/null; then
    echo "Error: sshd config test failed. Restoring backup." >&2
    cp "$backup" "$SSHD_CONFIG"
    exit 1
fi

echo "sshd config updated:"
for entry in $settings; do
    echo "  ${entry%%=*} = ${entry#*=}"
done

if command -v systemctl &>/dev/null; then
    systemctl restart sshd 2>/dev/null || systemctl restart ssh
elif command -v service &>/dev/null; then
    service sshd restart 2>/dev/null || service ssh restart
elif [[ "$(uname)" == "Darwin" ]]; then
    launchctl stop com.openssh.sshd 2>/dev/null || true
    launchctl start com.openssh.sshd 2>/dev/null || true
else
    echo "Warning: could not detect init system. Restart sshd manually." >&2
    exit 0
fi

echo "SSH service restarted. Password login is now disabled."
