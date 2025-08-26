#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Ensure Xcode CLT
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Installing Command Line Tools..."
  xcode-select --install || true
  echo "Please rerun after CLT installation completes."
  exit 1
fi

# Build Swift helper
mkdir -p "$ROOT/bin"
xcrun swiftc "$ROOT/ocr/ocr_vision.swift" -o "$ROOT/bin/ocr_vision"

# Symlink to /usr/local/bin (may prompt for password)
sudo mkdir -p /usr/local/bin
sudo ln -sf "$ROOT/bin/ocr_vision" /usr/local/bin/ocr_vision

echo "✅ Installed ocr_vision to /usr/local/bin/ocr_vision"
echo "Next: In Photoshop, enable Preferences > Plugins > 'Allow Scripts to Write Files and Access Network'."