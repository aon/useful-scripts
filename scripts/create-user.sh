#!/usr/bin/env bash
set -euo pipefail

# Create the "agustin" user, set zsh as the login shell, grant docker access
# (if the docker group exists), and install the dotfiles from
# github.com/aon/.dotfiles via stow. Targets Ubuntu/Debian. Run as root.

USERNAME="${1:-agustin}"
DOTFILES_REPO="https://github.com/aon/.dotfiles.git"

usage() {
    echo "Usage: $0 [username] [-h|--help]"
    echo ""
    echo "Creates a user (default: agustin) with zsh as the login shell, adds it"
    echo "to the docker group if that group exists, and installs the dotfiles from"
    echo "${DOTFILES_REPO} using stow."
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
fi

# Install prerequisites.
echo "Installing prerequisites (zsh, git, stow)..."
apt-get update
apt-get install -y zsh git stow ca-certificates

ZSH_BIN="$(command -v zsh)"

# Create the user if it does not already exist.
if id "$USERNAME" &>/dev/null; then
    echo "User '$USERNAME' already exists, ensuring configuration."
    chsh -s "$ZSH_BIN" "$USERNAME"
else
    echo "Creating user '$USERNAME'..."
    useradd --create-home --shell "$ZSH_BIN" "$USERNAME"
fi

USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"

# Grant docker access if the docker group exists.
if getent group docker &>/dev/null; then
    echo "Adding '$USERNAME' to the docker group."
    usermod -aG docker "$USERNAME"
else
    echo "Docker group not found, skipping docker access."
fi

# Install the dotfiles as the target user.
echo "Installing dotfiles into ${USER_HOME}/.dotfiles..."
su - "$USERNAME" -s /bin/bash -c '
    set -euo pipefail
    repo="'"$DOTFILES_REPO"'"
    dest="$HOME/.dotfiles"
    if [[ ! -d "$dest/.git" ]]; then
        # Rewrite SSH submodule URLs to HTTPS so cloning works without SSH keys.
        git -c url."https://github.com/".insteadOf="git@github.com:" \
            clone --recurse-submodules "$repo" "$dest"
    else
        echo "Dotfiles already cloned, updating."
        git -C "$dest" -c url."https://github.com/".insteadOf="git@github.com:" \
            pull --recurse-submodules
    fi
    cd "$dest"
    stow -t "$HOME" .
'

echo "Done. User '$USERNAME' is ready with zsh and dotfiles installed."
