# smart-cd.zsh
# Auto-triggered on every directory change (chpwd hook)
# Add to ~/.zshrc via: source ~/path/to/smart-cd.zsh
# Or place in oh-my-zsh custom: ~/.oh-my-zsh/custom/smart-cd.zsh

# ── Master hook — runs on every cd ───────────────────────────────────────────
chpwd() {
  _smart_git
  _smart_venv
  _smart_python_version
  _smart_node_version
  _smart_kubecontext
  _smart_env_safety
}


# ── 1. Git: pull prompt + status summary ─────────────────────────────────────
# On cd into a git repo:
#   - Shows branch, ahead/behind remote, dirty file count
#   - If on main or master, asks if you want to pull
_smart_git() {
  # Not a git repo — skip
  git rev-parse --is-inside-work-tree &>/dev/null || return

  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return

  # Count ahead, behind, dirty
  local ahead behind dirty
  ahead=$(git rev-list @{u}..HEAD 2>/dev/null | wc -l | tr -d ' ')
  behind=$(git rev-list HEAD..@{u} 2>/dev/null | wc -l | tr -d ' ')
  dirty=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

  # Status summary line
  echo ""
  echo "  git  branch: $branch | ↑$ahead ↓$behind | $dirty uncommitted"

  # Pull prompt on main/master only
  if [[ "$branch" == "main" || "$branch" == "master" ]]; then
    if [[ "$behind" -gt 0 ]]; then
      echo "  ⚠️  $behind commit(s) behind remote"
      echo -n "  Pull now? [y/N] "
      read -r answer
      if [[ "$answer" =~ ^[Yy]$ ]]; then
        git pull
      fi
    fi
  fi
}


# ── 2. Python venv: activate + update packages ───────────────────────────────
# On cd into a directory:
#   - Activates .venv if found
#   - If requirements.txt exists, asks to pip install -r
#   - If no venv but requirements.txt exists, warns you
# On cd out of a venv directory:
#   - Deactivates automatically
_smart_venv() {
  local venv_path=""

  # Look for venv in common locations
  if [[ -d ".venv" ]]; then
    venv_path=".venv"
  elif [[ -d "venv" ]]; then
    venv_path="venv"
  fi

  if [[ -n "$venv_path" ]]; then
    # Activate if not already active
    if [[ "$VIRTUAL_ENV" != "$(pwd)/$venv_path" ]]; then
      source "$venv_path/bin/activate"
      echo "  🐍 venv activated: $venv_path"
    fi

    # Check requirements
    if [[ -f "requirements.txt" ]]; then
      echo -n "  Update packages from requirements.txt? [y/N] "
      read -r answer
      if [[ "$answer" =~ ^[Yy]$ ]]; then
        pip install -r requirements.txt --quiet
        echo "  ✔ packages updated"
      fi
    fi

    if [[ -f "requirements-dev.txt" ]]; then
      echo -n "  Also install requirements-dev.txt? [y/N] "
      read -r answer
      if [[ "$answer" =~ ^[Yy]$ ]]; then
        pip install -r requirements-dev.txt --quiet
        echo "  ✔ dev packages updated"
      fi
    fi

  else
    # No venv found — deactivate if currently in one
    if [[ -n "$VIRTUAL_ENV" ]]; then
      deactivate
      echo "  🐍 venv deactivated"
    fi

    # Warn if requirements.txt exists with no venv
    if [[ -f "requirements.txt" ]]; then
      echo "  ⚠️  requirements.txt found but no venv — run: python3 -m venv .venv"
    fi
  fi
}


# ── 3. Python version: auto-switch via pyenv ─────────────────────────────────
# If .python-version file exists in the repo, pyenv switches automatically
# This just surfaces a visible confirmation
_smart_python_version() {
  command -v pyenv &>/dev/null || return
  [[ -f ".python-version" ]] || return

  local wanted current
  wanted=$(cat .python-version | tr -d '[:space:]')
  current=$(pyenv version-name 2>/dev/null)

  if [[ "$wanted" != "$current" ]]; then
    echo "  🐍 python switching: $current → $wanted"
    # pyenv handles the actual switch via its own chpwd hook
    # this message just makes it visible
  fi
}


# ── 4. Node version: auto-switch via fnm ─────────────────────────────────────
# If .nvmrc or .node-version found, fnm switches Node version automatically
_smart_node_version() {
  command -v fnm &>/dev/null || return
  [[ -f ".nvmrc" || -f ".node-version" ]] || return

  local wanted
  wanted=$(cat .nvmrc 2>/dev/null || cat .node-version 2>/dev/null | tr -d '[:space:]')

  echo "  ⬡  node version: $wanted (switching via fnm)"
  fnm use --silent-if-unchanged 2>/dev/null
}


# ── 5. Kubecontext: auto-switch if .kubecontext file found ───────────────────
# Drop a .kubecontext file in any repo root with the context name
# e.g. echo "production-us" > .kubecontext
# On cd, automatically switches kubectl context
_smart_kubecontext() {
  command -v kubectx &>/dev/null || return
  [[ -f ".kubecontext" ]] || return

  local wanted current
  wanted=$(cat .kubecontext | tr -d '[:space:]')
  current=$(kubectl config current-context 2>/dev/null)

  if [[ "$wanted" != "$current" ]]; then
    echo -n "  ☁️  switch kube context to '$wanted'? [y/N] "
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      kubectx "$wanted"
    fi
  fi
}


# ── 6. Security: .env safety check ───────────────────────────────────────────
# Warns if .env file exists but is not in .gitignore
# Prevents accidental credential commits
_smart_env_safety() {
  [[ -f ".env" ]] || return

  if [[ -f ".gitignore" ]]; then
    if ! grep -q "\.env" .gitignore 2>/dev/null; then
      echo "  🔴 SECURITY: .env found but not in .gitignore — add it now"
    fi
  else
    echo "  🔴 SECURITY: .env found with no .gitignore — credentials at risk"
  fi
}