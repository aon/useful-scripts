#!/usr/bin/env bash
set -euo pipefail

# Install the CLI tools the dotfiles expect: eza, fzf, zoxide, neovim, lazygit.
# Installs system-wide into /usr/local/bin. Targets Debian/Ubuntu. Run as root.

usage() {
    echo "Usage: $0 [-h|--help]"
    echo ""
    echo "Installs the CLI tools referenced by the dotfiles (eza, fzf, zoxide,"
    echo "neovim, lazygit) into /usr/local/bin. Already-installed tools are skipped."
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
fi

case "$(uname -m)" in
    x86_64 | amd64) RUST_ARCH=x86_64; NVIM_ARCH=x86_64; LG_ARCH=x86_64 ;;
    aarch64 | arm64) RUST_ARCH=aarch64; NVIM_ARCH=arm64; LG_ARCH=arm64 ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

echo "Installing prerequisites..."
apt-get update
apt-get install -y curl git tar ca-certificates

# Print the latest release tag (e.g. v0.44.1) for a GitHub owner/repo.
github_latest_tag() {
    curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
        | grep -m1 '"tag_name"' | cut -d'"' -f4
}

install_eza() {
    command -v eza &>/dev/null && { echo "eza already installed."; return; }
    local tag url tmp
    tag="$(github_latest_tag eza-community/eza)"
    url="https://github.com/eza-community/eza/releases/download/${tag}/eza_${RUST_ARCH}-unknown-linux-gnu.tar.gz"
    tmp="$(mktemp -d)"
    curl -fsSL "$url" | tar -xz -C "$tmp"
    install -m 0755 "$tmp/eza" /usr/local/bin/eza
    rm -rf "$tmp"
    echo "Installed eza ${tag}."
}

install_fzf() {
    command -v fzf &>/dev/null && { echo "fzf already installed."; return; }
    [[ -d /opt/fzf ]] || git clone --depth 1 https://github.com/junegunn/fzf.git /opt/fzf
    /opt/fzf/install --bin
    ln -sf /opt/fzf/bin/fzf /usr/local/bin/fzf
    echo "Installed fzf."
}

install_zoxide() {
    command -v zoxide &>/dev/null && { echo "zoxide already installed."; return; }
    local tag ver url tmp
    tag="$(github_latest_tag ajeetdsouza/zoxide)"
    ver="${tag#v}"
    url="https://github.com/ajeetdsouza/zoxide/releases/download/${tag}/zoxide-${ver}-${RUST_ARCH}-unknown-linux-musl.tar.gz"
    tmp="$(mktemp -d)"
    curl -fsSL "$url" | tar -xz -C "$tmp"
    install -m 0755 "$tmp/zoxide" /usr/local/bin/zoxide
    rm -rf "$tmp"
    echo "Installed zoxide ${tag}."
}

install_neovim() {
    command -v nvim &>/dev/null && { echo "neovim already installed."; return; }
    local base="https://github.com/neovim/neovim/releases/download/stable"
    rm -rf /opt/nvim
    mkdir -p /opt/nvim
    # Recent releases ship nvim-linux-<arch>.tar.gz; older x86_64 used nvim-linux64.tar.gz.
    if ! curl -fsSL "${base}/nvim-linux-${NVIM_ARCH}.tar.gz" | tar -xz -C /opt/nvim --strip-components=1; then
        [[ "$NVIM_ARCH" == "x86_64" ]] &&
            curl -fsSL "${base}/nvim-linux64.tar.gz" | tar -xz -C /opt/nvim --strip-components=1
    fi
    ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
    echo "Installed neovim."
}

install_lazygit() {
    command -v lazygit &>/dev/null && { echo "lazygit already installed."; return; }
    local tag ver url tmp
    tag="$(github_latest_tag jesseduffield/lazygit)"
    ver="${tag#v}"
    url="https://github.com/jesseduffield/lazygit/releases/download/${tag}/lazygit_${ver}_Linux_${LG_ARCH}.tar.gz"
    tmp="$(mktemp -d)"
    curl -fsSL "$url" | tar -xz -C "$tmp" lazygit
    install -m 0755 "$tmp/lazygit" /usr/local/bin/lazygit
    rm -rf "$tmp"
    echo "Installed lazygit ${tag}."
}

# Best-effort: a failure in one tool should not abort the rest.
for tool in eza fzf zoxide neovim lazygit; do
    "install_${tool}" || echo "WARNING: failed to install ${tool}, continuing." >&2
done

echo "Tool installation complete."
