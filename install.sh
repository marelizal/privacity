#!/bin/bash
# install.sh — Install privacity system-wide
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="/usr/local/bin/privacity"
LIBDIR="/usr/local/lib/privacity"
LIBS="lib/common.sh lib/net.sh lib/speed.sh lib/csv.sh lib/ovpn.sh"

if [[ ! -f "$DIR/privacity" ]]; then
  echo "Error: privacity script not found in $DIR"
  exit 1
fi

echo "Installing privacity to $TARGET..."
sudo cp "$DIR/privacity" "$TARGET"
sudo chmod 755 "$TARGET"

echo "Installing lib modules to $LIBDIR/..."
sudo mkdir -p "$LIBDIR"
pushd "$DIR" >/dev/null
sudo cp $LIBS "$LIBDIR/"
popd >/dev/null

echo "Done! Run 'privacity' to start."
