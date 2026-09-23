#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Derive every scale directly from the generated original, never from another export.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
for state in ["open", "closed"] {
    let source = root.appendingPathComponent("art/room/blanket/\(state).png")
    let name = "memory-blanket-" + state
    let folder = root.appendingPathComponent("ios/Ivy/Assets.xcassets/Scenes/Bedroom/\(name).imageset")
    guard let input = CGImageSourceCreateWithURL(source as CFURL, nil),
          let original = CGImageSourceCreateImageAtIndex(input, 0, nil) else { fatalError("Missing blanket original") }
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    var images: [[String: String]] = []
    for scale in 1...3 {
        let width = 560 * scale, height = 280 * scale
        precondition(width <= original.width && height <= original.height)
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.interpolationQuality = .high
        context.draw(original, in: CGRect(x: 0, y: 0, width: width, height: height))
        let filename = name + (scale == 1 ? "" : "@\(scale)x") + ".png"
        let output = CGImageDestinationCreateWithURL(folder.appendingPathComponent(filename) as CFURL,
            UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(output, context.makeImage()!, nil)
        guard CGImageDestinationFinalize(output) else { fatalError("Could not export blanket") }
        images.append(["idiom": "universal", "scale": "\(scale)x", "filename": filename])
    }
    try JSONSerialization.data(withJSONObject: ["images": images, "info": ["author": "xcode", "version": 1]],
        options: [.prettyPrinted, .sortedKeys]).write(to: folder.appendingPathComponent("Contents.json"))
}
print("Exported blanket backgrounds at 1x, 2x and 3x.")
