#!/usr/bin/env swift
import AppKit
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

// Production asset packaging, not a build or validation pass. Sources are never modified.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sources = root.appendingPathComponent("art/ferris/score-postcard/source")
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

for (source, name) in [
    ("cabinet.png", "ferris-music-cabinet"),
    ("harbour-low.png", "ferris-harbour-0"),
    ("harbour-middle.png", "ferris-harbour-1"),
    ("harbour-high.png", "ferris-harbour-2"),
    ("press.png", "ferris-press"),
    ("press-empty.png", "ferris-press-empty"),
    ("postbox.png", "ferris-postbox")
] { try export(load(source), name: name, width: 592) }

// Asset extraction from the generated sheet's actual unequal tile bounds.
let sheet = load("stamps.png")
let stampBounds = [CGRect(x: 35, y: 310, width: 970, height: 325),
                   CGRect(x: 1060, y: 100, width: 325, height: 535),
                   CGRect(x: 1600, y: 250, width: 490, height: 385)]
let stamps = stampBounds.map { sheet.cropping(to: $0)! }
for (index, stamp) in stamps.enumerated() { try export(stamp, name: "ferris-stamp-\(index)", width: 192) }

let ink = NSColor(red: 0.12, green: 0.20, blue: 0.21, alpha: 1)
CTFontManagerRegisterFontsForURL(root.appendingPathComponent("ios/Ivy/Fonts/Juniper-Regular.ttf") as CFURL, .process, nil)
CTFontManagerRegisterFontsForURL(root.appendingPathComponent("ios/Ivy/Fonts/Kiddos.ttf") as CFURL, .process, nil)
func art(width: Int, height: Int, draw: (CGContext) -> Void) -> CGImage {
    let c = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: c, flipped: false)
    draw(c)
    NSGraphicsContext.restoreGraphicsState()
    return c.makeImage()!
}
func text(_ value: String, in rect: CGRect, size: CGFloat, font: String = "Juniper-Regular") {
    let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
    NSAttributedString(string: value, attributes: [.font: NSFont(name: font, size: size)!,
                        .foregroundColor: ink, .paragraphStyle: paragraph]).draw(in: rect)
}
func fit(_ image: CGImage, in rect: CGRect, context: CGContext) {
    let scale = min(rect.width / CGFloat(image.width), rect.height / CGFloat(image.height))
    let w = CGFloat(image.width) * scale, h = CGFloat(image.height) * scale
    context.draw(image, in: CGRect(x: rect.midX - w / 2, y: rect.midY - h / 2, width: w, height: h))
}
func arrow(_ context: CGContext, start: CGPoint, end: CGPoint) {
    context.setStrokeColor(ink.cgColor); context.setLineWidth(4)
    context.move(to: start); context.addLine(to: end)
    context.move(to: CGPoint(x: end.x - 10, y: end.y + 8)); context.addLine(to: end)
    context.addLine(to: CGPoint(x: end.x - 10, y: end.y - 8)); context.strokePath()
}
let rule = art(width: 1160, height: 210) { c in
    text("Near to far", in: CGRect(x: 20, y: 70, width: 1120, height: 110), size: 70)
    // Scale and overlap show depth without giving the identities' correct order.
    c.setStrokeColor(ink.cgColor); c.setLineWidth(4)
    for i in 0..<3 {
        let side = CGFloat(43 - i * 10)
        c.stroke(CGRect(x: 420 + CGFloat(i) * 65, y: 12, width: side, height: side))
    }
    arrow(c, start: CGPoint(x: 640, y: 33), end: CGPoint(x: 730, y: 33))
}
try export(rule, name: "ferris-near-far-lettering", width: 464)
let impressions = art(width: 1160, height: 210) { c in
    for i in 0..<3 { fit(stamps[i], in: CGRect(x: 120 + CGFloat(i) * 330, y: 20, width: 260, height: 160), context: c) }
}
try export(impressions, name: "ferris-stamped-lettering", width: 464)
for (name, word) in [("ferris-record-off", "Explore"), ("ferris-record-on", "Record")] {
    let lettering = art(width: 480, height: 180) { _ in
        text(word, in: CGRect(x: 10, y: 25, width: 460, height: 140), size: 94, font: "KidDos-Font")
    }
    try export(lettering, name: name, width: 96)
}

