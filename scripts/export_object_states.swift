#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let catalog = root.appendingPathComponent("ios/Ivy/Assets.xcassets/Scenes")
let assets = [
    ("bt-state-menu", "BigTop/bt-state-menu"),
    ("pot-state-key", "Yard/pot-state-key"),
    ("drawer-state-eraser", "Hall/drawer-state-eraser"),
    ("book-state-ticket", "Plane/book-state-ticket"),
    ("box-state-both", "Bedroom/box-state-both"),
    ("cabinet-state-scoop", "Gelato/cabinet-state-scoop"),
    ("gelato-state-served", "Gelato/gelato-state-served"),
    ("bt-state-empty", "BigTop/bt-state-empty"),
    ("drawer-state-empty", "Hall/drawer-state-empty"),
    ("box-state-petal", "Bedroom/box-state-petal"),
    ("box-state-token", "Bedroom/box-state-token"),
    ("box-state-empty", "Bedroom/box-state-empty"),
    ("drawer-state-closed", "Hall/drawer-state-closed"),
    ("bt-state-closed", "BigTop/bt-state-closed"),
    ("box-state-closed", "Bedroom/box-state-closed"),
    ("pot-state-empty", "Yard/pot-state-empty"),
    ("pot-state-covered", "Yard/pot-state-covered"),
    ("book-state-empty", "Plane/book-state-empty"),
    ("cabinet-state-empty", "Gelato/cabinet-state-empty"),
    ("cabinet-state-closed", "Gelato/cabinet-state-closed"),
    ("gelato-state-empty", "Gelato/gelato-state-empty"),
    ("gelato-state-tasted", "Gelato/gelato-state-tasted")
]
for (source, path) in assets {
    let sourceURL = root.appendingPathComponent("art/object-states/source/\(source).png")
    guard let decoder = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(decoder, 0, nil) else { fatalError("Missing \(source)") }
    precondition(image.width >= 1600 && image.width == image.height * 2)
    // Keep 3x within native resolution; each rendition reads the original.
    let baseWidth = min(960, image.width / 6 * 2)
    let folder = catalog.appendingPathComponent(path + ".imageset")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    var images: [[String: String]] = []
    for scale in 1...3 {
        let width = baseWidth * scale, height = width / 2
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let filename = source + (scale == 1 ? "" : "@\(scale)x") + ".png"
        let destination = CGImageDestinationCreateWithURL(folder.appendingPathComponent(filename) as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, nil)
        precondition(CGImageDestinationFinalize(destination))
        images.append(["idiom": "universal", "scale": "\(scale)x", "filename": filename])
    }
    try JSONSerialization.data(withJSONObject: ["images": images, "info": ["author": "xcode", "version": 1]], options: [.prettyPrinted, .sortedKeys]).write(to: folder.appendingPathComponent("Contents.json"))
    print("Exported \(source) directly from \(image.width)×\(image.height)")
}
