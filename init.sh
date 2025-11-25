#!/usr/bin/env bash
set -euo pipefail

# init.sh — Install helper for sbrc
# Detects the user's interactive shell and adds a source entry to their rc
# Usage: ./init.sh [-y] [--shell SHELL]

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILE="$REPO_DIR/.sbrc"
AUTO_YES=0
FORCE_SHELL=""

print_help() {
  cat <<EOF
Usage: init.sh [-y] [--shell SHELL]

Options:
  -y            Run non-interactively and add source without prompting
  --shell SHELL Force target shell (bash, zsh, fish, ksh)
  -h, --help    Show this help message
EOF
}

while [[ ${#} -gt 0 ]]; do
  case "$1" in
    -y) AUTO_YES=1; shift ;;
    --shell) FORCE_SHELL="$2"; shift 2 ;;
    -h|--help) print_help; exit 0 ;;
    *) echo "Unknown option: $1"; print_help; exit 2 ;;
  esac
done

determine_shell() {
  # Prefer forced shell
  if [[ -n "$FORCE_SHELL" ]]; then
    echo "$FORCE_SHELL"
    return
  fi

  # Try $SHELL
  if [[ -n "${SHELL:-}" ]]; then
    bname="$(basename "$SHELL")"
    case "$bname" in
      bash|zsh|ksh|fish) echo "$bname"; return ;;
    esac
  fi

  # Fall back to process of current shell
  if ps -p $$ -o comm= >/dev/null 2>&1; then
    psh=$(ps -p $$ -o comm= | awk -F/ '{print $NF}' | tr -d ' -')
    case "$psh" in
      bash|zsh|ksh|fish) echo "$psh"; return ;;
    esac
  fi

  # Default
  echo "sh"
}

rc_for_shell() {
  local sh="$1"
  case "$sh" in
    zsh) echo "$HOME/.zshrc" ;;
    bash)
      # On macOS, add to ~/.bash_profile if no ~/.bashrc
      if [[ -f "$HOME/.bashrc" ]]; then
        echo "$HOME/.bashrc"
      else
        echo "$HOME/.bash_profile"
      fi
      ;;
    fish)
      mkdir -p "$HOME/.config/fish"
      echo "$HOME/.config/fish/config.fish" ;;
    ksh) echo "$HOME/.kshrc" ;;
    sh|profile) echo "$HOME/.profile" ;;
    *) echo "$HOME/.profile" ;;
  esac
}

ensure_backup() {
  local file="$1"
  if [[ -f "$file" ]]; then
    cp "$file" "$file.bak.$(date +%Y%m%d%H%M%S)"
    echo "Backup created: $file.bak.*"
  fi
}

insert_block() {
  local rcfile="$1"
  local sh="$2"
  local block_start="# sbrc: start (added by sbrc/init.sh)
"
  local block_end="# sbrc: end (added by sbrc/init.sh)
"

  # Prepare body depending on shell
  local body=""
  case "$sh" in
    fish)
      body="if test -f '$DOTFILE'\n    source '$DOTFILE'\nend"
      ;;
    *)
      body="[ -f '$DOTFILE' ] && source '$DOTFILE'"
      ;;
  esac

  # Idempotency: if a start marker exists, skip
  if grep -q "# sbrc: start (added by sbrc/init.sh)" "$rcfile" 2>/dev/null; then
    echo "sbrc already installed in $rcfile — skipping." 
    return
  fi

  # Ensure rc file exists
  mkdir -p "$(dirname "$rcfile")"
  touch "$rcfile"

  echo "Installing sbrc into $rcfile"
  ensure_backup "$rcfile"

  # Append the block
  printf "\n%s\n\n%s\n%s\n\n" "$block_start" "$body" "$block_end" >> "$rcfile"
  echo "Done. Please restart your shell or source $rcfile to apply changes." 
}

main() {
  if [[ ! -f "$DOTFILE" ]]; then
    echo "Error: $DOTFILE not found. Run this from repository root or clone sbrc to ~ and run it." >&2
    exit 1
  fi

  shname="$(determine_shell)"
  rcfile="$(rc_for_shell "$shname")"

  if [[ $AUTO_YES -eq 0 ]]; then
    echo "Detected shell: $shname"
    echo "Target rc file: $rcfile"
    read -p "Proceed to add sbrc to $rcfile? [y/N] " ans || true
    case "$ans" in
      y|Y|yes|Yes) ;;
      *) echo "Cancelled."; exit 0 ;;
    esac
  fi

  insert_block "$rcfile" "$shname"
}

main
