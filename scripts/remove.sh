#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

TARGET="wrapper"
PURGE_STATE=0

usage() {
  cat <<'EOF'
Usage: ./scripts/remove.sh [--target wrapper|openclaw] [--purge-state]

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

resolve_target_paths "$TARGET"
MANIFEST_PATH="$(manifest_path_for_config "$CONFIG_DIR")"
[[ -f "$MANIFEST_PATH" ]] || die "Manifest not found at $MANIFEST_PATH"

python3 - "$MANIFEST_PATH" "$PURGE_STATE" "$CONFIG_DIR/openclaw.json" <<'PY'
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

managed_root = manifest_path.parent
if managed_root.exists():
    # Remove empty directories only.
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

info "Pack-managed files removed from target '$TARGET'."
