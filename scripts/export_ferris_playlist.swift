#!/usr/bin/env swift
import AppKit
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

// Production asset packaging, not a build or validation pass. Sources are never modified.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sources = root.appendingPathComponent("art/ferris/playlist")
let sceneSources = root.appendingPathComponent("art/ferris/sequence")
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
    ("classic-cutout.png", "ferris-classic-ipod", 256),
    ("ticket-cutout.png", "ferris-ride-ticket", 320),
    ("phone-cutout.png", "ferris-selfie-phone", 256),
    ("dispenser-source.png", "ferris-dispenser", 320)
] { try export(load(source), name: name, width: width) }

for (source, name, width) in [
    ("promenade-source.png", "ferris-promenade", 592),
    ("booth-source.png", "ferris-ticket-booth", 592),
    ("gate-closed-source.png", "ferris-boarding-closed", 592),
    ("gate-open-source.png", "ferris-boarding-open", 592),
    ("cabin-empty-source.png", "ferris-cabin-interior", 592),
    ("selfie-cartoon-source.png", "ferris-selfie", 418)
] { try export(load(source, from: sceneSources), name: name, width: width) }

// Tight physical LCD camera crop from the unchanged high-resolution source.
let ipod = load("classic-source.png")
let screen = ipod.cropping(to: CGRect(x: 162, y: 180, width: 698, height: 510))!
try export(screen, name: "ferris-ipod-screen", width: 384)

// Exact, independently movable lettering. Layout bounds: 360×44, 10pt left margin,
// title at y=3 (17pt), artist at y=25 (12pt); CJK uses the system's CJK font fallback.
CTFontManagerRegisterFontsForURL(root.appendingPathComponent("ios/Ivy/Fonts/Kiddos.ttf") as CFURL, .process, nil)
let songs = [("Enchanted", "Taylor Swift"), ("I don’t want to say goodbye", "Dean Lewis"),
             ("Part of the band", "The 1975"), ("也许", "林忆莲"), ("Lover", "Taylor Swift")]
for (index, song) in songs.enumerated() {
    let context = CGContext(data: nil, width: 1080, height: 132, bitsPerComponent: 8, bytesPerRow: 4320,
                            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.scaleBy(x: 3, y: 3)
    let graphics = NSGraphicsContext(cgContext: context, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphics
    let title = NSAttributedString(string: song.0, attributes: [
        .font: NSFont(name: "KidDos-Font", size: 17) ?? NSFont.systemFont(ofSize: 17),
        .foregroundColor: NSColor(red: 0.96, green: 0.90, blue: 0.75, alpha: 1)
    ])
    let artist = NSAttributedString(string: song.1, attributes: [
        .font: NSFont(name: "KidDos-Font", size: 12) ?? NSFont.systemFont(ofSize: 12),
        .foregroundColor: NSColor(red: 0.79, green: 0.84, blue: 0.80, alpha: 1)
    ])
    title.draw(at: NSPoint(x: 10, y: 22))
    artist.draw(at: NSPoint(x: 10, y: 5))
    NSGraphicsContext.restoreGraphicsState()
    try export(context.makeImage()!, name: "ferris-track-\(index)", width: 360)
}
