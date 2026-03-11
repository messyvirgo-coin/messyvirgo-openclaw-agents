#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

TARGET="wrapper"
PROFILE="mv-t1"

usage() {
  cat <<'EOF'
Usage: ./scripts/update.sh [--target wrapper|openclaw] [--profile mv-t1]

Updates managed pack files while preserving stateful workspace files.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="${2:-}"
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

resolve_target_paths "$TARGET"
"$SCRIPT_DIR/install.sh" --target "$TARGET" --profile "$PROFILE" --sync
