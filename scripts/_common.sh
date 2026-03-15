#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACK_SLUG="messyvirgo-openclaw-agents"
PACK_MANAGED_ROOT="packs/$PACK_SLUG"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

info() {
  echo "==> $*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing dependency: $1"
}

resolve_target_paths() {
  local target="$1"
  case "$target" in
    wrapper)
      CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw-secure}"
      WORKSPACES_DIR="${OPENCLAW_WORKSPACES_DIR:-$HOME/OpenClawWorkspaces}"
      ;;
    openclaw)
      CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}"
      WORKSPACES_DIR="${OPENCLAW_WORKSPACES_DIR:-$HOME/.openclaw/workspaces}"
      ;;
    *)
      die "Unknown target '$target' (expected wrapper|openclaw)"
      ;;
  esac
}

runtime_config_dir_for_target() {
  local target="$1"
  local host_config_dir="$2"
  case "$target" in
    wrapper)
      echo "/home/node/.openclaw"
      ;;
    openclaw)
      echo "$host_config_dir"
      ;;
    *)
      die "Unknown target '$target' (expected wrapper|openclaw)"
      ;;
  esac
}

managed_root_for_config() {
  local config_dir="$1"
  echo "$config_dir/$PACK_MANAGED_ROOT"
}

manifest_path_for_config() {
  local config_dir="$1"
  echo "$config_dir/$PACK_MANAGED_ROOT/manifest.json"
}

shared_manifest_path_for_config() {
  local config_dir="$1"
  echo "$config_dir/$PACK_MANAGED_ROOT/manifest-shared.json"
}

bundle_manifest_path_for_config() {
  local config_dir="$1"
  local bundle_key="$2"
  echo "$config_dir/$PACK_MANAGED_ROOT/manifests/bundle-$bundle_key.json"
}

shared_entry_rel_for_pack() {
  echo "$PACK_MANAGED_ROOT/generated-shared.json"
}

bundle_entry_rel_for_pack() {
  local bundle_key="$1"
  echo "$PACK_MANAGED_ROOT/generated-bundle-$bundle_key.json"
}

sanitize_bundle_key() {
  local raw="${1:-all}"
  local key
  key="$(echo "$raw" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9._-' '-')"
  key="${key#-}"
  key="${key%-}"
  if [[ -z "$key" ]]; then
    key="all"
  fi
  echo "$key"
}

ensure_dirs() {
  mkdir -p "$CONFIG_DIR" "$WORKSPACES_DIR"
}

copy_if_missing() {
  local src="$1"
  local dst="$2"
  if [[ ! -f "$dst" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    return
  fi
}

safe_sync_template_file() {
  local src="$1"
  local dst="$2"
  local sync_mode="$3"
  local ts="$4"
  if [[ ! -f "$dst" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    return
  fi
  if cmp -s "$src" "$dst"; then
    return
  fi
  if [[ "$sync_mode" == "1" ]]; then
    cp "$dst" "$dst.bak.$ts"
    cp "$src" "$dst"
  fi
}

render_shared_pack_config() {
  local fragment_dir="$1"
  local out_path="$2"
  local managed_skills_dir="$3"

  python3 - "$fragment_dir" "$out_path" "$managed_skills_dir" <<'PY'
import json
import pathlib
import sys

fragment_dir = pathlib.Path(sys.argv[1])
out_path = pathlib.Path(sys.argv[2])
managed_skills_dir = sys.argv[3]

cfg = {"$include": []}
parts = []
for p in sorted(fragment_dir.glob("*.json")):
    with p.open() as f:
        parts.append(json.load(f))

def deep_merge(left, right):
    if isinstance(left, dict) and isinstance(right, dict):
        out = dict(left)
        for k, v in right.items():
            if k in out:
                out[k] = deep_merge(out[k], v)
            else:
                out[k] = v
        return out
    if isinstance(left, list) and isinstance(right, list):
        return left + right
    return right

merged = {}
for part in parts:
    merged = deep_merge(merged, part)

skills = merged.setdefault("skills", {})
load = skills.setdefault("load", {})
extra_dirs = load.setdefault("extraDirs", [])
if managed_skills_dir not in extra_dirs:
    extra_dirs.append(managed_skills_dir)

out_path.parent.mkdir(parents=True, exist_ok=True)
with out_path.open("w") as f:
    json.dump(merged, f, indent=2)
    f.write("\n")
PY
}

render_agents_pack_config() {
  local registry_path="$1"
  local out_path="$2"
  local selected_ids_csv="${3:-}"

  python3 - "$registry_path" "$out_path" "$selected_ids_csv" <<'PY'
import json
import pathlib
import sys

registry_path = pathlib.Path(sys.argv[1])
out_path = pathlib.Path(sys.argv[2])
selected_csv = sys.argv[3]

registry = json.loads(registry_path.read_text())
agents = registry.get("agents", [])
if not isinstance(agents, list):
    print("ERROR: agents/registry.json must contain an 'agents' array", file=sys.stderr)
    sys.exit(2)

if selected_csv.strip():
    selected_ids = [x for x in selected_csv.split(",") if x]
else:
    selected_ids = [a.get("id") for a in agents if isinstance(a, dict) and a.get("id")]

selected_set = set(selected_ids)
selected_agents = [a for a in agents if isinstance(a, dict) and a.get("id") in selected_set]

missing = [agent_id for agent_id in selected_ids if agent_id not in {a.get("id") for a in selected_agents}]
if missing:
    print("ERROR: Unknown agent ids in selection: " + ", ".join(missing), file=sys.stderr)
    sys.exit(2)

out = {"agents": {"list": selected_agents}}
out_path.parent.mkdir(parents=True, exist_ok=True)
out_path.write_text(json.dumps(out, indent=2) + "\n")
PY
}

ensure_root_include_hook() {
  local config_dir="$1"
  local managed_entry_rel="$2"
  local root_path="$config_dir/openclaw.json"

  python3 - "$root_path" "$managed_entry_rel" <<'PY'
import json
import pathlib
import sys

root_path = pathlib.Path(sys.argv[1])
managed_rel = sys.argv[2]

if not root_path.exists():
    cfg = {"$include": [managed_rel]}
    with root_path.open("w") as f:
        json.dump(cfg, f, indent=2)
        f.write("\n")
    sys.exit(0)

raw = root_path.read_text()
try:
    cfg = json.loads(raw)
except Exception:
    print("WARN: openclaw.json is not strict JSON. Add this manually:", file=sys.stderr)
    print(f'  "$include": ["{managed_rel}"]', file=sys.stderr)
    sys.exit(0)

changed = False
inc = cfg.get("$include")
if inc is None:
    cfg["$include"] = [managed_rel]
    changed = True
elif isinstance(inc, str):
    if inc != managed_rel:
        cfg["$include"] = [inc, managed_rel]
        changed = True
elif isinstance(inc, list):
    if managed_rel not in inc:
        inc.append(managed_rel)
        cfg["$include"] = inc
        changed = True
else:
    print("WARN: Unsupported $include type in openclaw.json; add managed include manually.", file=sys.stderr)
    sys.exit(0)

if changed:
    with root_path.open("w") as f:
        json.dump(cfg, f, indent=2)
        f.write("\n")
PY
}
