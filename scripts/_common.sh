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

managed_root_for_config() {
  local config_dir="$1"
  echo "$config_dir/$PACK_MANAGED_ROOT"
}

manifest_path_for_config() {
  local config_dir="$1"
  echo "$config_dir/$PACK_MANAGED_ROOT/manifest.json"
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

render_managed_pack_config() {
  local profile="$1"
  local config_dir="$2"
  local out_path="$3"
  local fragment_dir="$ROOT_DIR/profiles/$profile/config-fragments"
  local managed_skills_dir="$config_dir/$PACK_MANAGED_ROOT/skills"

  python3 - "$fragment_dir" "$out_path" "$managed_skills_dir" <<'PY'
import json
import os
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
