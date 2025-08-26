# Photoshop Text Removal

Automated text detection and masking for product photography retouching using Apple Vision OCR.

## Overview

This project combines Apple's Vision framework with Photoshop scripting to automatically detect and mask text in product photography. Perfect for e-commerce retouching workflows where you need to remove product labels, ingredients lists, or other text elements.

**Features:**
- Apple Vision OCR for accurate text detection
- Automatic mask generation with proper coordinate system handling
- Configurable selection expansion and feathering
- Leaves active selection for your Photoshop Actions to process
- Debug and QC options for fine-tuning

## Prerequisites
- macOS (Apple Silicon recommended)
- Adobe Photoshop 2024/2025
- Xcode Command Line Tools (`xcode-select --install`)

## Installation
```bash
git clone https://github.com/liampgordon/photoshop-text-removal.git
cd photoshop-text-removal
./scripts/install.sh
```

Then in Photoshop: **Preferences → Plugins → Allow Scripts to Write Files and Access Network**

## Usage

1. Open your product image in Photoshop
2. Run the script via:
   - **Menu:** File → Scripts → Browse… → select `jsx/AutoBlank.jsx`
   - **CLI:** `./scripts/run_photoshop_jsx.sh`

The script will:
- Export a flattened version for OCR processing
- Detect text using Apple Vision
- Create an `AUTO_TEXT_MASK` channel
- Leave an active selection ready for your retouching workflow

## Tuning

Edit `jsx/AutoBlank.jsx`:

- `MIN_TXT`: lower (e.g., 0.004) to pick smaller text, higher (e.g., 0.012) to be stricter.
- `EXPAND_PX` / `FEATHER_PX`: edge coverage for cleaner fills.
- `LANGS`: comma-separated language hints (e.g., "en-US,fr-FR").

## Troubleshooting

- **"OCR helper not found"**: run `./scripts/install.sh` to build/symlink.
- **"No mask produced"**: lower `MIN_TXT`, increase image contrast, or zoom to the label and try again.
- **Permission issues**: ensure Photoshop scripting preference above is enabled.
- **Photoshop version string** in `run_photoshop_jsx.sh` may need to match your installed app ("Adobe Photoshop 2024").
