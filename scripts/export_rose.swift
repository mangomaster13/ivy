#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Export only the approved original; runtime vector masks isolate the three petals.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = root.appendingPathComponent("art/memories/source/bouquet-final.png")
let folder = root.appendingPathComponent("ios/Ivy/Assets.xcassets/Scenes/Bedroom/rose-bouquet.imageset")
guard let input = CGImageSourceCreateWithURL(source as CFURL, nil),
      let original = CGImageSourceCreateImageAtIndex(input, 0, nil) else {
    fatalError("Missing original bouquet artwork")
}
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
var images: [[String: String]] = []
for scale in 1...3 {
    let edge = 400 * scale
    precondition(edge <= min(original.width, original.height), "Never upscale the original")
    let context = CGContext(data: nil, width: edge, height: edge, bitsPerComponent: 8,
                            bytesPerRow: edge * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.interpolationQuality = .high
    context.draw(original, in: CGRect(x: 0, y: 0, width: edge, height: edge))
    let filename = "rose-bouquet" + (scale == 1 ? "" : "@\(scale)x") + ".png"
    let output = CGImageDestinationCreateWithURL(folder.appendingPathComponent(filename) as CFURL,
                                                UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(output, context.makeImage()!, nil)
    guard CGImageDestinationFinalize(output) else { fatalError("Could not export \(filename)") }
    images.append(["idiom": "universal", "scale": "\(scale)x", "filename": filename])
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: folder.appendingPathComponent("Contents.json"))
print("Exported rose-bouquet at 400, 800 and 1200 pixels from the original.")
