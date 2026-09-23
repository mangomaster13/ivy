#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Export only the approved original; runtime vector masks isolate the three petals.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = root.appendingPathComponent("art/room/rose-bed/rose-lying.png")
let folder = root.appendingPathComponent("ios/Ivy/Assets.xcassets/Scenes/Bedroom/rose-lying.imageset")
guard let input = CGImageSourceCreateWithURL(source as CFURL, nil),
      let original = CGImageSourceCreateImageAtIndex(input, 0, nil) else {
    fatalError("Missing original bouquet artwork")
}
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
var images: [[String: String]] = []
for scale in 1...3 {
    let edge = 160 * scale
    let height = Int((Double(edge) * Double(original.height) / Double(original.width)).rounded())
    precondition(edge <= min(original.width, original.height), "Never upscale the original")
    let context = CGContext(data: nil, width: edge, height: height, bitsPerComponent: 8,
                            bytesPerRow: edge * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.interpolationQuality = .high
    context.draw(original, in: CGRect(x: 0, y: 0, width: edge, height: height))
    let filename = "rose-lying" + (scale == 1 ? "" : "@\(scale)x") + ".png"
    let output = CGImageDestinationCreateWithURL(folder.appendingPathComponent(filename) as CFURL,
                                                UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(output, context.makeImage()!, nil)
    guard CGImageDestinationFinalize(output) else { fatalError("Could not export \(filename)") }
    images.append(["idiom": "universal", "scale": "\(scale)x", "filename": filename])
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: folder.appendingPathComponent("Contents.json"))
print("Exported lying rose sprite directly from its original at all three scales.")
