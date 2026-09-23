#!/usr/bin/env swift
// Package ImageGen originals. Pixel world and high-resolution close-ups use separate export paths.
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let art = root.appendingPathComponent("art/yard")
let source = art.appendingPathComponent("source")
let catalog = root.appendingPathComponent("ios/Ivy/Assets.xcassets")
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
var manifest: [[String: Any]] = []

func context(_ width: Int, _ height: Int, smooth: Bool = false) -> CGContext {
    let c = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                      bytesPerRow: width * 4, space: colorSpace,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.interpolationQuality = smooth ? .high : .none
    c.setShouldAntialias(smooth)
    return c
}

func load(_ name: String) -> CGImage {
    let url = source.appendingPathComponent(name + ".png")
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
        fatalError("Missing source: \(url.path)")
    }
    return image
}

func trim(_ image: CGImage) -> CGImage {
    let c = context(image.width, image.height)
    c.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    let bytes = c.data!.assumingMemoryBound(to: UInt8.self)
    var x0 = image.width, y0 = image.height, x1 = 0, y1 = 0
    for y in 0..<image.height {
        for x in 0..<image.width where bytes[(y * image.width + x) * 4 + 3] > 32 {
            x0 = min(x0, x); y0 = min(y0, y); x1 = max(x1, x); y1 = max(y1, y)
        }
    }
    precondition(x0 <= x1 && y0 <= y1, "Empty sprite")
    return image.cropping(to: CGRect(x: x0, y: y0, width: x1 - x0 + 1, height: y1 - y0 + 1))!
}

func resize(_ image: CGImage, _ width: Int, _ height: Int, smooth: Bool = false) -> CGImage {
    let c = context(width, height, smooth: smooth)
    c.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return c.makeImage()!
}

func png(_ image: CGImage, _ url: URL) throws {
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    precondition(CGImageDestinationFinalize(dest), "PNG export failed")
}

func export(name: String, group: String, width: Int, height: Int, frames: Int = 1,
            pipeline: String, render: (Int) -> CGImage) throws {
    let folder = catalog.appendingPathComponent(group).appendingPathComponent(name + ".imageset")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    var variants: [[String: String]] = []
    for scale in 1...3 {
        let filename = name + (scale == 1 ? "" : "@\(scale)x") + ".png"
        let image = render(scale)
        precondition(image.width == width * scale && image.height == height * scale)
        try png(image, folder.appendingPathComponent(filename))
        variants.append(["filename": filename, "idiom": "universal", "scale": "\(scale)x"])
    }
    let json: [String: Any] = ["images": variants, "info": ["author": "xcode", "version": 1],
                              "properties": ["template-rendering-intent": "original"]]
    try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        .write(to: folder.appendingPathComponent("Contents.json"))
    manifest.append(["name": name, "pointWidth": width, "pointHeight": height,
                     "scales": [1, 2, 3], "frames": frames, "group": group, "pipeline": pipeline])
    print("\(name): \(width)x\(height) pt / \(frames) frames / \(pipeline)")
}

let yard = "Scenes/Yard", shared = "Shared/Lock"
func pixel(_ image: CGImage, _ name: String, frames: Int = 1) throws {
    try export(name: name, group: yard, width: image.width, height: image.height, frames: frames,
               pipeline: "integer pixel master") { resize(image, image.width * $0, image.height * $0) }
}
func detail(_ image: CGImage, _ name: String, _ w: Int, _ h: Int, group: String) throws {
    // Every variant comes directly from the original. Never enlarge a discarded 1x thumbnail.
    try export(name: name, group: group, width: w, height: h,
               pipeline: "direct original at each scale") { resize(image, w * $0, h * $0, smooth: true) }
}

try detail(load("yard-closed"), "story-yard-base", 960, 480, group: yard)
try detail(load("yard-open"), "story-yard-open", 960, 480, group: yard)
try detail(trim(load("cloud")), "story-cloud", 414, 78, group: yard)

