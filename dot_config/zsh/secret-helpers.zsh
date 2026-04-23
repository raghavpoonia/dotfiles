#!/usr/bin/env zsh
# secret-helpers.zsh
# macOS Keychain-based secret management for project env vars
# Secrets stored as one JSON blob per project — no plaintext files ever
#
# Source in ~/.zshrc:
#   source ~/.config/zsh/secret-helpers.zsh
#
# Commands:
#   secret-set    PROJECT   — add/update vars interactively
#   secret-load   PROJECT   — export all vars into current shell
#   secret-get    PROJECT VAR_NAME — print one var value
#   secret-list   PROJECT   — list var names (never values)
#   secret-edit   PROJECT   — edit all vars in $EDITOR
#   secret-delete PROJECT   — remove project from keychain


# ── Internal ──────────────────────────────────────────────────────────────────

_secret_service() { echo "dotfiles-secrets-$1" }

# Write JSON blob to keychain via temp file (reliable on macOS Sequoia)
_secret_save() {
  local service="$1"
  local json="$2"
  local tmp
  tmp=$(mktemp /tmp/.secret-XXXXXX.json)
  printf '%s' "$json" > "$tmp"
  security delete-generic-password -a "$USER" -s "$service" 2>/dev/null
  security add-generic-password -a "$USER" -s "$service" -w "$(cat $tmp)" -U 2>/dev/null
  rm -f "$tmp"
}

# Read from terminal — works correctly inside zsh functions
_secret_prompt() {
  local __var="$1" __msg="$2"
  printf '%s' "$__msg" > /dev/tty
  IFS= read -r "$__var" < /dev/tty
}

# Strip surrounding quotes from a value (single or double)
_secret_unquote() {
  local v="$1"
  v="${v#\"}"; v="${v%\"}"
  v="${v#\'}"; v="${v%\'}"
  printf '%s' "$v"
}

# Retrieve raw JSON blob from keychain
_secret_blob() {
  local service="$1"
  local tmp
  tmp=$(mktemp /tmp/.secret-XXXXXX.json)
  security find-generic-password -a "$USER" -s "$service" -w 2>/dev/null > "$tmp"
  local blob
  blob=$(cat "$tmp" 2>/dev/null)
  rm -f "$tmp"
  printf '%s' "$blob"
}


# ── secret-set ────────────────────────────────────────────────────────────────
# Prompts for VAR=value pairs. Empty line to finish.
# Re-running merges — existing vars not overwritten unless re-entered.
secret-set() {
  local project="${1:?Usage: secret-set PROJECT_NAME}"
  local service=$(_secret_service "$project")

  # Load existing or start fresh
  local current
  current=$(_secret_blob "$service")
  [[ -z "$current" ]] && current="{}"

  echo ""
  echo "  project : $project"
  echo "  format  : VAR_NAME=value  or  VAR_NAME=\"value\""
  echo "  tip     : empty line when done"
  echo ""

  local updated="$current"
  local pair key val
  while true; do
    _secret_prompt pair "  > "
    [[ -z "$pair" ]] && break

    key="${pair%%=*}"
    val="${pair#*=}"
    val=$(_secret_unquote "$val")

    if [[ -z "$key" || "$key" == "$pair" ]]; then
      echo "  ⚠️  format: VAR_NAME=value"
      continue
    fi

    updated=$(printf '%s' "$updated" | jq --arg k "$key" --arg v "$val" '.[$k] = $v')
    echo "  ✔  $key"
  done

  _secret_save "$service" "$updated"
  echo ""
  echo "  ✔  saved — run: secret-list $project"
}


# ── secret-load ───────────────────────────────────────────────────────────────
# Exports all vars from a project into the current shell session
secret-load() {
  local project="${1:?Usage: secret-load PROJECT_NAME}"
  local service=$(_secret_service "$project")

  local blob
  blob=$(_secret_blob "$service")

  if [[ -z "$blob" ]]; then
    echo "  ⚠️  no secrets for: $project — run: secret-set $project"
    return 1
  fi

  local count=0
  while IFS='=' read -r k v; do
    export "${k}"="${v}"
    (( count++ ))
  done < <(printf '%s' "$blob" | jq -r 'to_entries[] | "\(.key)=\(.value)"')

  echo "  🔑 $count vars loaded for: $project"
}


# ── secret-get ────────────────────────────────────────────────────────────────
# Print value of one var — useful in scripts
secret-get() {
  local project="${1:?Usage: secret-get PROJECT VAR_NAME}"
  local varname="${2:?Usage: secret-get PROJECT VAR_NAME}"
  local blob
  blob=$(_secret_blob "$(_secret_service "$project")")
  [[ -z "$blob" ]] && { echo "  ⚠️  no secrets for: $project" >&2; return 1 }
  printf '%s' "$blob" | jq -r --arg k "$varname" '.[$k] // empty'
}


# ── secret-list ───────────────────────────────────────────────────────────────
# Show all var names — never values
secret-list() {
  local project="${1:?Usage: secret-list PROJECT_NAME}"
  local blob
  blob=$(_secret_blob "$(_secret_service "$project")")

  if [[ -z "$blob" ]]; then
    echo "  ⚠️  no secrets for: $project"
    return 1
  fi

  local count
  count=$(printf '%s' "$blob" | jq 'length')
  echo ""
  echo "  $count vars stored for: $project"
  echo ""
  printf '%s' "$blob" | jq -r 'keys[]' | while read -r k; do
    echo "    $k"
  done
  echo ""
}


# ── secret-edit ───────────────────────────────────────────────────────────────
# Edit all vars in $EDITOR — opens JSON, saves back to keychain on exit
secret-edit() {
  local project="${1:?Usage: secret-edit PROJECT_NAME}"
  local service=$(_secret_service "$project")

  local blob
  blob=$(_secret_blob "$service")
  [[ -z "$blob" ]] && blob="{}"

  local tmp
  tmp=$(mktemp /tmp/.secret-XXXXXX.json)
  printf '%s' "$blob" | jq '.' > "$tmp"

  ${EDITOR:-nvim} "$tmp" < /dev/tty > /dev/tty 2>&1

  if ! jq '.' "$tmp" &>/dev/null; then
    echo "  ❌ invalid JSON — not saved"
    rm -f "$tmp"
    return 1
  fi

  local updated
  updated=$(cat "$tmp")
  rm -f "$tmp"

  _secret_save "$service" "$updated"
  echo "  ✔  updated: $project"
}


# ── secret-delete ─────────────────────────────────────────────────────────────
secret-delete() {
  local project="${1:?Usage: secret-delete PROJECT_NAME}"
  local service=$(_secret_service "$project")
  local answer
  _secret_prompt answer "  Delete ALL secrets for '$project'? [y/N] "
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    security delete-generic-password -a "$USER" -s "$service" 2>/dev/null
    echo "  ✔  deleted: $project"
  else
    echo "  cancelled"
  fi
}