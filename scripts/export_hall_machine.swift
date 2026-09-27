#!/usr/bin/env swift
// Export approved Hall machine states; no game build or device checks.
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = root.appendingPathComponent("art/finale/hall-machine-redesign")
let catalog = root.appendingPathComponent("ios/Ivy/Assets.xcassets/Scenes/Hall")
for (state, filename) in [("ready", "proposal.png"), ("finished", "finished.png")] {
    let url = source.appendingPathComponent(filename)
    guard let input = CGImageSourceCreateWithURL(url as CFURL, nil),
          let original = CGImageSourceCreateImageAtIndex(input, 0, nil) else {
        fatalError("Missing original: \(url.path)")
    }
    let name = "story-hall-" + state
    let folder = catalog.appendingPathComponent(name + ".imageset")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    var entries: [[String: String]] = []
    for scale in 1...3 {
        // All scales derive directly from the 1774×887 original, without upscaling.
        let width = 590 * scale, height = 295 * scale
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.interpolationQuality = .high
        context.draw(original, in: CGRect(x: 0, y: 0, width: width, height: height))
        let output = name + (scale == 1 ? "" : "@\(scale)x") + ".png"
        let destination = CGImageDestinationCreateWithURL(folder.appendingPathComponent(output) as CFURL,
                                                         UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, nil)
        precondition(CGImageDestinationFinalize(destination), "PNG export failed")
        entries.append(["filename": output, "idiom": "universal", "scale": "\(scale)x"])
    }
    try JSONSerialization.data(withJSONObject: ["images": entries, "info": ["author": "xcode", "version": 1]],
                               options: [.prettyPrinted, .sortedKeys])
        .write(to: folder.appendingPathComponent("Contents.json"))
    print("Exported \(name)")
}
