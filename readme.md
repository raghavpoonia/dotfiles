20250421 | dotfiles - Terminal Setup for DevSecOps by Raghav Dinesh
#wrap #vault

# dotfiles

Opinionated terminal setup for DevSecOps engineers. Built for M1/M4 Macs
(ARM-native), with Intel fallback. Managed via chezmoi so one command
bootstraps any new machine.

---

Contents
1. Philosophy
2. What's Inside
3. Tool Decisions
4. Quick Start
5. Manual Steps
6. Intel Mac Notes
7. Structure


---


1. Philosophy

IDEs are fine. Terminals are faster once the muscle memory lands.

This setup is terminal-first, not terminal-only. The goal is:
- Zero friction switching between machines
- Every tool earns its place (no bloat)
- Config is readable — comments explain why, not just what
- Works on a caged corporate Mac and a clean personal one equally well

No GUI apps. No App Store dependencies. Homebrew + chezmoi handles
everything.


2. What's Inside

Shell
- zsh (default on macOS since Catalina)
- oh-my-zsh for plugin management
- starship for prompt (fast, no Node dependency)

Plugins
- zsh-autosuggestions    — ghost text from history as you type
- zsh-syntax-highlighting — red = bad command, green = found
- zsh-history-substring-search — UP arrow searches history by prefix

Core CLI replacements
- eza      — ls with git status, icons, tree view (maintained exa fork)
- bat      — cat with syntax highlighting and line numbers
- ripgrep  — grep but 10x faster, respects .gitignore
- fd       — find but simpler syntax and faster
- fzf      — fuzzy finder: CTRL+R for history, CTRL+T for files
- zoxide   — smarter cd, remembers your most-used dirs

Data + Automation
- jq       — JSON query and transform
- yq       — YAML query (jq sibling)
- direnv   — per-directory env vars, auto-loads on cd

Terminal Multiplexer
- tmux     — split panes, sessions, detach/reattach

Editor
- neovim   — modal editor, LazyVim distribution
- configured for Python, Go, YAML, Markdown, shell

DevSecOps Tools
- k9s      — Kubernetes cluster management in terminal
- kubectx  — switch kube contexts fast
- stern    — tail multiple pod logs simultaneously
- trivy    — vulnerability scanner for containers and repos
- mitmproxy — intercept and inspect HTTP/HTTPS traffic

Language Runtimes
- pyenv    — manage multiple Python versions
- fnm      — fast Node version manager (ARM-native)

Dotfile Manager
- chezmoi  — templates + machine-specific overrides, single source of truth


3. Tool Decisions

Why eza over exa?
  exa was abandoned in 2023. eza is the community fork, actively maintained,
  drop-in replacement. Same flags, same aliases.

Why starship over powerlevel10k?
  p10k requires a configuration wizard and a specific font stack. Starship
  is a single binary, toml config, works with any Nerd Font. Faster to
  replicate across machines.

Why fnm over nvm?
  nvm is shell-script-based and slows shell startup. fnm is a Rust binary,
  ARM-native on M-series Macs, same .nvmrc compatibility.

Why chezmoi over bare git repo?
  A bare git repo tracking $HOME gets messy fast. chezmoi gives you
  templates (machine-specific paths), encrypted secrets, and a dry-run
  diff before applying. Essential when Homebrew prefix differs between
  ARM (/opt/homebrew) and Intel (/usr/local).

Why LazyVim over hand-rolled init.lua?
  Writing LSP configs from scratch is a weekend project. LazyVim gives
  you a working IDE-grade setup in an hour, and you can override anything.
  The goal here is vim muscle memory, not vim config mastery.

Why tmux?
  SSH sessions die. tmux doesn't. Also: split panes mean you stop
  alt-tabbing between terminal windows.


4. Quick Start

4.1 Prerequisites

  xcode-select --install

  Then install Homebrew:

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  Add Homebrew to PATH (M4/ARM Macs):

  echo >> ~/.zprofile
  echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"

4.2 Install chezmoi and apply dotfiles

  brew install chezmoi
  chezmoi init --apply raghavpoonia

  That's it. chezmoi pulls this repo, runs the bootstrap, and applies
  all configs.

4.3 Install tools

  bash ~/.local/share/chezmoi/bootstrap.sh

  Takes 5-10 minutes. All tools installed via Homebrew.

4.4 Set up Neovim

  nvim

  LazyVim will install plugins on first launch. Let it finish (~2 min).


5. Manual Steps

These can't be fully automated:

5.1 Ghostty terminal
  Download from https://ghostty.org
  Config is at ~/.config/ghostty/config and managed by chezmoi.

5.2 fzf shell keybindings
  After brew install fzf, run:

  $(brew --prefix)/opt/fzf/install

  Say yes to all prompts. Enables CTRL+R and CTRL+T.

5.3 pyenv Python version
  pyenv install 3.12.0
  pyenv global 3.12.0

5.4 fnm Node version
  fnm install --lts
  fnm default lts-latest


6. Intel Mac Notes

Homebrew prefix on Intel is /usr/local, not /opt/homebrew.
chezmoi templates handle this automatically via:

  {{ if eq .chezmoi.arch "arm64" }}
  eval "$(/opt/homebrew/bin/brew shellenv)"
  {{ else }}
  eval "$(/usr/local/bin/brew shellenv)"
  {{ end }}

No manual edits needed when switching between machines.


7. Structure

  dotfiles/
  ├── README.md                  — this file
  ├── bootstrap.sh               — installs all Homebrew packages
  ├── dot_zshrc                  — zsh config (chezmoi renames to .zshrc)
  ├── dot_zprofile               — PATH and brew shellenv
  ├── .chezmoitemplates/
  │   └── brew_path.tmpl         — ARM vs Intel Homebrew path template
  ├── dot_config/
  │   ├── starship.toml          — prompt config
  │   ├── ghostty/
  │   │   └── config             — terminal emulator config
  │   ├── nvim/                  — LazyVim-based neovim config
  │   │   ├── init.lua
  │   │   └── lua/plugins/       — per-language plugin overrides
  │   └── tmux/
  │       └── tmux.conf          — tmux config with vim-style pane nav
  └── dot_gitconfig              — global git config


---

MIT License.
Feedback and forks welcome.