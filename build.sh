#!/usr/bin/env bash
set -e

ALMIDE="${ALMIDE_BIN:-almide}"

# Find the .almd source file
ALMD_FILE=$(ls *.almd 2>/dev/null | head -1)
if [ -z "$ALMD_FILE" ]; then
  echo "Error: No .almd file found" >&2
  exit 1
fi

# Compile: .almd → .rs → minigit
"$ALMIDE" "$ALMD_FILE" --target rust > minigit.rs
rustc minigit.rs -o minigit
chmod +x minigit
echo "Built minigit from $ALMD_FILE"
