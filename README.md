# dotfiles
 
Opinionated terminal setup for DevSecOps engineers. Built for M1/M4 Macs (ARM-native), with Intel fallback. Managed via chezmoi — one command bootstraps any new machine.
 
---
 
## Philosophy
 
IDEs are fine. Terminals are faster once the muscle memory lands.
 
This setup is terminal-first, not terminal-only. Goals:
 
- Zero friction switching between machines
- Every tool earns its place — no bloat
- Config is readable: comments explain *why*, not just *what*
- Works on a caged corporate Mac and a clean personal one equally well
No GUI apps. No App Store dependencies. Homebrew + chezmoi handles everything.
 
---
 
## What's Inside
 
| Category | Tools |
|----------|-------|
| Shell | zsh, oh-my-zsh, starship |
| CLI replacements | eza, bat, ripgrep, fd, fzf, zoxide |
| Data + automation | jq, yq, direnv |
| Multiplexer | tmux |
| Editor | neovim (LazyVim) |
| DevSecOps | k9s, kubectx, stern, trivy, mitmproxy |
| Runtimes | pyenv, fnm |
| Dotfile manager | chezmoi |
 
---
 
## Tool Decisions
 
**Why eza over exa?**
exa was abandoned in 2023. eza is the maintained community fork — drop-in replacement, same flags, same aliases.
 
**Why starship over powerlevel10k?**
p10k requires a configuration wizard and a specific font stack. Starship is a single binary with a toml config. Works with any Nerd Font. Faster to replicate across machines.
 
**Why fnm over nvm?**
nvm is shell-script-based and slows shell startup. fnm is a Rust binary, ARM-native on M-series Macs, with the same `.nvmrc` compatibility.
 
**Why chezmoi over a bare git repo?**
A bare git repo tracking `$HOME` gets messy fast. chezmoi gives you templates (machine-specific paths), encrypted secrets, and a dry-run diff before applying. Essential when Homebrew prefix differs between ARM (`/opt/homebrew`) and Intel (`/usr/local`).
 
**Why LazyVim over hand-rolled init.lua?**
Writing LSP configs from scratch is a weekend project. LazyVim gives you a working IDE-grade setup in an hour and you can override anything. The goal here is vim muscle memory, not vim config mastery.
 
**Why tmux?**
SSH sessions die. tmux doesn't. Also: split panes mean you stop alt-tabbing between terminal windows.
 
---
 
## Quick Start
 
### Prerequisites
 
```sh
xcode-select --install
```
 
Then install Homebrew:
 
```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
 
Add Homebrew to PATH (M4/ARM Macs only):
 
```sh
echo >> ~/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv zsh)"
```
 
### Install chezmoi and apply dotfiles
 
```sh
brew install chezmoi
chezmoi init --apply raghavpoonia
```
 
That's it. chezmoi pulls this repo, runs the bootstrap, and applies all configs.
 
### Install all tools
 
```sh
bash ~/.local/share/chezmoi/bootstrap.sh
```
 
Takes 5–10 minutes. All tools installed via Homebrew.
 
### Set up Neovim
 
```sh
nvim
```
 
LazyVim installs plugins on first launch. Let it finish (~2 min).
 
---
 
## Manual Steps
 
These can't be fully automated:
 
**Ghostty terminal**
Download from [ghostty.org](https://ghostty.org). Config is at `~/.config/ghostty/config` and managed by chezmoi.
 
**fzf shell keybindings**
 
```sh
$(brew --prefix)/opt/fzf/install
```
 
Say yes to all prompts. Enables `CTRL+R` (history) and `CTRL+T` (file search).
 
**Python version**
 
```sh
pyenv install 3.12.0
pyenv global 3.12.0
```
 
**Node version**
 
```sh
fnm install --lts
fnm default lts-latest
```
 
---
 
## Intel Mac Notes
 
Homebrew prefix on Intel is `/usr/local`, not `/opt/homebrew`. chezmoi templates handle this automatically — no manual edits needed when switching between machines.
 
---
 
## Repo Structure
 
```
dotfiles/
├── README.md
├── bootstrap.sh                   # installs all Homebrew packages
├── dot_zshrc                      # zsh config (chezmoi renames to .zshrc)
├── dot_zprofile.tmpl              # PATH and brew shellenv (ARM/Intel template)
├── .chezmoitemplates/
│   └── brew_path.tmpl             # ARM vs Intel Homebrew path
└── dot_config/
    ├── starship.toml              # prompt config
    ├── ghostty/config             # terminal emulator config
    ├── nvim/init.lua              # LazyVim-based neovim config
    └── tmux/tmux.conf             # tmux with vim-style pane navigation
```
 
---
 
MIT License. Feedback and forks welcome.