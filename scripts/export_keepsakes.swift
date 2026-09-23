#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Export approved standalone originals directly at every device scale; preserve their alpha.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sourceRoot = root.appendingPathComponent("art/keepsakes/source")
let catalog = root.appendingPathComponent("ios/Ivy/Assets.xcassets/Keepsakes")
// Perfume uses its separately approved sealed and Gaiac artwork.
let ids = ["letter", "vuori", "plane", "keycard", "city", "rose", "gelato", "noodle",
           "cinema", "sunset", "ferris", "taxi"]
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
try FileManager.default.createDirectory(at: catalog, withIntermediateDirectories: true)
try Data("{\"info\":{\"author\":\"xcode\",\"version\":1}}\n".utf8)
    .write(to: catalog.appendingPathComponent("Contents.json"))

func read(_ url: URL) throws -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        throw NSError(domain: "KeepsakeExport", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "Cannot read \(url.path)"])
    }
    return image
}

func objectBounds(_ image: CGImage) -> CGRect {
    let width = image.width, height = image.height
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                            bytesPerRow: width * 4, space: colorSpace,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    let pixels = context.data!.assumingMemoryBound(to: UInt8.self)
    var left = width, right = 0, top = height, bottom = 0
    for y in 0..<height {
        for x in 0..<width where pixels[(y * width + x) * 4 + 3] > 12 {
            left = min(left, x); right = max(right, x)
            top = min(top, y); bottom = max(bottom, y)
        }
    }
    guard left <= right, top <= bottom else {
        return CGRect(x: 0, y: 0, width: width, height: height)
    }
    return CGRect(x: max(0, left - 4), y: max(0, top - 4),
                  width: min(width, right + 5) - max(0, left - 4),
                  height: min(height, bottom + 5) - max(0, top - 4))
}

func export(_ name: String, source: URL, points: Int, trim: Bool) throws {
    let original = try read(source)
    let object = trim ? original.cropping(to: objectBounds(original))! : original
    let folder = catalog.appendingPathComponent("\(name).imageset")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    var variants: [[String: String]] = []
    for scale in 1...3 {
        let edge = points * scale
        let context = CGContext(data: nil, width: edge, height: edge, bitsPerComponent: 8,
                                bytesPerRow: edge * 4, space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.interpolationQuality = .high
        let fit = CGFloat(edge) * (trim ? 0.94 : 1) / CGFloat(max(object.width, object.height))
        let width = CGFloat(object.width) * fit, height = CGFloat(object.height) * fit
        context.draw(object, in: CGRect(x: (CGFloat(edge) - width) / 2,
                                       y: (CGFloat(edge) - height) / 2,
                                       width: width, height: height))
        let filename = name + (scale == 1 ? "" : "@\(scale)x") + ".png"
        let destination = CGImageDestinationCreateWithURL(folder.appendingPathComponent(filename) as CFURL,
                                                          UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "KeepsakeExport", code: 2)
        }
        variants.append(["filename": filename, "idiom": "universal", "scale": "\(scale)x"])
    }
    try JSONSerialization.data(withJSONObject: ["images": variants,
        "info": ["author": "xcode", "version": 1]], options: [.prettyPrinted, .sortedKeys])
        .write(to: folder.appendingPathComponent("Contents.json"))
    print("Exported \(name)")
}

// Optional IDs permit a focused asset update without rewriting unrelated artwork.
let requested = Array(CommandLine.arguments.dropFirst())
let selected = requested.isEmpty ? ids : requested.filter { ids.contains($0) }
for id in selected {
    // The collectible and the bed represent the same Jellycat bouquet.
    let source = id == "rose"
        ? root.appendingPathComponent("art/room/rose-bed/rose-lying.png")
        : sourceRoot.appendingPathComponent("\(id).png")
    try export("keepsake-\(id)", source: source, points: 160, trim: true)
}
if requested.isEmpty {
    try export("keepsake-tap-sprigs", source: sourceRoot.appendingPathComponent("tap-sprigs.png"),
               points: 220, trim: false)
}