// Four texture pixels per logical unit; crop metadata keeps each pose at24x72 world units.
let vineSource = trim(load("vine"))
try export(name: "story-vine-sheet", group: yard, width: 288, height: 288, frames: 3,
           pipeline: "each scale from original; 4 texels per logical unit") { scale in
    let density = 4 * scale
    let vine = resize(vineSource, 20 * density, 68 * density, smooth: true)
    let sheet = context(72 * density, 72 * density)
    for (frame, shift) in [0, 1, -1].enumerated() {
        for row in 0..<(68 * density) {
            let bend = Int((Double(68 * density - 1 - row) / Double(68 * density - 1) * Double(shift * density)).rounded())
            let strip = vine.cropping(to: CGRect(x: 0, y: row, width: 20 * density, height: 1))!
            sheet.draw(strip, in: CGRect(x: (frame * 24 + 2) * density + bend, y: 70 * density - row - 1, width: 20 * density, height: 1))
        }
    }
    return sheet.makeImage()!
}
try detail(trim(load("panel")), "story-lock-panel", 800, 400, group: shared)
try detail(trim(load("foliage")), "story-hint-leaves", 306, 129, group: yard)
let envelope = trim(load("envelope"))
try detail(envelope, "story-envelope", 480, 320, group: yard)

// HUD stays 32pt. Only the full-size collection reveal uses the large envelope asset.
for inactive in [false, true] {
    try export(name: inactive ? "icon-letter-off" : "icon-letter", group: yard, width: 32, height: 32, pipeline: "direct original each scale") { scale in
        let icon = context(32 * scale, 32 * scale, smooth: true)
        icon.draw(envelope, in: CGRect(x: scale, y: 6 * scale, width: 30 * scale, height: 20 * scale))
        if inactive {
            icon.setBlendMode(.sourceIn)
            icon.setFillColor(CGColor(colorSpace: colorSpace, components: [0.14, 0.24, 0.27, 1])!)
            icon.fill(CGRect(x: 0, y: 0, width: 32 * scale, height: 32 * scale))
        }
        return icon.makeImage()!
    }
}

// Register each pose to the same center. Reveal the unchanged sheet behind two travelling curls.
// No scaleY animation, no morph between different AI-generated papers, and no baked text.
let paper = trim(load("letter")), roll = trim(load("scroll-roll"))
let reveals: [CGFloat] = [0, 0.045, 0.10, 0.20, 0.34, 0.50, 0.66, 0.80, 0.91, 0.97, 1, 1]
func scrollFrame(_ index: Int, scale: Int) -> CGImage {
    let c = context(448 * scale, 300 * scale, smooth: true)
    c.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
    let fraction = reveals[index]
    let exposed = 290 * fraction
    if fraction > 0 {
        c.saveGState()
        c.clip(to: CGRect(x: 0, y: 150 - exposed / 2, width: 448, height: exposed))
        c.draw(paper, in: CGRect(x: 2, y: 5, width: 444, height: 290))
        c.restoreGState()
    }
    if index < 11 {
        let thickness: CGFloat = index == 0 ? 40 : 8 + 30 * sqrt(1 - fraction)
        c.setAlpha(index == 10 ? 0.4 : 1)
        c.draw(roll, in: CGRect(x: 2, y: 150 - exposed / 2 - thickness / 2, width: 444, height: thickness))
        if index > 0 {
            c.saveGState()
            c.translateBy(x: 0, y: 300)
            c.scaleBy(x: 1, y: -1)
            c.draw(roll, in: CGRect(x: 2, y: 150 - exposed / 2 - thickness / 2, width: 444, height: thickness))
            c.restoreGState()
        }
    }
    return c.makeImage()!
}
try export(name: "story-scroll-sheet", group: yard, width: 448 * 4, height: 300 * 3,
           frames: reveals.count, pipeline: "registered scroll poses from original paper at each scale") { scale in
    let c = context(448 * 4 * scale, 300 * 3 * scale, smooth: true)
    for index in reveals.indices {
        let x = index % 4 * 448 * scale
        let y = (2 - index / 4) * 300 * scale
        c.draw(scrollFrame(index, scale: scale), in: CGRect(x: x, y: y, width: 448 * scale, height: 300 * scale))
    }
    return c.makeImage()!
}
try png(scrollFrame(0, scale: 2), art.appendingPathComponent("review/scroll-closed.png"))
try png(scrollFrame(5, scale: 2), art.appendingPathComponent("review/scroll-middle.png"))
try png(scrollFrame(11, scale: 2), art.appendingPathComponent("review/scroll-open.png"))
try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
    .write(to: art.appendingPathComponent("assets.json"))
