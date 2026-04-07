#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

BUNDLE=""
PROFILE=""

usage() {
  cat <<'EOF'
Usage: ./scripts/update.sh [--bundle <name>]

Updates managed pack files while preserving stateful workspace files.
Defaults to all agents when --bundle is not provided.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bundle)
      BUNDLE="${2:-}"
      shift 2
      ;;
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

if [[ -n "$PROFILE" ]]; then
  if [[ -n "$BUNDLE" && "$BUNDLE" != "$PROFILE" ]]; then
    die "Use either --bundle or --profile (deprecated alias), not both"
  fi
  BUNDLE="$PROFILE"
fi

if [[ -n "$BUNDLE" ]]; then
  "$SCRIPT_DIR/install.sh" --bundle "$BUNDLE" --sync
else
  "$SCRIPT_DIR/install.sh" --sync
fi
