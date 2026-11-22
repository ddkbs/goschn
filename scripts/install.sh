#!/bin/bash
# Builds Goschn, copies it to /Applications and starts it.
set -euo pipefail
cd "$(dirname "$0")/.."

scripts/build.sh
pkill -x Goschn 2>/dev/null && sleep 1 || true
rm -rf "/Applications/Goschn.app"
cp -R "build/Goschn.app" /Applications/
open "/Applications/Goschn.app"
echo "Installed. Press ⇧⌘Space to translate."
