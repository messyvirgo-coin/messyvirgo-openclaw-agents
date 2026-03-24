#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

TARGET="secure"
CHANNEL="telegram"
AGENT_ID="mv-t1-mngr"
CLIENT_REPO="${CLIENT_REPO:-$HOME/Git/messyvirgo-openclaw-client}"
TOKEN=""
TOKEN_FILE=""
USE_ENV=0

usage() {
  cat <<'EOF'
Usage: ./scripts/setup-agent-channel.sh [options]

Generic channel setup helper for pack-managed agents.

Options:
  --target secure|raw   Runtime mode (default: secure)
  --channel <name>            Channel id (default: telegram)
  --agent <id>                Agent id to bind (default: mv-t1-mngr)
  --client-repo <path>        Path to messyvirgo-openclaw-client repo (contains openclaw-secure/ and openclaw-raw/)
  --token <token>             Inline token for channels add
  --token-file <path>         Token file path (if channel supports it)
  --use-env                   Use env-based token resolution
  -h, --help                  Show help

Examples:
  ./scripts/setup-agent-channel.sh --agent mv-t1-mngr
  ./scripts/setup-agent-channel.sh --agent mv-t1-mngr --token "$TELEGRAM_BOT_TOKEN"
  ./scripts/setup-agent-channel.sh --target raw --agent mv-t1-mngr --use-env
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    --channel)
      CHANNEL="${2:-}"
      shift 2
      ;;
    --agent)
      AGENT_ID="${2:-}"
      shift 2
      ;;
    --client-repo)
      CLIENT_REPO="${2:-}"
      shift 2
      ;;
    --token)
      TOKEN="${2:-}"
      shift 2
      ;;
    --token-file)
      TOKEN_FILE="${2:-}"
      shift 2
      ;;
    --use-env)
      USE_ENV=1
      shift
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

[[ -n "$AGENT_ID" ]] || die "--agent is required"
[[ -n "$CHANNEL" ]] || die "--channel is required"

if [[ -n "$TOKEN" && -n "$TOKEN_FILE" ]]; then
  die "Use either --token or --token-file, not both"
fi
if [[ "$USE_ENV" == "1" && ( -n "$TOKEN" || -n "$TOKEN_FILE" ) ]]; then
  die "--use-env cannot be combined with --token/--token-file"
fi

# Resolve CLI: secure -> openclaw-secure; raw -> openclaw-raw if present, else openclaw
case "$TARGET" in
  secure)
    CLI_PATH="$CLIENT_REPO/openclaw-secure/scripts/cli.sh"
    [[ -x "$CLI_PATH" ]] || die "Missing secure CLI at $CLI_PATH"
    ;;
  raw)
    if [[ -x "$CLIENT_REPO/openclaw-raw/scripts/cli.sh" ]]; then
      CLI_PATH="$CLIENT_REPO/openclaw-raw/scripts/cli.sh"
    else
      CLI_PATH="openclaw"
      require_cmd openclaw
    fi
    ;;
  *)
    die "Unknown target '$TARGET' (expected secure|raw)"
    ;;
esac

run_cli() {
  if [[ "$CLI_PATH" == "openclaw" ]]; then
    openclaw "$@"
  else
    "$CLI_PATH" "$@"
  fi
}

build_channel_add_args() {
  local args=()
  args+=("channels" "add" "--channel" "$CHANNEL")
  if [[ "$USE_ENV" == "1" ]]; then
    args+=("--use-env")
  elif [[ -n "$TOKEN" ]]; then
    args+=("--token" "$TOKEN")
  elif [[ -n "$TOKEN_FILE" ]]; then
    args+=("--token-file" "$TOKEN_FILE")
  fi
  printf '%s\n' "${args[@]}"
}

info "Adding channel account ($CHANNEL)"
mapfile -t add_args < <(build_channel_add_args)
run_cli "${add_args[@]}"

info "Binding channel '$CHANNEL' to agent '$AGENT_ID'"
run_cli agents bind --agent "$AGENT_ID" --bind "$CHANNEL"

cat <<EOF

Done.

Next steps:
  1) Verify binding:
       $CLI_PATH agents bindings

  2) Approve first-time DM pairing:
       $CLI_PATH pairing list $CHANNEL
       $CLI_PATH pairing approve $CHANNEL <CODE>
EOF
