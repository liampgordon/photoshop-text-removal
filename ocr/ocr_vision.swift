import Foundation
import Vision
import AppKit

func loadCGImage(_ path:String) -> CGImage? {
    guard let img = NSImage(contentsOfFile: path) else { return nil }
    var rect = NSRect(origin: .zero, size: img.size)
    return img.cgImage(forProposedRect: &rect, context: nil, hints: nil)
}

guard CommandLine.arguments.count >= 3 else {
    fputs("usage: ocr_vision <in.png> <out_mask.png> [langHints comma] [minTextHeight 0.0-1.0]\n", stderr)
    exit(2)
}
let inPath = CommandLine.arguments[1]
let outPath = CommandLine.arguments[2]
let langHints = CommandLine.arguments.count > 3 ? CommandLine.arguments[3].split(separator: ",").map(String.init) : ["en-US"]
let minTextHeight = CommandLine.arguments.count > 4 ? (Double(CommandLine.arguments[4]) ?? 0.008) : 0.008

guard let cg = loadCGImage(inPath) else { exit(3) }
let w = Int(CGFloat(cg.width)), h = Int(CGFloat(cg.height))

let req = VNRecognizeTextRequest()
req.recognitionLanguages = langHints
req.recognitionLevel = .accurate
req.usesLanguageCorrection = false
req.minimumTextHeight = Float(minTextHeight)

let handler = VNImageRequestHandler(cgImage: cg, options: [:])
try? handler.perform([req])

let colorSpace = CGColorSpaceCreateDeviceGray()
let bytesPerRow = w
var buffer = [UInt8](repeating: 0, count: w*h)

if let results = req.results {
    for obs in results {
        guard obs.confidence > 0.35 else { continue }
        let r = obs.boundingBox
        var x = Int(r.origin.x * CGFloat(w))
        var y = Int(r.origin.y * CGFloat(h))
        var bw = Int(r.size.width  * CGFloat(w))
        var bh = Int(r.size.height * CGFloat(h))
        x = max(0, min(w-1, x)); y = max(0, min(h-1, y))
        bw = max(1, min(w-x, bw)); bh = max(1, min(h-y, bh))
        for yy in y..<y+bh {
            let row = yy*bytesPerRow
            for xx in x..<x+bw {
                buffer[row+xx] = 255
            }
        }
    }
}

func dilate(_ buf: inout [UInt8], _ w:Int, _ h:Int, _ r:Int) {
    var out = buf
    let rr = max(1,r)
    for y in 0..<h {
        for x in 0..<w {
            if buf[y*w+x] > 0 {
                for yy in max(0,y-rr)...min(h-1,y+rr) {
                    for xx in max(0,x-rr)...min(w-1,x+rr) {
                        out[yy*w+xx] = 255
                    }
                }
            }
        }
    }
    buf = out
}

// Flip vertically so Vision's bottom-left origin matches Photoshop's top-left
var flipped = [UInt8](repeating: 0, count: w*h)
for y in 0..<h {
    let srcRow = y * w
    let dstRow = (h - 1 - y) * w
    for x in 0..<w {
        flipped[dstRow + x] = buffer[srcRow + x]
    }
}
buffer = flipped

dilate(&buffer, w, h, 2)

if let ctx = CGContext(data: &buffer, width: w, height: h, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: 0),
   let outCG = ctx.makeImage() {
    let rep = NSBitmapImageRep(cgImage: outCG)
    if let data = rep.representation(using: .png, properties: [:]) {
        try? data.write(to: URL(fileURLWithPath: outPath))
        exit(0)
    }
}
exit(5)