#!/usr/bin/env bash
# bootstrap.sh
# Installs all Homebrew packages for raghavpoonia/dotfiles
# Safe to re-run — brew install skips already-installed packages
#
# Usage:
#   bash bootstrap.sh           — core setup only
#   bash bootstrap.sh --ml      — core + AI/ML tools
#   bash bootstrap.sh --help    — show what each flag installs
#
# Tested on: macOS 15 Sequoia M4 (ARM64) and Intel x86_64
# Homebrew handles arch differences automatically

set -euo pipefail

ARCH=$(uname -m)
INSTALL_ML=false

# ── Flags ─────────────────────────────────────────────────────────────────────
for arg in "$@"; do
  case $arg in
    --ml)   INSTALL_ML=true ;;
    --help)
      echo ""
      echo "  bootstrap.sh — raghavpoonia/dotfiles"
      echo ""
      echo "  Usage:"
      echo "    bash bootstrap.sh           core setup only"
      echo "    bash bootstrap.sh --ml      core + AI/ML tools"
      echo ""
      echo "  Core installs:"
      echo "    CLI tools   eza, bat, ripgrep, fd, fzf, zoxide, tldr, glow"
      echo "    Data        jq, yq, direnv, wget, curl"
      echo "    Shell       starship, zsh plugins"
      echo "    Editor      neovim (LazyVim)"
      echo "    Multiplexer tmux"
      echo "    DevSecOps   k9s, kubectx, stern, trivy, mitmproxy, grc"
      echo "    Runtimes    pyenv, fnm"
      echo "    Dotfiles    chezmoi"
      echo ""
      echo "  AI/ML installs (--ml flag):"
      echo "    System      cmake, libomp, portaudio"
      echo "    Python pkgs see requirements-ml.txt"
      echo "    Jupyter     jupyterlab, jupytext"
      echo ""
      echo "  When to use --ml:"
      echo "    ML model training, LLM work, transformer research,"
      echo "    Jupyter notebooks, AI security tooling."
      echo "    Not needed for general Python or security tooling."
      echo ""
      echo "  GPU notes:"
      echo "    M-series Mac  Metal/MPS — torch uses Apple GPU automatically"
      echo "    Intel Mac     CPU only — no CUDA, no MPS"
      echo ""
      exit 0
      ;;
  esac
done

echo ""
echo "  raghavpoonia/dotfiles bootstrap"
echo "  arch: $ARCH"
echo "  ml:   $INSTALL_ML"
echo ""

# ── Core CLI replacements ─────────────────────────────────────────────────────
echo "==> Core CLI tools..."
brew install \
  eza \
  bat \
  ripgrep \
  fd \
  fzf \
  zoxide \
  tldr \
  glow

# ── Data + automation ─────────────────────────────────────────────────────────
echo "==> Data tools..."
brew install \
  jq \
  yq \
  direnv \
  wget \
  curl

# ── Shell + prompt ────────────────────────────────────────────────────────────
echo "==> Shell tools..."
brew install \
  starship \
  zsh-autosuggestions \
  zsh-syntax-highlighting \
  zsh-history-substring-search

# ── Terminal multiplexer ──────────────────────────────────────────────────────
echo "==> tmux..."
brew install tmux

# ── Editor ────────────────────────────────────────────────────────────────────
echo "==> Neovim..."
brew install neovim

# ── DevSecOps tools ───────────────────────────────────────────────────────────
echo "==> DevSecOps tools..."
brew install \
  k9s \
  kubectx \
  stern \
  trivy \
  mitmproxy \
  grc

# ── Language runtimes ─────────────────────────────────────────────────────────
echo "==> Language runtime managers..."
brew install \
  pyenv \
  fnm

# ── Dotfile manager ───────────────────────────────────────────────────────────
echo "==> chezmoi..."
brew install chezmoi

# ── fzf shell integration ─────────────────────────────────────────────────────
echo "==> fzf shell keybindings..."
"$(brew --prefix)/opt/fzf/install" --all --no-update-rc


# ── AI/ML (optional) ─────────────────────────────────────────────────────────
if [ "$INSTALL_ML" = true ]; then
  echo ""
  echo "==> AI/ML system dependencies..."
  brew install cmake libomp portaudio

  echo "==> Jupyter..."
  brew install jupyterlab

  echo "==> Python ML packages..."
  if command -v pip3 &>/dev/null; then
    REQS_LOCAL="$(dirname "$0")/requirements-ml.txt"
    if [ -f "$REQS_LOCAL" ]; then
      echo "==> Installing from requirements-ml.txt..."
      pip3 install -r "$REQS_LOCAL"
    else
      pip3 install \
        numpy pandas scikit-learn matplotlib seaborn scipy \
        torch torchvision torchaudio \
        transformers datasets tokenizers accelerate sentencepiece einops \
        langchain langchain-community openai anthropic \
        duckdb faiss-cpu chromadb \
        jupyter jupytext nbformat \
        black ruff mypy ipython rich python-dotenv
    fi

    echo ""
    echo "==> Checking GPU availability..."
    python3 -c "
import torch
mps = torch.backends.mps.is_available()
print(f'  Metal/MPS (Apple Silicon): {mps}')
if not mps:
    print('  Intel Mac — CPU training only')
" 2>/dev/null || echo "  torch not importable yet — restart shell and retry"

  else
    echo "  ⚠️  pip3 not found — set up pyenv Python first"
    echo "  Run: pyenv install 3.12.0 && pyenv global 3.12.0"
    echo "  Then: bash bootstrap.sh --ml"
  fi
fi


# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "==> Bootstrap complete."
echo ""
echo "  Next steps:"
echo "  1. source ~/.zshrc"
echo "  2. pyenv install 3.12.0 && pyenv global 3.12.0"
echo "  3. fnm install --lts && fnm default lts-latest"
echo "  4. nvim  (LazyVim installs plugins on first run)"
echo "  5. brew install --cask ghostty"
echo "  6. brew install --cask font-jetbrains-mono-nerd-font"
if [ "$INSTALL_ML" = false ]; then
  echo ""
  echo "  For AI/ML work: bash bootstrap.sh --ml"
fi
echo ""
echo "  Quick file viewing:"
echo "    bat file.py          syntax highlighted"
echo "    glow README.md       rendered markdown"
echo "    nvim .               open project in neovim"
