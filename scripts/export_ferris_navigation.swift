#!/usr/bin/env swift
import AppKit
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

// Production asset packaging, not a build or validation pass. Sources are never modified.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sources = root.appendingPathComponent("art/ferris/taxi-navigation/source")
let catalog = root.appendingPathComponent("ios/Ivy/Assets.xcassets/Scenes/Ferris")

func load(_ filename: String, from folder: URL = sources) -> CGImage {
    let url = folder.appendingPathComponent(filename)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { fatalError("Missing \(filename)") }
    return image
}

func export(_ image: CGImage, name: String, width: Int) throws {
    let folder = catalog.appendingPathComponent(name + ".imageset")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    var entries: [[String: String]] = []
    for scale in 1...3 {
        let w = min(image.width, width * scale)
        let h = Int((Double(w) * Double(image.height) / Double(image.width)).rounded())
        let context = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        let filename = name + (scale == 1 ? "" : "@\(scale)x") + ".png"
        let destination = CGImageDestinationCreateWithURL(folder.appendingPathComponent(filename) as CFURL,
                                                          UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, nil)
        guard CGImageDestinationFinalize(destination) else { fatalError("Cannot export \(name)") }
        entries.append(["idiom": "universal", "scale": "\(scale)x", "filename": filename])
    }
    try JSONSerialization.data(withJSONObject: ["images": entries, "info": ["author": "xcode", "version": 1]],
                               options: [.prettyPrinted, .sortedKeys]).write(to: folder.appendingPathComponent("Contents.json"))
    print("Exported \(name)")
}

for (source, name, width) in [
    ("forecourt.png", "ferris-taxi-forecourt", 592),
    ("ticket-ready.png", "ferris-ticket-ready", 592),
    ("ticket-empty.png", "ferris-ticket-empty", 592)
] { try export(load(source), name: name, width: width) }

// Trim only transparent padding. All scales come directly from the generated source.
for (source, name, bounds, width) in [
    ("postcard.png", "taxi-ferris-postcard", CGRect(x: 0.075, y: 0.04, width: 0.85, height: 0.91), 256),
    ("ticket.png", "ferris-navigation-ticket", CGRect(x: 0.07, y: 0.12, width: 0.86, height: 0.83), 192)
] {
    let original = load(source)
    let crop = CGRect(x: bounds.minX * CGFloat(original.width), y: bounds.minY * CGFloat(original.height),
                      width: bounds.width * CGFloat(original.width), height: bounds.height * CGFloat(original.height))
    guard let object = original.cropping(to: crop) else { fatalError("Cannot crop \(source)") }
    try export(object, name: name, width: width)
}
