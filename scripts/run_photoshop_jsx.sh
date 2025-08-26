#!/usr/bin/env bash
set -euo pipefail
JSX_PATH="$HOME/ps-auto-blank/jsx/AutoBlank.jsx"
APP_NAME="Adobe Photoshop 2025"

if [ ! -f "$JSX_PATH" ]; then
  echo "JSX not found at $JSX_PATH"
  exit 1
fi

/usr/bin/osascript <<EOF
tell application "$APP_NAME"
  activate
  do javascript file "$JSX_PATH"
end tell
EOF