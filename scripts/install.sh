#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

TARGET="wrapper"
PROFILE="mv-t1"
SYNC=0

usage() {
  cat <<'EOF'
Usage: ./scripts/install.sh [--target wrapper|openclaw] [--profile mv-t1] [--sync]

Installs a Messy Virgo agent pack profile into a target OpenClaw instance.
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
    --sync)
      SYNC=1
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

PROFILE_ROOT="$ROOT_DIR/profiles/$PROFILE"
[[ -d "$PROFILE_ROOT" ]] || die "Profile not found: $PROFILE"

resolve_target_paths "$TARGET"
ensure_dirs
TS="$(date +%Y%m%d-%H%M%S)"

MANAGED_ROOT="$(managed_root_for_config "$CONFIG_DIR")"
MANAGED_ENTRY_REL="$PACK_MANAGED_ROOT/generated-$PROFILE.json"
MANAGED_ENTRY_PATH="$CONFIG_DIR/$MANAGED_ENTRY_REL"
MANIFEST_PATH="$(manifest_path_for_config "$CONFIG_DIR")"

mkdir -p "$MANAGED_ROOT"
mkdir -p "$MANAGED_ROOT/workspaces" "$MANAGED_ROOT/skills"

info "Installing profile '$PROFILE' into target '$TARGET'"

# Sync workspace templates into actual workspace dirs.
for agent_dir in "$PROFILE_ROOT/workspaces"/*/; do
  [[ -d "$agent_dir" ]] || continue
  agent_id="$(basename "$agent_dir")"
  target_dir="$WORKSPACES_DIR/$agent_id"
  mkdir -p "$target_dir"

  for src in "$agent_dir"*.md; do
    [[ -f "$src" ]] || continue
    file_name="$(basename "$src")"
    dst="$target_dir/$file_name"

    case "$file_name" in
      USER.md|MEMORY.md|IDENTITY.md|HEARTBEAT.md|TOOLS.md)
        copy_if_missing "$src" "$dst"
        ;;
      *)
        safe_sync_template_file "$src" "$dst" "$SYNC" "$TS"
        ;;
    esac
  done
done

# Copy skill packages to managed root for explicit ownership.
if [[ -d "$PROFILE_ROOT/skills" ]]; then
  cp -R "$PROFILE_ROOT/skills/." "$MANAGED_ROOT/skills/" 2>/dev/null || true
fi

runtime_mcporter="$PROFILE_ROOT/runtime/mcporter.json"
if [[ -f "$runtime_mcporter" ]]; then
  rendered_mcporter="$(mktemp)"
  python3 - "$runtime_mcporter" "$rendered_mcporter" <<'PY'
import os
import re
import sys
from pathlib import Path

src = Path(sys.argv[1])
dst = Path(sys.argv[2])
raw = src.read_text()

pattern = re.compile(r"\$\{([A-Z0-9_]+)\}")
required = sorted(set(pattern.findall(raw)))

missing = [name for name in required if os.environ.get(name, "") == ""]
if missing:
    print(
        "ERROR: Missing required environment variables for runtime template: "
        + ", ".join(missing),
        file=sys.stderr,
    )
    sys.exit(2)

rendered = raw
for name in required:
    rendered = rendered.replace("${" + name + "}", os.environ[name])

dst.write_text(rendered)
PY
  safe_sync_template_file "$rendered_mcporter" "$CONFIG_DIR/mcporter.json" "$SYNC" "$TS"
  rm -f "$rendered_mcporter"
  info "Rendered MCP runtime config: $CONFIG_DIR/mcporter.json"
fi

render_managed_pack_config "$PROFILE" "$CONFIG_DIR" "$MANAGED_ENTRY_PATH"
ensure_root_include_hook "$CONFIG_DIR" "$MANAGED_ENTRY_REL"

python3 - "$MANIFEST_PATH" "$PROFILE" "$MANAGED_ROOT" "$MANAGED_ENTRY_PATH" "$CONFIG_DIR/mcporter.json" "$WORKSPACES_DIR" "$PROFILE_ROOT/workspaces" <<'PY'
import json
import pathlib
import sys

manifest_path = pathlib.Path(sys.argv[1])
profile = sys.argv[2]
managed_root = pathlib.Path(sys.argv[3])
managed_entry = pathlib.Path(sys.argv[4])
mcporter_path = pathlib.Path(sys.argv[5])
workspaces_root = pathlib.Path(sys.argv[6])
profile_workspaces = pathlib.Path(sys.argv[7])

managed_files = []
for p in sorted(managed_root.rglob("*")):
    if p.is_file():
        managed_files.append(str(p))
if managed_entry.exists():
    managed_files.append(str(managed_entry))
if mcporter_path.exists():
    managed_files.append(str(mcporter_path))

workspace_files = []
for agent_dir in sorted(profile_workspaces.glob("*/")):
    agent_id = agent_dir.name
    for p in sorted(agent_dir.glob("*.md")):
        workspace_files.append(
            {
                "path": str(workspaces_root / agent_id / p.name),
                "stateful": p.name in {"USER.md", "MEMORY.md", "IDENTITY.md", "HEARTBEAT.md", "TOOLS.md"},
            }
        )

manifest = {
    "pack": "messyvirgo-openclaw-agents",
    "profile": profile,
    "managed_include_rel": f"packs/messyvirgo-openclaw-agents/generated-{profile}.json",
    "managed_files": managed_files,
    "workspace_files": workspace_files,
}

manifest_path.parent.mkdir(parents=True, exist_ok=True)
with manifest_path.open("w") as f:
    json.dump(manifest, f, indent=2)
    f.write("\n")
PY

info "Install complete."
info "Config dir: $CONFIG_DIR"
info "Workspaces dir: $WORKSPACES_DIR"
