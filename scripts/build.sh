#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT/bin"
xcrun swiftc "$ROOT/ocr/ocr_vision.swift" -o "$ROOT/bin/ocr_vision"
echo "Built: $ROOT/bin/ocr_vision"