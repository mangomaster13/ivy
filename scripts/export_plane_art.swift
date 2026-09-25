#!/usr/bin/env swift
import AppKit
import CoreText
import ImageIO
import UniformTypeIdentifiers

// Approved overhead objects; every device scale comes directly from the original.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = root.appendingPathComponent("art/plane-redesign/source")
let catalog = root.appendingPathComponent("ios/Ivy/Assets.xcassets/Scenes/Plane")
for font in ["Kiddos.ttf", "Juniper-Regular.ttf"] {
    CTFontManagerRegisterFontsForURL(root.appendingPathComponent("ios/Ivy/Fonts/" + font) as CFURL, .process, nil)
}
func load(_ name: String) -> CGImage {
    let url = source.appendingPathComponent(name + ".png")
    guard let data = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(data, 0, nil) else { fatalError("Missing source: \(url.path)") }
    return image
}
func export(_ name: String, width: Int, height: Int, draw: (CGContext) -> Void) throws {
    let folder = catalog.appendingPathComponent(name + ".imageset")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    var images: [[String: String]] = []
    for scale in 1...3 {
        let context = CGContext(data: nil, width: width * scale, height: height * scale, bitsPerComponent: 8,
                                bytesPerRow: width * scale * 4, space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
        context.interpolationQuality = .high
        draw(context)
        let filename = name + (scale == 1 ? "" : "@\(scale)x") + ".png"
        let url = folder.appendingPathComponent(filename)
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil),
              let image = context.makeImage() else { fatalError("Cannot export \(name)") }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { fatalError("Cannot write \(url.path)") }
        images.append(["idiom": "universal", "scale": "\(scale)x", "filename": filename])
    }
    try JSONSerialization.data(withJSONObject: ["images": images, "info": ["author": "xcode", "version": 1]],
                               options: [.prettyPrinted, .sortedKeys]).write(to: folder.appendingPathComponent("Contents.json"))
}
func lettering(_ text: String, font: String, size: CGFloat, bounds: CGRect, color: NSColor, in context: CGContext) {
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [
        NSAttributedString.Key(kCTFontAttributeName as String): CTFontCreateWithName(font as CFString, size, nil),
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): color.cgColor
    ]))
    let ink = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
    let fit = min(1, min(bounds.width / ink.width, bounds.height / ink.height))
    context.saveGState()
    context.translateBy(x: bounds.midX - ink.width * fit / 2 - ink.minX * fit,
                        y: bounds.midY - ink.height * fit / 2 - ink.minY * fit)
    context.scaleBy(x: fit, y: fit)
    context.textMatrix = .identity
    context.textPosition = .zero
    CTLineDraw(line, context)
    context.restoreGState()
}
for (file, name, width) in [("ticket", "plane-ticket-paper", 620), ("atlas-paper", "plane-atlas-paper", 512), ("atlas-land", "plane-atlas-land", 512)] {
    let image = load(file)
    let height = Int((Double(width) * Double(image.height) / Double(image.width)).rounded())
    try export(name, width: width, height: height) { context in
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
}
let teal = NSColor(red: 0.08, green: 0.25, blue: 0.25, alpha: 1)
try export("plane-ticket-lettering", width: 620, height: 282) { context in
    // Top-origin writable bounds: route (49, 79, 435, 40), inscription (62, 121, 409, 29).
    lettering("Hangzhou → Hong Kong", font: "Georgia-Italic", size: 32,
              bounds: CGRect(x: 49, y: 163, width: 435, height: 40), color: teal, in: context)
    lettering("our first journey", font: "Juniper-Regular", size: 25,
              bounds: CGRect(x: 62, y: 132, width: 409, height: 29), color: teal, in: context)
}
for (name, text, width, height, size) in [
    ("plane-depart", "depart", 124, 32, 23), ("plane-departing", "on our way…", 124, 32, 21),
    ("plane-route-one", "1", 32, 32, 23), ("plane-route-two", "2", 32, 32, 23)
] {
    try export(name, width: width, height: height) { context in
        lettering(text, font: "KidDos-Font", size: CGFloat(size),
                  bounds: CGRect(x: 3, y: 3, width: width - 6, height: height - 6), color: teal, in: context)
    }
}
print("Exported Plane artwork and lettering from source at 1x/2x/3x.")
