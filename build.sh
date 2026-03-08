#!/usr/bin/env bash
set -e

# Find almide binary
ALMIDE="${ALMIDE_BIN:-}"
if [ -z "$ALMIDE" ]; then
  if command -v almide &>/dev/null; then
    ALMIDE="$(command -v almide)"
  elif [ -x "$HOME/.local/almide/almide" ]; then
    ALMIDE="$HOME/.local/almide/almide"
  else
    echo "Error: almide not found. Set ALMIDE_BIN or install to PATH." >&2
    exit 1
  fi
fi

# Find the .almd source file
ALMD_FILE=$(ls *.almd 2>/dev/null | head -1)
if [ -z "$ALMD_FILE" ]; then
  echo "Error: No .almd file found" >&2
  exit 1
fi

# Create wrapper script that uses `almide run`
cat > minigit <<WRAPPER
#!/usr/bin/env bash
DIR="\$(cd "\$(dirname "\$0")" && pwd)"
"$ALMIDE" run "\$DIR/$ALMD_FILE" "\$@"
WRAPPER
chmod +x minigit
echo "Built minigit from $ALMD_FILE (using almide run)"
