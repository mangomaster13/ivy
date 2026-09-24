#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Production packaging only; each scale reads its approved high-resolution source.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = [
    ("chain-menu-unmarked.png", "gelato-words-unmarked", 592),
    ("chain-menu-superseded-v2.png", "gelato-words-marked", 592),
    ("chain-order-design-v2.png", "gelato-word-order", 512),
    ("chain-note-design-v2.png", "gelato-word-note", 512)
]
for (source, name, baseWidth) in assets {
    let sourceURL = root.appendingPathComponent("art/gelato/word-puzzle/" + source)
    guard let decoder = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(decoder, 0, nil) else { fatalError("Missing \(source)") }
    let folder = root.appendingPathComponent("ios/Ivy/Assets.xcassets/Scenes/Gelato/\(name).imageset")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    var images: [[String: String]] = []
    for scale in 1...3 {
        let width = min(image.width, baseWidth * scale)
        let height = Int((Double(width) * Double(image.height) / Double(image.width)).rounded())
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let filename = name + (scale == 1 ? "" : "@\(scale)x") + ".png"
        let destination = CGImageDestinationCreateWithURL(folder.appendingPathComponent(filename) as CFURL,
                                                          UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, nil)
        guard CGImageDestinationFinalize(destination) else { fatalError("Cannot write \(filename)") }
        images.append(["idiom": "universal", "scale": "\(scale)x", "filename": filename])
    }
    try JSONSerialization.data(withJSONObject: ["images": images, "info": ["author": "xcode", "version": 1]],
                               options: [.prettyPrinted, .sortedKeys])
        .write(to: folder.appendingPathComponent("Contents.json"))
    print("Exported \(name)")
}
