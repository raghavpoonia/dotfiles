#!/usr/bin/env zsh
# secret-helpers.zsh
# macOS Keychain-based secret management for project env vars
# All secrets stored as one JSON blob per project — no plaintext files
#
# Usage:
#   source ~/.config/zsh/secret-helpers.zsh
#
# Commands:
#   secret-set   PROJECT_NAME    — store all vars for a project interactively
#   secret-load  PROJECT_NAME    — export all vars into current shell
#   secret-get   PROJECT_NAME VAR_NAME — get a single var value
#   secret-list  PROJECT_NAME    — list all var names (not values) for a project
#   secret-edit  PROJECT_NAME    — open stored vars in $EDITOR for editing
#   secret-delete PROJECT_NAME   — remove all vars for a project from keychain


# ── Internal: keychain service name ──────────────────────────────────────────
_secret_service() {
  echo "dotfiles-secrets-$1"
}


# ── secret-set: store vars interactively ─────────────────────────────────────
# Usage: secret-set myproject
# Prompts for each var name and value, stores as JSON in keychain
# To add to existing: secret-set myproject (adds/updates individual keys)
secret-set() {
  local project="${1:?Usage: secret-set PROJECT_NAME}"
  local service=$(_secret_service "$project")

  # Load existing if any
  local existing="{}"
  existing=$(security find-generic-password -a "$USER" -s "$service" -w 2>/dev/null) || existing="{}"

  echo "  Setting secrets for project: $project"
  echo "  Enter VAR_NAME=value pairs. Empty line to finish."
  echo ""

  local updated="$existing"
  while true; do
    echo -n "  VAR_NAME=value (or press Enter to finish): "
    read -r pair
    [[ -z "$pair" ]] && break

    local key="${pair%%=*}"
    local val="${pair#*=}"

    if [[ -z "$key" || -z "$val" ]]; then
      echo "  ⚠️  Invalid format. Use VAR_NAME=value"
      continue
    fi

    # Add/update key in JSON using jq
    updated=$(echo "$updated" | jq --arg k "$key" --arg v "$val" '.[$k] = $v')
    echo "  ✔ $key set"
  done

  # Store updated JSON in keychain
  # Delete existing entry first (keychain won't update in place)
  security delete-generic-password -a "$USER" -s "$service" 2>/dev/null
  security add-generic-password \
    -a "$USER" \
    -s "$service" \
    -w "$updated" \
    -U

  echo ""
  echo "  ✔ Secrets stored in keychain under: $service"
}


# ── secret-load: export all vars into current shell ──────────────────────────
# Usage: secret-load myproject
# Reads JSON blob from keychain, exports each key as env var
secret-load() {
  local project="${1:?Usage: secret-load PROJECT_NAME}"
  local service=$(_secret_service "$project")

  local blob
  blob=$(security find-generic-password -a "$USER" -s "$service" -w 2>/dev/null)

  if [[ -z "$blob" ]]; then
    echo "  ⚠️  No secrets found for project: $project"
    echo "  Run: secret-set $project"
    return 1
  fi

  # Export each key-value pair
  local count=0
  while IFS='=' read -r key val; do
    export "$key"="$val"
    (( count++ ))
  done < <(echo "$blob" | jq -r 'to_entries[] | "\(.key)=\(.value)"')

  echo "  🔑 $count secrets loaded for: $project"
}


# ── secret-get: retrieve a single var ────────────────────────────────────────
# Usage: secret-get myproject VAR_NAME
# Prints the value (useful for scripting)
secret-get() {
  local project="${1:?Usage: secret-get PROJECT_NAME VAR_NAME}"
  local varname="${2:?Usage: secret-get PROJECT_NAME VAR_NAME}"
  local service=$(_secret_service "$project")

  local blob
  blob=$(security find-generic-password -a "$USER" -s "$service" -w 2>/dev/null)

  if [[ -z "$blob" ]]; then
    echo "  ⚠️  No secrets found for project: $project" >&2
    return 1
  fi

  echo "$blob" | jq -r --arg k "$varname" '.[$k] // empty'
}


# ── secret-list: show var names only, never values ───────────────────────────
# Usage: secret-list myproject
secret-list() {
  local project="${1:?Usage: secret-list PROJECT_NAME}"
  local service=$(_secret_service "$project")

  local blob
  blob=$(security find-generic-password -a "$USER" -s "$service" -w 2>/dev/null)

  if [[ -z "$blob" ]]; then
    echo "  ⚠️  No secrets found for project: $project"
    return 1
  fi

  echo "  Secrets for: $project"
  echo ""
  echo "$blob" | jq -r 'keys[]' | while read -r key; do
    echo "    $key"
  done
}


# ── secret-edit: edit vars in $EDITOR ────────────────────────────────────────
# Usage: secret-edit myproject
# Opens current JSON in editor, saves back to keychain on exit
# WARNING: briefly writes to /tmp — never on a shared machine
secret-edit() {
  local project="${1:?Usage: secret-edit PROJECT_NAME}"
  local service=$(_secret_service "$project")

  local blob
  blob=$(security find-generic-password -a "$USER" -s "$service" -w 2>/dev/null) || blob="{}"

  local tmpfile
  tmpfile=$(mktemp /tmp/secrets-XXXXXX.json)
  echo "$blob" | jq '.' > "$tmpfile"

  "${EDITOR:-nvim}" "$tmpfile"

  # Validate JSON before saving
  if ! jq '.' "$tmpfile" &>/dev/null; then
    echo "  ❌ Invalid JSON — changes not saved"
    rm -f "$tmpfile"
    return 1
  fi

  local updated
  updated=$(cat "$tmpfile")
  rm -f "$tmpfile"

  security delete-generic-password -a "$USER" -s "$service" 2>/dev/null
  security add-generic-password \
    -a "$USER" \
    -s "$service" \
    -w "$updated" \
    -U

  echo "  ✔ Secrets updated for: $project"
}


# ── secret-delete: remove all vars for a project ─────────────────────────────
# Usage: secret-delete myproject
secret-delete() {
  local project="${1:?Usage: secret-delete PROJECT_NAME}"
  local service=$(_secret_service "$project")

  echo -n "  Delete ALL secrets for '$project'? This cannot be undone. [y/N] "
  read -r answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    security delete-generic-password -a "$USER" -s "$service" 2>/dev/null
    echo "  ✔ Deleted secrets for: $project"
  else
    echo "  Cancelled"
  fi
}