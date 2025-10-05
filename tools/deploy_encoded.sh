#!/usr/bin/env bash
set -euo pipefail
ROOT="/workspaces/fivem"
SRC="$ROOT/dist-resources"
DST="$ROOT/fxserver/resources"
BACKUP="$ROOT/.encoded_backup_once"

if [ ! -d "$SRC" ]; then
  echo "Encoded resources not found at $SRC; run encoder first." >&2
  exit 1
fi

mkdir -p "$DST"

if [ ! -d "$BACKUP" ]; then
  echo "Creating one-time backup of original pt-* resources..."
  mkdir -p "$BACKUP"
  find "$DST" -maxdepth 1 -type d -name 'pt-*' -print0 | xargs -0 -I{} cp -a {} "$BACKUP" || true
fi

echo "Deploying encoded pt-* resources to $DST..."
# Only sync pt-* resources and do not delete non-pt resources in DST
shopt -s nullglob
for dir in "$SRC"/pt-*; do
  name="$(basename "$dir")"
  rsync -a --delete "$dir/" "$DST/$name/"
done
shopt -u nullglob

echo "Done. Encoded resources deployed."
