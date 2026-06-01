#!/bin/bash
# install.sh — Install privacity system-wide
set -euo pipefail

SCRIPT="$(dirname "$0")/privacity"
TARGET="/usr/local/bin/privacity"

if [[ ! -f "$SCRIPT" ]]; then
  echo "Error: privacity script not found in $(dirname "$0")"
  exit 1
fi

echo "Installing privacity to $TARGET..."
sudo cp "$SCRIPT" "$TARGET"
sudo chmod 755 "$TARGET"
echo "Done! Run 'privacity' to start."
