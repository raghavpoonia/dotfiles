#!/usr/bin/env zsh
# secret-helpers.zsh
# macOS Keychain-based secret management for project env vars
# All secrets stored as one JSON blob per project — no plaintext files
#
# Usage:
#   source ~/.config/zsh/secret-helpers.zsh
#
# Commands:
#   secret-set    PROJECT_NAME              — store vars interactively
#   secret-load   PROJECT_NAME              — export all vars into current shell
#   secret-get    PROJECT_NAME VAR_NAME     — get a single var value
#   secret-list   PROJECT_NAME              — list all var names (not values)
#   secret-edit   PROJECT_NAME              — edit vars in $EDITOR
#   secret-delete PROJECT_NAME              — remove all vars for a project


# ── Internal helpers ──────────────────────────────────────────────────────────
_secret_service() { echo "dotfiles-secrets-$1" }

_secret_read() {
  # Read a line from the terminal directly — works inside zsh functions
  local __var="$1"
  local __prompt="$2"
  echo -n "$__prompt" > /dev/tty
  read -r "$__var" < /dev/tty
}

_secret_strip_quotes() {
  # Strip surrounding single or double quotes from a value
  local val="$1"
  val="${val#\"}" ; val="${val%\"}"
  val="${val#\'}" ; val="${val%\'}"
  echo "$val"
}


# ── secret-set ────────────────────────────────────────────────────────────────
# Usage: secret-set myproject
# Prompts VAR_NAME="value" pairs one at a time, empty line to finish
# Re-running adds/updates keys without wiping existing ones
secret-set() {
  local project="${1:?Usage: secret-set PROJECT_NAME}"
  local service=$(_secret_service "$project")

  # Load existing blob if any
  local updated="{}"
  updated=$(security find-generic-password -a "$USER" -s "$service" -w 2>/dev/null) || updated="{}"

  echo "  Setting secrets for: $project"
  echo "  Format: VAR_NAME=value or VAR_NAME=\"value\""
  echo "  Empty line to finish."
  echo ""

  local pair key val
  while true; do
    _secret_read pair "  > "
    [[ -z "$pair" ]] && break

    # Split on first = only
    key="${pair%%=*}"
    val="${pair#*=}"

    # Strip surrounding quotes from value
    val=$(_secret_strip_quotes "$val")

    if [[ -z "$key" || "$key" == "$pair" ]]; then
      echo "  ⚠️  Use VAR_NAME=value format"
      continue
    fi

    updated=$(printf '%s' "$updated" | jq --arg k "$key" --arg v "$val" '.[$k] = $v')
    echo "  ✔ $key"
  done

  # Save to keychain
  security delete-generic-password -a "$USER" -s "$service" 2>/dev/null
  security add-generic-password -a "$USER" -s "$service" -w "$updated" -U 2>/dev/null

  echo ""
  echo "  ✔ Saved to keychain: $service"
  echo "  Run 'secret-list $project' to verify"
}


# ── secret-load ───────────────────────────────────────────────────────────────
# Usage: secret-load myproject
# Exports all vars into the current shell session
secret-load() {
  local project="${1:?Usage: secret-load PROJECT_NAME}"
  local service=$(_secret_service "$project")

  local blob
  blob=$(security find-generic-password -a "$USER" -s "$service" -w 2>/dev/null)

  if [[ -z "$blob" ]]; then
    echo "  ⚠️  No secrets found for: $project"
    echo "  Run: secret-set $project"
    return 1
  fi

  local count=0
  while IFS='=' read -r key val; do
    export "${key}"="${val}"
    (( count++ ))
  done < <(printf '%s' "$blob" | jq -r 'to_entries[] | "\(.key)=\(.value)"')

  echo "  🔑 $count vars loaded for: $project"
}


# ── secret-get ────────────────────────────────────────────────────────────────
# Usage: secret-get myproject VAR_NAME
secret-get() {
  local project="${1:?Usage: secret-get PROJECT_NAME VAR_NAME}"
  local varname="${2:?Usage: secret-get PROJECT_NAME VAR_NAME}"
  local service=$(_secret_service "$project")

  local blob
  blob=$(security find-generic-password -a "$USER" -s "$service" -w 2>/dev/null)

  [[ -z "$blob" ]] && { echo "  ⚠️  No secrets for: $project" >&2; return 1 }

  printf '%s' "$blob" | jq -r --arg k "$varname" '.[$k] // empty'
}


# ── secret-list ───────────────────────────────────────────────────────────────
# Usage: secret-list myproject
# Shows var names only — never values
secret-list() {
  local project="${1:?Usage: secret-list PROJECT_NAME}"
  local service=$(_secret_service "$project")

  local blob
  blob=$(security find-generic-password -a "$USER" -s "$service" -w 2>/dev/null)

  if [[ -z "$blob" ]]; then
    echo "  ⚠️  No secrets found for: $project"
    return 1
  fi

  local count
  count=$(printf '%s' "$blob" | jq 'length')
  echo "  $count secrets for: $project"
  echo ""
  printf '%s' "$blob" | jq -r 'keys[]' | while read -r key; do
    echo "    $key"
  done
}


# ── secret-edit ───────────────────────────────────────────────────────────────
# Usage: secret-edit myproject
# Opens JSON in $EDITOR, saves back to keychain on exit
# Temp file lives in /tmp briefly — clean personal machine only
secret-edit() {
  local project="${1:?Usage: secret-edit PROJECT_NAME}"
  local service=$(_secret_service "$project")

  local blob="{}"
  blob=$(security find-generic-password -a "$USER" -s "$service" -w 2>/dev/null) || blob="{}"

  local tmpfile
  tmpfile=$(mktemp /tmp/secrets-XXXXXX.json)
  printf '%s' "$blob" | jq '.' > "$tmpfile"

  # Open editor bound to terminal
  ${EDITOR:-nvim} "$tmpfile" < /dev/tty > /dev/tty 2>&1

  # Validate JSON
  if ! jq '.' "$tmpfile" &>/dev/null; then
    echo "  ❌ Invalid JSON — not saved"
    rm -f "$tmpfile"
    return 1
  fi

  local updated
  updated=$(cat "$tmpfile")
  rm -f "$tmpfile"

  security delete-generic-password -a "$USER" -s "$service" 2>/dev/null
  security add-generic-password -a "$USER" -s "$service" -w "$updated" -U 2>/dev/null

  echo "  ✔ Secrets updated for: $project"
}


# ── secret-delete ─────────────────────────────────────────────────────────────
# Usage: secret-delete myproject
secret-delete() {
  local project="${1:?Usage: secret-delete PROJECT_NAME}"
  local service=$(_secret_service "$project")

  local answer
  _secret_read answer "  Delete ALL secrets for '$project'? [y/N] "
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    security delete-generic-password -a "$USER" -s "$service" 2>/dev/null
    echo "  ✔ Deleted: $project"
  else
    echo "  Cancelled"
  fi
}