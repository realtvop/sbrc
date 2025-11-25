#!/usr/bin/env bash
set -euo pipefail

# install.sh — clones the sbrc repo and runs init.sh to install into the user's shell
# Usage:
#   ./install.sh [-y] [--dest PATH] [--repo URL] [--branch BRANCH]
#   curl -fsSL https://raw.githubusercontent.com/realtvop/sbrc/main/install.sh | bash -s -- -y

REPO_URL_DEFAULT="https://github.com/realtvop/sbrc.git"
DEST_DEFAULT="$HOME/sbrc"
BRANCH=""
FORCE_YES=0
REPO_URL=""
DEST=""

print_help(){
  cat <<'EOF'
Usage: install.sh [-y] [--dest PATH] [--repo URL] [--branch BRANCH]

Options:
  -y                Run non-interactively; accept defaults and overwrite if necessary
  --dest PATH       Destination path to clone to (default: ~/sbrc)
  --repo URL        Git repo URL to clone from (default: https://github.com/realtvop/sbrc.git)
  --branch BRANCH   Branch to checkout after cloning (default: repository default branch)
  -h, --help        Show this help
EOF
}

parse_args(){
  REPO_URL="$REPO_URL_DEFAULT"
  DEST="$DEST_DEFAULT"

  while [[ ${#} -gt 0 ]]; do
    case "$1" in
      -y) FORCE_YES=1; shift ;;
      --dest) DEST="$2"; shift 2 ;;
      --repo) REPO_URL="$2"; shift 2 ;;
      --branch) BRANCH="$2"; shift 2 ;;
      -h|--help) print_help; exit 0 ;;
      --) shift; break ;;
      *) echo "Unknown option: $1" >&2; print_help; exit 2 ;;
    esac
  done
}

require_git(){
  if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is required to run this installer. Please install git and try again." >&2
    exit 1
  fi
}

backup_existing(){
  local path="$1"
  if [[ -e "$path" ]]; then
    local stamp
    stamp="$(date +%Y%m%d%H%M%S)"
    echo "Backing up existing $path to ${path}.bak.${stamp}"
    mv "$path" "${path}.bak.${stamp}"
  fi
}

clone_repo(){
  local url="$1"
  local dest="$2"
  local branch="${3:-}"

  echo "Cloning $url to $dest"
  if [[ -n "$branch" ]]; then
    git clone --depth 1 -b "$branch" "$url" "$dest"
  else
    git clone --depth 1 "$url" "$dest"
  fi
}

main(){
  parse_args "$@"
  require_git

  if [[ -d "$DEST" && -f "$DEST/.sbrc" && -f "$DEST/init.sh" ]]; then
    echo "Destination $DEST already contains sbrc. Skipping clone and running init.sh in-place."
  else
    if [[ -e "$DEST" ]]; then
      if [[ $FORCE_YES -eq 0 ]]; then
        read -p "Destination $DEST exists. Back up and overwrite? [y/N] " ans || true
        case "$ans" in
          y|Y|yes|Yes) backup_existing "$DEST" ;;
          *) echo "Cancelled."; exit 0 ;;
        esac
      else
        backup_existing "$DEST"
      fi

    fi

    # Allow cloning from a local path (file://) or remote URL
    clone_repo "$REPO_URL" "$DEST" "$BRANCH"
  fi

  # Run the bundled init script from the dest, forwarding -y if requested
  local init_sh="$DEST/init.sh"
  if [[ ! -x "$init_sh" && -f "$init_sh" ]]; then
    chmod +x "$init_sh"
  fi

  if [[ ! -f "$init_sh" ]]; then
    echo "Error: init.sh not found in $DEST" >&2
    exit 1
  fi

  echo "Running init.sh from $DEST"
  if [[ $FORCE_YES -eq 1 ]]; then
    HOME="$HOME" bash "$init_sh" -y
  else
    HOME="$HOME" bash "$init_sh"
  fi

  echo "Installation complete."
  echo "If you sourced the new file into your rc, you may need to restart your shell or source your rc file." 
}

main "$@"
