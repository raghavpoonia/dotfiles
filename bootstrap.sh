#!/usr/bin/env bash
# bootstrap.sh
# ruwgxo/dotfiles
# Safe to re-run — brew skips already-installed packages
#
# Usage:
#   bash bootstrap.sh           core setup only
#   bash bootstrap.sh --ml      core + AI/ML tools
#   bash bootstrap.sh --help    what each flag installs

set -euo pipefail

ARCH=$(uname -m)
INSTALL_ML=false

for arg in "$@"; do
  case $arg in
    --ml) INSTALL_ML=true ;;
    --help)
      echo ""
      echo "  bootstrap.sh — ruwgxo/dotfiles"
      echo ""
      echo "  Usage:"
      echo "    bash bootstrap.sh           core setup only"
      echo "    bash bootstrap.sh --ml      core + AI/ML tools"
      echo ""
      echo "  Core installs:"
      echo "    CLI     eza bat ripgrep fd fzf zoxide tldr glow"
      echo "    Data    jq yq direnv wget curl"
      echo "    Shell   starship zsh-plugins"
      echo "    Editor  neovim (LazyVim)"
      echo "    Tmux    terminal multiplexer"
      echo "    SecOps  k9s kubectx stern trivy mitmproxy grc"
      echo "    Runtime pyenv fnm"
      echo ""
      echo "  AI/ML installs (--ml):"
      echo "    System  cmake libomp portaudio jupyterlab"
      echo "    Python  see requirements-ml.txt"
      echo "    Needs pyenv Python active before running"
      echo ""
      echo "  GPU notes:"
      echo "    Apple Silicon  Metal/MPS — torch auto-detects"
      echo "    Intel          CPU only, no CUDA or MPS"
      echo ""
      exit 0
      ;;
  esac
done

echo ""
echo "  ruwgxo/dotfiles bootstrap"
echo "  arch : $ARCH"
echo "  ml   : $INSTALL_ML"
echo ""

# ── Core CLI ──────────────────────────────────────────────────────────────────
echo "==> Core CLI tools..."
brew install eza bat ripgrep fd fzf zoxide tldr glow

# ── Data + automation ─────────────────────────────────────────────────────────
echo "==> Data tools..."
brew install jq yq direnv wget curl

# ── Shell ─────────────────────────────────────────────────────────────────────
echo "==> Shell tools..."
brew install starship zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search

# ── Tmux ──────────────────────────────────────────────────────────────────────
echo "==> tmux..."
brew install tmux

# ── Neovim ────────────────────────────────────────────────────────────────────
echo "==> Neovim..."
brew install neovim

# ── DevSecOps ─────────────────────────────────────────────────────────────────
echo "==> DevSecOps tools..."
brew install k9s kubectx stern trivy mitmproxy grc

# ── Runtimes ──────────────────────────────────────────────────────────────────
echo "==> Language runtimes..."
brew install pyenv fnm

# ── Dotfiles ──────────────────────────────────────────────────────────────────
echo "==> chezmoi..."
brew install chezmoi

# ── fzf keybindings ───────────────────────────────────────────────────────────
echo "==> fzf shell integration..."
"$(brew --prefix)/opt/fzf/install" --all --no-update-rc


# ── AI/ML (optional) ─────────────────────────────────────────────────────────
if [ "$INSTALL_ML" = true ]; then
  echo ""
  echo "==> AI/ML system dependencies..."
  brew install cmake libomp portaudio jupyterlab

  echo "==> Python ML packages..."

  # Must use pyenv Python — system Python is protected on macOS Sequoia/Sonoma
  PYTHON_PATH=$(which python3 2>/dev/null || echo "none")

  if [[ "$PYTHON_PATH" != *"pyenv"* ]]; then
    echo ""
    echo "  ⚠️  pyenv Python not active — skipping pip installs"
    echo "  System Python is externally managed and cannot install packages"
    echo ""
    echo "  Run these first then re-run bootstrap.sh --ml:"
    echo "    pyenv install 3.12.0"
    echo "    pyenv global 3.12.0"
    echo "    source ~/.zshrc"
    echo ""
  else
    echo "  ✔ pyenv Python: $PYTHON_PATH"

    REQS="$(dirname "$0")/requirements-ml.txt"
    if [ -f "$REQS" ]; then
      pip3 install -r "$REQS"
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
    echo "==> GPU check..."
    python3 - <<'PYCHECK'
try:
    import torch
    mps = torch.backends.mps.is_available()
    print(f"  Metal/MPS (Apple Silicon): {mps}")
    if not mps:
        print("  Intel Mac — CPU training only")
except ImportError:
    print("  torch not yet importable — restart shell and re-check")
PYCHECK
  fi
fi


# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "==> Bootstrap complete."
echo ""
echo "  Next steps:"
echo "    1. source ~/.zshrc"
echo "    2. pyenv install 3.12.0 && pyenv global 3.12.0"
echo "    3. fnm install --lts && fnm default lts-latest"
echo "    4. nvim  (LazyVim installs plugins on first run)"
echo "    5. brew install --cask ghostty"
echo "    6. brew install --cask font-jetbrains-mono-nerd-font"
if [ "$INSTALL_ML" = false ]; then
  echo ""
  echo "  For AI/ML work: bash bootstrap.sh --ml"
fi
echo ""
echo "  Quick file viewing:"
echo "    bat file.py        syntax highlighted"
echo "    glow README.md     rendered markdown"
echo "    nvim .             open project in neovim"
