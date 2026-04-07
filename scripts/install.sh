#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

BUNDLE=""
PROFILE=""
SYNC=0

usage() {
  cat <<'EOF'
Usage: ./scripts/install.sh [--bundle <name>] [--sync]

Installs shared runtime assets and agent workspace templates into the configured OpenClaw instance.
Set OPENCLAW_CONFIG_DIR / OPENCLAW_WORKSPACES_DIR (optional) to match your deployment; see .env.example.

  --sync  Overwrite files that already exist but differ from the pack:
          - native `mcp.servers` in generated shared pack config (resolved URLs/headers)
          - agent templates except USER.md, MEMORY.md, IDENTITY.md, HEARTBEAT.md
            (those are always "copy if missing" only, so local state is preserved)
          Without --sync, existing differing files are left unchanged (first-time copy only).

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

if [[ -n "$PROFILE" ]]; then
  if [[ -n "$BUNDLE" && "$BUNDLE" != "$PROFILE" ]]; then
    die "Use either --bundle or --profile (deprecated alias), not both"
  fi
  BUNDLE="$PROFILE"
fi

resolve_openclaw_paths
ensure_dirs

TS="$(date +%Y%m%d-%H%M%S)"

MANAGED_ROOT="$(managed_root_for_config "$CONFIG_DIR")"
SHARED_DIR="$MANAGED_ROOT/shared"
SHARED_SKILLS_DIR="$SHARED_DIR/skills"
SHARED_SKILLS_RUNTIME_DIR="~/.openclaw/$PACK_MANAGED_ROOT/shared/skills"
SHARED_ENTRY_REL="$(shared_entry_rel_for_pack)"
SHARED_ENTRY_PATH="$CONFIG_DIR/$SHARED_ENTRY_REL"
SHARED_MANIFEST_PATH="$(shared_manifest_path_for_config "$CONFIG_DIR")"

BUNDLE_NAME="${BUNDLE:-all}"
BUNDLE_KEY="$(sanitize_bundle_key "$BUNDLE_NAME")"
BUNDLE_ENTRY_REL="$(bundle_entry_rel_for_pack "$BUNDLE_KEY")"
BUNDLE_ENTRY_PATH="$CONFIG_DIR/$BUNDLE_ENTRY_REL"
BUNDLE_MANIFEST_PATH="$(bundle_manifest_path_for_config "$CONFIG_DIR" "$BUNDLE_KEY")"

RUNTIME_FRAGMENT_DIR="$ROOT_DIR/runtime/config-fragments"
AGENTS_REGISTRY="$ROOT_DIR/agents/registry.json"
AGENTS_ROOT="$ROOT_DIR/agents"
BUNDLES_ROOT="$ROOT_DIR/bundles"
SKILLS_SOURCE_DIR="$ROOT_DIR/skills"

[[ -d "$RUNTIME_FRAGMENT_DIR" ]] || die "Missing runtime fragments directory: $RUNTIME_FRAGMENT_DIR"
[[ -f "$AGENTS_REGISTRY" ]] || die "Missing agents registry: $AGENTS_REGISTRY"

mkdir -p "$MANAGED_ROOT"
mkdir -p "$SHARED_DIR" "$(dirname "$BUNDLE_MANIFEST_PATH")" "$(dirname "$SHARED_ENTRY_PATH")" "$(dirname "$BUNDLE_ENTRY_PATH")"

if [[ -n "$BUNDLE" ]]; then
  bundle_path="$BUNDLES_ROOT/$BUNDLE.json"
  [[ -f "$bundle_path" ]] || die "Bundle not found: $BUNDLE"
  info "Installing bundle '$BUNDLE'"
else
  bundle_path=""
  info "Installing all agents"
fi

selected_ids_csv="$(python3 - "$AGENTS_REGISTRY" "$bundle_path" <<'PY'
import json
import pathlib
import sys

registry_path = pathlib.Path(sys.argv[1])
bundle_path = pathlib.Path(sys.argv[2]) if sys.argv[2] else None

registry = json.loads(registry_path.read_text())
agents = registry.get("agents", [])
agent_ids = [a.get("id") for a in agents if isinstance(a, dict) and a.get("id")]
known = set(agent_ids)

if bundle_path:
    bundle = json.loads(bundle_path.read_text())
    selected = bundle.get("agents", [])
    if not isinstance(selected, list):
        print("ERROR: bundle file must contain an 'agents' array", file=sys.stderr)
        sys.exit(2)
    selected_ids = []
    for item in selected:
        if not isinstance(item, str):
            print("ERROR: bundle agent entries must be strings", file=sys.stderr)
            sys.exit(2)
        selected_ids.append(item)
else:
    selected_ids = agent_ids

missing = [agent_id for agent_id in selected_ids if agent_id not in known]
if missing:
    print("ERROR: bundle references unknown agent ids: " + ", ".join(missing), file=sys.stderr)
    sys.exit(2)

print(",".join(selected_ids))
PY
)"

