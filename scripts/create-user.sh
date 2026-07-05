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

# Install prerequisites. build-essential and python3 are needed to compile
# native node modules (e.g. node-pty) that have no prebuilt Linux binaries.
echo "Installing prerequisites (zsh, git, stow, build tools)..."
apt-get update
apt-get install -y zsh git stow ca-certificates curl build-essential python3 sudo openssh-client

# Install the CLI tools the dotfiles expect (eza, fzf, zoxide, neovim, lazygit).
echo "Installing CLI tools..."
curl -fsSL https://raw.githubusercontent.com/aon/useful-scripts/refs/heads/main/scripts/install-tools.sh | bash

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

# Grant passwordless sudo. The account has no password, so NOPASSWD lets it run
# privileged commands without one.
echo "Granting passwordless sudo to '$USERNAME'."
usermod -aG sudo "$USERNAME"
printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$USERNAME" > "/etc/sudoers.d/$USERNAME"
chmod 0440 "/etc/sudoers.d/$USERNAME"
visudo -cf "/etc/sudoers.d/$USERNAME"

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

    # Generate an SSH key if none exists. Used both for pushing to GitHub
    # (pushInsteadOf sends pushes over SSH) and for signing commits (the
    # dotfiles .gitconfig sets gpg.format=ssh with ~/.ssh/id_ed25519.pub).
    if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
        mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
        ssh-keygen -t ed25519 -N "" -f "$HOME/.ssh/id_ed25519" -C "$USER@$(hostname)"
    fi
    # Trust GitHub host key so the first SSH push does not fail verification.
    if ! grep -q "^github.com " "$HOME/.ssh/known_hosts" 2>/dev/null; then
        ssh-keyscan -t ed25519 github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null
    fi

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

    # Install nvm (into ~/.nvm) and the latest LTS node. The dotfiles lazy-load
    # nvm from $NVM_DIR, so PROFILE=/dev/null keeps the installer from editing them.
    export NVM_DIR="$HOME/.nvm"
    if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
        PROFILE=/dev/null bash -c "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash"
    fi
    . "$NVM_DIR/nvm.sh"
    nvm install --lts

    # Install bun (into ~/.bun) if missing; the dotfiles already add it to PATH.
    export BUN_INSTALL="$HOME/.bun"
    if [[ ! -x "$BUN_INSTALL/bin/bun" ]]; then
        curl -fsSL https://bun.sh/install | bash
    fi
    export PATH="$BUN_INSTALL/bin:$PATH"

    # Install Claude Code (into ~/.local/bin, already on PATH via the dotfiles).
    if ! command -v claude &>/dev/null && [[ ! -x "$HOME/.local/bin/claude" ]]; then
        curl -fsSL https://claude.ai/install.sh | bash
    fi

    # Install the pi coding agent (into ~/.bun/bin) via bun.
    if [[ ! -x "$BUN_INSTALL/bin/pi" ]]; then
        bun install -g @earendil-works/pi-coding-agent
    fi

    # The bun/claude installers may append PATH lines to stowed shell rc files;
    # the dotfiles already set those paths, so revert edits to keep the repo clean.
    git -C "$HOME/.dotfiles" checkout -- . 2>/dev/null || true

    echo ""
    echo "==> Add this SSH key to GitHub (authentication + signing key):"
    echo "    https://github.com/settings/keys"
    cat "$HOME/.ssh/id_ed25519.pub"
'

echo "Done. User '$USERNAME' is ready with zsh, dotfiles, and node installed."
