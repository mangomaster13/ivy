#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let catalog = root.appendingPathComponent("ios/Ivy/Assets.xcassets/Scenes")
let assets = [
    ("main", "Gelato/hk-gelato"),
    ("bench", "Gelato/explore-gelato-bench"),
    ("service", "Gelato/explore-gelato-service"),
    ("menu", "Gelato/gelato-menu"),
    ("tasting", "Gelato/gelato-tasting"),
    ("box-closed", "Gelato/gelato-box-closed"),
    ("box-open", "Gelato/gelato-box-open")
]
let requested = Array(CommandLine.arguments.dropFirst())
for (source, path) in assets where requested.isEmpty || requested.contains(source) {
    let sourceURL = root.appendingPathComponent("art/gelato/source/\(source).png")
    guard let decoder = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(decoder, 0, nil) else { fatalError("Missing \(source)") }
    precondition(image.width >= 1600 && image.width == image.height * 2)
    let name = String(path.split(separator: "/").last!)
    let folder = catalog.appendingPathComponent(path + ".imageset")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    var images: [[String: String]] = []
    for scale in 1...3 {
        // Every scale reads the original, never another catalog rendition.
        let width = 640 * scale, height = 320 * scale
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let filename = name + (scale == 1 ? "" : "@\(scale)x") + ".png"
        let destination = CGImageDestinationCreateWithURL(folder.appendingPathComponent(filename) as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, nil)
        precondition(CGImageDestinationFinalize(destination))
        images.append(["idiom": "universal", "scale": "\(scale)x", "filename": filename])
    }
    try JSONSerialization.data(withJSONObject: ["images": images, "info": ["author": "xcode", "version": 1]], options: [.prettyPrinted, .sortedKeys]).write(to: folder.appendingPathComponent("Contents.json"))
    print("Exported \(name) directly from \(image.width)×\(image.height)")
}
