#target photoshop
(function () {
    // -------- CONFIG (tweak to taste) --------
    var OCR_BIN = "/usr/local/bin/ocr_vision";   // compiled Swift helper
    var TMP_IN  = "/tmp/plate.png";
    var TMP_OUT = "/tmp/text_mask.png";

    var LANGS   = "en-US";   // e.g., "en-US,fr-FR"
    var MIN_TXT = "0.004";   // smaller finds smaller copy (try 0.006..0.002)

    var EXPAND_PX  = 4;      // grow selection to cover glyph edges
    var FEATHER_PX = 1.2;    // soften selection for smoother manual retouch

    var OVERLAY    = false;  // true = paint a faint QC overlay on a new layer
    var LEAVE_SELECTION_ACTIVE = true; // leave selection active for your Action
    var DEBUG_SAVE = false;  // save a copy of the raw mask for QC
    var DEBUG_DIR  = Folder("~/ps-auto-blank/debug");
    var SHOW_ALERT = false;  // set true if you want a completion alert

    if (!app.documents.length) { if (SHOW_ALERT) alert("Open a document first."); return; }
    if (!(new File(OCR_BIN)).exists) {
        if (SHOW_ALERT) alert("OCR helper not found at:\n" + OCR_BIN + "\nRun scripts/install.sh");
        return;
    }

    var doc = app.activeDocument;

    // Export flattened temp plate for OCR
    function exportTempPNG(path) {
        var dup = doc.duplicate();
        dup.flatten();
        var opt = new PNGSaveOptions(); opt.interlaced = false;
        dup.saveAs(new File(path), opt, true, Extension.LOWERCASE);
        dup.close(SaveOptions.DONOTSAVECHANGES);
    }

    // Reset to composite channel (fixes "Array expected" issues)
    function resetCompositeChannels() {
        try {
            switch (doc.mode) {
                case DocumentMode.RGB:       doc.activeChannels = [doc.channels.getByName("RGB")]; break;
                case DocumentMode.CMYK:      doc.activeChannels = [doc.channels.getByName("CMYK")]; break;
                case DocumentMode.GRAYSCALE: doc.activeChannels = [doc.channels.getByName("Gray")]; break;
                case DocumentMode.LAB:       doc.activeChannels = [doc.channels.getByName("Lab")]; break;
                default:                     doc.activeChannels = [doc.channels[0]];
            }
        } catch (e) { /* ignore */ }
    }

    exportTempPNG(TMP_IN);

    // Run Apple Vision OCR -> mask
    var cmd = OCR_BIN + " " + TMP_IN + " " + TMP_OUT + " " + LANGS + " " + MIN_TXT;
    try { app.system(cmd); } catch (e) { if (SHOW_ALERT) alert("Failed to call OCR helper:\n" + e); return; }

    var maskFile = new File(TMP_OUT);
    if (!maskFile.exists) {
        if (SHOW_ALERT) alert("No mask produced. Lower MIN_TXT or increase contrast.");
        return;
    }

    // Bring mask in as an alpha channel
    var mDoc = app.open(maskFile);
    mDoc.selection.selectAll(); mDoc.selection.copy();
    mDoc.close(SaveOptions.DONOTSAVECHANGES);

    var alpha = doc.channels.add();
    alpha.name = "AUTO_TEXT_MASK";
    doc.activeChannels = [alpha];
    doc.paste();

    // Load as selection
    doc.selection.deselect();
    doc.selection.load(alpha, SelectionType.REPLACE);

    // If empty selection, bail gracefully
    try { var _ = doc.selection.bounds; } catch(e) {
        resetCompositeChannels();
        if (SHOW_ALERT) alert("Mask was empty.");
        return;
    }

    // Pad/soften edges for nicer manual retouch
    if (EXPAND_PX  > 0) doc.selection.expand(EXPAND_PX);
    if (FEATHER_PX > 0) doc.selection.feather(FEATHER_PX);

    // Optional translucent overlay for quick QC
    if (OVERLAY) {
        var qc = doc.artLayers.add();
        qc.name = "QC—Text Mask";
        qc.opacity = 30; qc.blendMode = BlendMode.MULTIPLY;
        doc.selection.fill(app.foregroundColor);
    }

    // Optional: archive the raw mask for QC
    if (DEBUG_SAVE) {
        try {
            if (!DEBUG_DIR.exists) DEBUG_DIR.create();
            var base = doc.name.replace(/\.[^\.]+$/, "");
            var ts   = (new Date().getTime());
            maskFile.copy(DEBUG_DIR.fsName + "/" + base + "-" + ts + ".png");
        } catch (e) { /* ignore */ }
    }

    if (!LEAVE_SELECTION_ACTIVE) doc.selection.deselect();
    resetCompositeChannels();

    if (SHOW_ALERT) alert("Mask ready → channel 'AUTO_TEXT_MASK' created" +
                          (LEAVE_SELECTION_ACTIVE ? " and selection active." : "."));
})();