if [[ -d "$SKILLS_SOURCE_DIR" ]]; then
  rm -rf "$SHARED_SKILLS_DIR"
  mkdir -p "$SHARED_SKILLS_DIR"
  cp -R "$SKILLS_SOURCE_DIR/." "$SHARED_SKILLS_DIR/" 2>/dev/null || true
fi

render_shared_pack_config "$RUNTIME_FRAGMENT_DIR" "$SHARED_ENTRY_PATH" "$SHARED_SKILLS_RUNTIME_DIR"

# Native OpenClaw MCP (`mcp.servers`) must use real http(s) URLs after env substitution.
# A literal "${VAR}" in JSON fails Zod validation (`mcp.servers.*.url` uses z.string().url())
# and can prevent the gateway from starting. Inject resolved values here.
python3 - "$SHARED_ENTRY_PATH" <<'PY'
import json
import os
import sys
from pathlib import Path
from urllib.parse import urlparse

path = Path(sys.argv[1])
if not path.exists():
    print(f"ERROR: shared pack config missing: {path}", file=sys.stderr)
    sys.exit(2)

url = os.environ.get("MESSY_VIRGO_MCP_URL", "").strip()
api_key = os.environ.get("MESSY_VIRGO_API_KEY", "").strip()
missing = []
if not url:
    missing.append("MESSY_VIRGO_MCP_URL")
if not api_key:
    missing.append("MESSY_VIRGO_API_KEY")
if missing:
    print(
        "ERROR: Missing required environment variables for native MCP (mcp.servers): "
        + ", ".join(missing),
        file=sys.stderr,
    )
    sys.exit(2)

parsed = urlparse(url)
if parsed.scheme not in ("http", "https") or not parsed.netloc:
    print(f"ERROR: MESSY_VIRGO_MCP_URL is not a valid http(s) URL: {url!r}", file=sys.stderr)
    sys.exit(2)

# Canonicalize to a slash-terminated endpoint to avoid auth/header loss on redirects
# (some HTTP clients do not preserve Authorization across 30x follow-ups).
if not parsed.path:
    parsed = parsed._replace(path="/")
elif not parsed.path.endswith("/"):
    parsed = parsed._replace(path=parsed.path + "/")
url = parsed.geturl()

cfg = json.loads(path.read_text())
mcp = cfg.setdefault("mcp", {})
servers = mcp.setdefault("servers", {})
servers["messy-virgo-funds"] = {
    "url": url,
    "transport": "streamable-http",
    "headers": {"Authorization": f"Bearer {api_key}"},
}
path.write_text(json.dumps(cfg, indent=2) + "\n")
PY
info "Wrote native OpenClaw MCP server to $SHARED_ENTRY_PATH (messy-virgo-funds)"

render_agents_pack_config "$AGENTS_REGISTRY" "$BUNDLE_ENTRY_PATH" "$selected_ids_csv"
ensure_root_include_hook "$CONFIG_DIR" "$SHARED_ENTRY_REL"
ensure_root_include_hook "$CONFIG_DIR" "$BUNDLE_ENTRY_REL"

