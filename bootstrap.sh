#!/usr/bin/env bash
# bootstrap.sh
# Installs all Homebrew packages for raghavpoonia/dotfiles
# Safe to re-run — brew install skips already-installed packages
#
# Usage:
#   bash bootstrap.sh
#
# Tested on: macOS 15 Sequoia, M4 (ARM64)
# Intel compatible: yes (Homebrew handles arch differences)

set -euo pipefail

echo "==> raghavpoonia/dotfiles bootstrap"
echo "==> Architecture: $(uname -m)"
echo ""

# ── Core CLI replacements ────────────────────────────────────────────────────
echo "==> Installing core CLI tools..."
brew install \
  eza \
  bat \
  ripgrep \
  fd \
  fzf \
  zoxide \
  tldr

# ── Data + automation ────────────────────────────────────────────────────────
echo "==> Installing data tools..."
brew install \
  jq \
  yq \
  direnv \
  wget \
  curl

# ── Shell + prompt ───────────────────────────────────────────────────────────
echo "==> Installing shell tools..."
brew install \
  starship \
  zsh-autosuggestions \
  zsh-syntax-highlighting \
  zsh-history-substring-search

# ── Terminal multiplexer ─────────────────────────────────────────────────────
echo "==> Installing tmux..."
brew install tmux

# ── Editor ───────────────────────────────────────────────────────────────────
echo "==> Installing neovim..."
brew install neovim

# ── DevSecOps tools ──────────────────────────────────────────────────────────
echo "==> Installing DevSecOps tools..."
brew install \
  k9s \
  kubectx \
  stern \
  trivy \
  mitmproxy \
  grc

# ── Language runtimes ────────────────────────────────────────────────────────
echo "==> Installing language runtime managers..."
brew install \
  pyenv \
  fnm

# ── Dotfile manager ──────────────────────────────────────────────────────────
echo "==> Installing chezmoi..."
brew install chezmoi

# ── fzf shell integration ────────────────────────────────────────────────────
echo ""
echo "==> Setting up fzf shell keybindings..."
"$(brew --prefix)/opt/fzf/install" --all --no-update-rc

echo ""
echo "==> Bootstrap complete."
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. Set up Python: pyenv install 3.12.0 && pyenv global 3.12.0"
echo "  3. Set up Node:   fnm install --lts && fnm default lts-latest"
echo "  4. Launch neovim: nvim  (LazyVim installs plugins on first run)"
echo "  5. Download Ghostty: https://ghostty.org"