// Exact notation; y coordinates are the inverted form of FerrisStaff's top-down canvas.
// Read the one melody literal from the state source so art and answer cannot silently drift.
let state = try String(contentsOf: root.appendingPathComponent("ios/Ivy/Game/FerrisPuzzle.swift"), encoding: .utf8)
let melodyLine = state.components(separatedBy: "\n").first { $0.contains("static let melody =") }!
let melody = melodyLine.components(separatedBy: "[")[1].components(separatedBy: "]")[0]
    .split(separator: ",").map { Int($0.trimmingCharacters(in: .whitespaces))! }
let score = art(width: 1160, height: 200) { c in
    c.setStrokeColor(ink.cgColor); c.setFillColor(ink.cgColor)
    c.setLineWidth(2.6)
    for line in 0..<5 {
        let y = 200 * (0.3 + Double(line) * 0.15)
        c.move(to: CGPoint(x: 0, y: y)); c.addLine(to: CGPoint(x: 1160, y: y)); c.strokePath()
    }
    for (i, note) in melody.enumerated() {
        let x = 1160 / Double(melody.count) * (Double(i) + 0.5)
        let y = 200 * (0.3 + Double(note) * 0.075)
        c.fillEllipse(in: CGRect(x: x - 17, y: y - 11.56, width: 34, height: 23.12))
        c.setLineWidth(5); c.move(to: CGPoint(x: x + 17, y: y))
        c.addLine(to: CGPoint(x: x + 17, y: y + 44)); c.strokePath()
    }
}
try export(score, name: "ferris-score", width: 580)

// The generator retained an outside tan field. Crop to the physical paper bounds;
// this is a rectangular paper keepsake, not a falsely advertised alpha cutout.
let card = load("postcard.png").cropping(to: CGRect(x: 34, y: 44, width: 1468, height: 932))!
try export(card, name: "ferris-postcard", width: 490)
let finished = art(width: card.width, height: card.height) { c in
    c.draw(card, in: CGRect(x: 0, y: 0, width: card.width, height: card.height))
    text("Above the harbour", in: CGRect(x: 50, y: 27, width: 750, height: 110), size: 64)
    for i in 0..<3 { fit(stamps[i], in: CGRect(x: 880 + CGFloat(i) * 160, y: 20, width: 140, height: 115), context: c) }
}
try export(finished, name: "ferris-postcard-finished", width: 490)
let clue = art(width: 1160, height: 650) { c in
    for (i, identity) in [2, 0, 1].enumerated() { fit(stamps[identity], in: CGRect(x: 70 + CGFloat(i) * 370, y: 260, width: 280, height: 280), context: c) }
    c.draw(rule, in: CGRect(x: 0, y: 20, width: 1160, height: 210))
}
try export(clue, name: "ferris-postcard-clue", width: 580)

// Save assembled source art for inspection, not a runtime screenshot.
func save(_ image: CGImage, filename: String) {
    let destination = CGImageDestinationCreateWithURL(sources.appendingPathComponent(filename) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { fatalError("Cannot save \(filename)") }
}
let cabinet = load("cabinet.png")
let lettered = art(width: cabinet.width, height: cabinet.height) { c in
    c.draw(cabinet, in: CGRect(x: 0, y: 0, width: cabinet.width, height: cabinet.height))
    let scale = CGFloat(cabinet.width) / 320
    c.draw(score, in: CGRect(x: 100 * scale, y: (160 - 47) * scale, width: 116 * scale, height: 20 * scale))
}
save(lettered, filename: "cabinet-lettered.png")
save(finished, filename: "postcard-finished.png")
let emptyBed = load("cabin-empty-bed.png").cropping(to: CGRect(x: 183, y: 620, width: 220, height: 75))!
try export(emptyBed, name: "ferris-cabin-empty-bed", width: 74)
let press = load("press.png")
let pressLettered = art(width: press.width, height: press.height) { c in
    c.draw(press, in: CGRect(x: 0, y: 0, width: press.width, height: press.height))
    let scale = CGFloat(press.width) / 320
    for (slot, identity) in [2, 0, 1].enumerated() {
        let center = [111.0, 157.0, 204.0][slot]
        fit(stamps[identity], in: CGRect(x: (center - 12) * scale, y: (160 - 80.5) * scale,
                                         width: 24 * scale, height: 25 * scale), context: c)
    }
    c.draw(rule, in: CGRect(x: 99 * scale, y: (160 - 115.5) * scale, width: 116 * scale, height: 21 * scale))
}
save(pressLettered, filename: "press-lettered.png")