IFS=',' read -r -a selected_ids <<< "$selected_ids_csv"
for agent_id in "${selected_ids[@]}"; do
  source_dir="$AGENTS_ROOT/$agent_id"
  [[ -d "$source_dir" ]] || die "Missing template directory for agent '$agent_id': $source_dir"
  target_dir="$WORKSPACES_DIR/$agent_id"
  mkdir -p "$target_dir"

  for src in "$source_dir"/*.md "$source_dir"/soul.json; do
    [[ -f "$src" ]] || continue
    file_name="$(basename "$src")"
    dst="$target_dir/$file_name"

    case "$file_name" in
      USER.md|MEMORY.md|IDENTITY.md|HEARTBEAT.md)
        copy_if_missing "$src" "$dst"
        ;;
      *)
        safe_sync_template_file "$src" "$dst" "$SYNC" "$TS"
        ;;
    esac
  done

  avatar_src="$source_dir/avatar.png"
  if [[ -f "$avatar_src" ]]; then
    safe_sync_template_file "$avatar_src" "$target_dir/avatar.png" "$SYNC" "$TS"
  fi
done

python3 - "$SHARED_MANIFEST_PATH" "$SHARED_DIR" "$SHARED_ENTRY_PATH" "$SHARED_ENTRY_REL" <<'PY'
import json
import pathlib
import sys

manifest_path = pathlib.Path(sys.argv[1])
shared_dir = pathlib.Path(sys.argv[2])
shared_entry = pathlib.Path(sys.argv[3])
shared_rel = sys.argv[4]

managed_files = []
for p in sorted(shared_dir.rglob("*")):
    if p.is_file():
        managed_files.append(str(p))
if shared_entry.exists():
    managed_files.append(str(shared_entry))

manifest = {
    "pack": "messyvirgo-openclaw-agents",
    "scope": "shared",
    "managed_include_rel": shared_rel,
    "managed_files": managed_files,
    "workspace_files": [],
}

manifest_path.parent.mkdir(parents=True, exist_ok=True)
manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
PY

python3 - "$BUNDLE_MANIFEST_PATH" "$BUNDLE_KEY" "$BUNDLE_NAME" "$BUNDLE_ENTRY_PATH" "$BUNDLE_ENTRY_REL" "$WORKSPACES_DIR" "$AGENTS_ROOT" "$selected_ids_csv" <<'PY'
import json
import pathlib
import sys

manifest_path = pathlib.Path(sys.argv[1])
bundle_key = sys.argv[2]
bundle_name = sys.argv[3]
bundle_entry = pathlib.Path(sys.argv[4])
bundle_rel = sys.argv[5]
workspaces_root = pathlib.Path(sys.argv[6])
agents_root = pathlib.Path(sys.argv[7])
selected_ids_csv = sys.argv[8]

selected_ids = [x for x in selected_ids_csv.split(",") if x]

workspace_files = []
for agent_id in selected_ids:
    source_dir = agents_root / agent_id
    files = list(source_dir.glob("*.md"))
    soul_json = source_dir / "soul.json"
    if soul_json.exists():
        files.append(soul_json)
    avatar_png = source_dir / "avatar.png"
    if avatar_png.is_file():
        files.append(avatar_png)
    for p in sorted(files):
        workspace_files.append(
            {
                "path": str(workspaces_root / agent_id / p.name),
                "stateful": p.name in {"USER.md", "MEMORY.md", "IDENTITY.md", "HEARTBEAT.md"},
            }
        )

managed_files = []
if bundle_entry.exists():
    managed_files.append(str(bundle_entry))

manifest = {
    "pack": "messyvirgo-openclaw-agents",
    "scope": "bundle",
    "bundle_key": bundle_key,
    "bundle_name": bundle_name,
    "managed_include_rel": bundle_rel,
    "managed_files": managed_files,
    "workspace_files": workspace_files,
}

manifest_path.parent.mkdir(parents=True, exist_ok=True)
manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
PY

info "Install complete."
info "Config dir: $CONFIG_DIR"
info "Workspaces dir: $WORKSPACES_DIR"
