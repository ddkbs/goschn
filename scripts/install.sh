#!/bin/bash
# Builds Rüber, copies it to /Applications and starts it.
set -euo pipefail
cd "$(dirname "$0")/.."

scripts/build.sh
pkill -x Rueber 2>/dev/null && sleep 1 || true
rm -rf "/Applications/Rüber.app"
cp -R "build/Rüber.app" /Applications/
open "/Applications/Rüber.app"
echo "Installed. Press ⇧⌘Space to translate."
