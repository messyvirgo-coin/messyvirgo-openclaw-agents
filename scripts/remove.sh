#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

TARGET="secure"
PURGE_STATE=0
BUNDLE=""
PROFILE=""

usage() {
  cat <<'EOF'
Usage: ./scripts/remove.sh [--target secure|raw] [--bundle <name>] [--purge-state]

Removes files managed by this pack. Stateful workspace files are preserved unless
--purge-state is explicitly set.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    --bundle)
      BUNDLE="${2:-}"
      shift 2
      ;;
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    --purge-state)
      PURGE_STATE=1
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

resolve_target_paths "$TARGET"

SHARED_MANIFEST_PATH="$(shared_manifest_path_for_config "$CONFIG_DIR")"
BUNDLES_MANIFEST_DIR="$CONFIG_DIR/$PACK_MANAGED_ROOT/manifests"
ROOT_CONFIG_PATH="$CONFIG_DIR/openclaw.json"

remove_manifest() {
  local manifest_path="$1"
  [[ -f "$manifest_path" ]] || return 0
  python3 - "$manifest_path" "$PURGE_STATE" "$ROOT_CONFIG_PATH" <<'PY'
import json
import pathlib
import sys

manifest_path = pathlib.Path(sys.argv[1])
purge_state = sys.argv[2] == "1"
root_config_path = pathlib.Path(sys.argv[3])
manifest = json.loads(manifest_path.read_text())

for p in manifest.get("managed_files", []):
    fp = pathlib.Path(p)
    if fp.exists() and fp.is_file():
        fp.unlink()

for item in manifest.get("workspace_files", []):
    path = pathlib.Path(item["path"])
    stateful = bool(item.get("stateful"))
    if stateful and not purge_state:
        continue
    if path.exists() and path.is_file():
        path.unlink()

managed_rel = manifest.get("managed_include_rel")
if managed_rel and root_config_path.exists():
    try:
        root_cfg = json.loads(root_config_path.read_text())
    except Exception:
        root_cfg = None
    if isinstance(root_cfg, dict):
        inc = root_cfg.get("$include")
        changed = False
        if isinstance(inc, str) and inc == managed_rel:
            root_cfg.pop("$include", None)
            changed = True
        elif isinstance(inc, list) and managed_rel in inc:
            root_cfg["$include"] = [x for x in inc if x != managed_rel]
            changed = True
        if changed:
            root_config_path.write_text(json.dumps(root_cfg, indent=2) + "\n")

if manifest_path.exists():
    manifest_path.unlink()
PY
}

if [[ -n "$BUNDLE" ]]; then
  bundle_key="$(sanitize_bundle_key "$BUNDLE")"
  bundle_manifest_path="$(bundle_manifest_path_for_config "$CONFIG_DIR" "$bundle_key")"
  [[ -f "$bundle_manifest_path" ]] || die "Bundle manifest not found: $bundle_manifest_path"
  remove_manifest "$bundle_manifest_path"
  info "Bundle '$BUNDLE' removed from target '$TARGET'. Shared assets were left intact."
else
  if [[ -d "$BUNDLES_MANIFEST_DIR" ]]; then
    for manifest in "$BUNDLES_MANIFEST_DIR"/*.json; do
      [[ -f "$manifest" ]] || continue
      remove_manifest "$manifest"
    done
  fi
  remove_manifest "$SHARED_MANIFEST_PATH"
  info "All pack-managed files removed from target '$TARGET'."
fi

python3 - "$CONFIG_DIR/$PACK_MANAGED_ROOT" <<'PY'
import pathlib
import sys

managed_root = pathlib.Path(sys.argv[1])
if not managed_root.exists():
    sys.exit(0)

for d in sorted(managed_root.rglob("*"), reverse=True):
    if d.is_dir():
        try:
            d.rmdir()
        except OSError:
            pass
try:
    managed_root.rmdir()
except OSError:
    pass
PY
