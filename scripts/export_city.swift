#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Export each scale from its high-resolution original, without altering the painting.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets: [(String, String, Int)] = [("overhead-empty", "city-puzzle-overhead", 592)]
let modules = ["city-puzzle-overhead": "Bedroom"]
let requested = Array(CommandLine.arguments.dropFirst())
for (source, name, baseWidth) in assets where requested.isEmpty || requested.contains(name) {
    let sourceURL = root.appendingPathComponent("art/city/\(source).png")
    guard let decoder = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(decoder, 0, nil) else { fatalError("Missing \(source)") }
    let folder = root.appendingPathComponent("ios/Ivy/Assets.xcassets/Scenes/\(modules[name]!)/\(name).imageset")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    var entries: [[String: String]] = []
    for scale in 1...3 {
        let width = baseWidth * scale
        let height = Int((Double(width) * Double(image.height) / Double(image.width)).rounded())
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let file = name + (scale == 1 ? "" : "@\(scale)x") + ".png"
        let dest = CGImageDestinationCreateWithURL(folder.appendingPathComponent(file) as CFURL,
                                                   UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, context.makeImage()!, nil)
        guard CGImageDestinationFinalize(dest) else { fatalError("Cannot write \(file)") }
        entries.append(["filename": file, "idiom": "universal", "scale": "\(scale)x"])
    }
    try JSONSerialization.data(withJSONObject: ["images": entries, "info": ["version": 1, "author": "xcode"]],
                               options: [.prettyPrinted, .sortedKeys]).write(to: folder.appendingPathComponent("Contents.json"))
    print("Exported \(name)")
}
