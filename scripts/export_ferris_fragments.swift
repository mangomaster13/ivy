#!/usr/bin/env swift
import AppKit
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

// Production asset packaging, not a build or validation pass. Sources are never modified.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sources = root.appendingPathComponent("art/ferris/scene-redesign/source")
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

let review = root.appendingPathComponent("art/ferris/scene-redesign/review")
try export(load("ticket-booth.png", from: review), name: "ferris-ticket-booth", width: 592)
try export(load("fragment-cabinet.png"), name: "ferris-fragment-cabinet", width: 592)

// Read the shuffled evidence from gameplay, never export the complete solution as a clue.
let state = try String(contentsOf: root.appendingPathComponent("ios/Ivy/Game/FerrisPuzzle.swift"), encoding: .utf8)
let fragmentLine = state.components(separatedBy: "\n").first { $0.contains("static let fragments =") }!
let fragmentJSON = fragmentLine.components(separatedBy: "= ")[1]
let fragments = try JSONDecoder().decode([[Int]].self, from: Data(fragmentJSON.utf8))

// Matches FerrisStaff exactly, with bottom-up CoreGraphics coordinates.
func staff(_ notes: [Int], in rect: CGRect, context c: CGContext) {
    c.saveGState()
    c.translateBy(x: rect.minX, y: rect.minY)
    c.setStrokeColor(ink.cgColor); c.setFillColor(ink.cgColor)
    c.setLineWidth(max(1, rect.height * 0.013))
    for line in 0..<5 {
        let y = rect.height * (0.3 + CGFloat(line) * 0.15)
        c.move(to: CGPoint(x: 0, y: y)); c.addLine(to: CGPoint(x: rect.width, y: y)); c.strokePath()
    }
    let step = rect.width / CGFloat(notes.count)
    let w = min(step * 0.44, rect.height * 0.17)
    for (i, note) in notes.enumerated() {
        let x = step * (CGFloat(i) + 0.5)
        let y = rect.height * (0.3 + CGFloat(note) * 0.075)
        c.fillEllipse(in: CGRect(x: x - w / 2, y: y - w * 0.34, width: w, height: w * 0.68))
        c.move(to: CGPoint(x: x + w / 2, y: y))
        c.addLine(to: CGPoint(x: x + w / 2, y: y + rect.height * 0.22)); c.strokePath()
    }
    c.restoreGState()
}
let rule = art(width: 1300, height: 360) { c in
    text("Use every paper once.", in: CGRect(x: 10, y: 296, width: 1280, height: 60), size: 48)
    text("Join matching ends. Play the shared note once.",
         in: CGRect(x: 10, y: 238, width: 1280, height: 55), size: 42)
    // Unrelated example: F,A + A,C becomes F,A,C, not the puzzle's answer.
    staff([1, 3], in: CGRect(x: 50, y: 124, width: 200, height: 94), context: c)
    text("+", in: CGRect(x: 269, y: 143, width: 60, height: 65), size: 48)
    staff([3, 5], in: CGRect(x: 349, y: 124, width: 200, height: 94), context: c)
    arrow(c, start: CGPoint(x: 594, y: 169), end: CGPoint(x: 680, y: 169))
    staff([1, 3, 5], in: CGRect(x: 736, y: 124, width: 500, height: 94), context: c)
    text("Begin", in: CGRect(x: 52, y: 17, width: 160, height: 66), size: 43)
    staff([0], in: CGRect(x: 236, y: 10, width: 150, height: 90), context: c)
    text("Finish", in: CGRect(x: 657, y: 17, width: 160, height: 66), size: 43)
    staff([6], in: CGRect(x: 870, y: 10, width: 150, height: 90), context: c)
}
let oldSources = root.appendingPathComponent("art/ferris/score-postcard/source")
let cabinet = load("cabinet.png", from: oldSources)
let guide = art(width: cabinet.width, height: cabinet.height) { c in
    c.draw(cabinet, in: CGRect(x: 0, y: 0, width: cabinet.width, height: cabinet.height))
    let scale = CGFloat(cabinet.width) / 320
    c.draw(rule, in: CGRect(x: 100 * scale, y: (160 - 61) * scale, width: 123 * scale, height: 34 * scale))
}
try export(guide, name: "ferris-join-guide", width: 592)
let clue = art(width: 1000, height: 760) { c in
    for (i, notes) in fragments.enumerated() {
        staff(notes, in: CGRect(x: 20 + (i % 2) * 520, y: 580 - (i / 2) * 170, width: 440, height: 140), context: c)
    }
    // Notes retain a large visual joining example, not miniature paragraphs or a solved phrase.
    staff([1, 3], in: CGRect(x: 20, y: 215, width: 210, height: 120), context: c)
    text("+", in: CGRect(x: 237, y: 238, width: 65, height: 90), size: 76)
    staff([3, 5], in: CGRect(x: 310, y: 215, width: 210, height: 120), context: c)
    arrow(c, start: CGPoint(x: 545, y: 273), end: CGPoint(x: 615, y: 273))
    staff([1, 3, 5], in: CGRect(x: 650, y: 215, width: 330, height: 120), context: c)
    text("Begin", in: CGRect(x: 10, y: 32, width: 210, height: 95), size: 76)
    staff([0], in: CGRect(x: 242, y: 22, width: 160, height: 120), context: c)
    text("Finish", in: CGRect(x: 520, y: 32, width: 240, height: 95), size: 76)
    staff([6], in: CGRect(x: 800, y: 22, width: 160, height: 120), context: c)
}
try export(clue, name: "ferris-fragment-clue", width: 650)
let plaque = art(width: 240, height: 340) { c in
    text("Join", in: CGRect(x: 5, y: 262, width: 230, height: 72), size: 66)
    c.setStrokeColor(ink.cgColor); c.setLineWidth(9)
    c.move(to: CGPoint(x: 27, y: 185)); c.addLine(to: CGPoint(x: 120, y: 125))
    c.addLine(to: CGPoint(x: 213, y: 185)); c.strokePath()
    c.setFillColor(ink.cgColor)
    for point in [CGPoint(x: 27, y: 185), CGPoint(x: 120, y: 125), CGPoint(x: 213, y: 185)] {
        c.fillEllipse(in: CGRect(x: point.x - 15, y: point.y - 15, width: 30, height: 30))
    }
    text("1 ×", in: CGRect(x: 5, y: 18, width: 230, height: 72), size: 62)
}
try export(plaque, name: "ferris-join-plaque", width: 120)

// Authored source composites for art inspection, not app screenshots.
func save(_ image: CGImage, filename: String) {
    let url = sources.appendingPathComponent(filename)
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { fatalError("Cannot save \(filename)") }
}
save(guide, filename: "join-guide.png")
save(clue, filename: "fragment-clue.png")
let blank = load("fragment-cabinet.png")
let lettered = art(width: blank.width, height: blank.height) { c in
    c.draw(blank, in: CGRect(x: 0, y: 0, width: blank.width, height: blank.height))
    let scale = CGFloat(blank.width) / 320
    let bounds = [CGRect(x: 110, y: 28, width: 49, height: 13), CGRect(x: 172, y: 28, width: 50, height: 13),
                  CGRect(x: 108, y: 51, width: 51, height: 13), CGRect(x: 173, y: 51, width: 51, height: 13)]
    for (i, rect) in bounds.enumerated() {
        staff(fragments[i], in: CGRect(x: rect.minX * scale, y: (160 - rect.maxY) * scale,
                                      width: rect.width * scale, height: rect.height * scale), context: c)
    }
    c.draw(plaque, in: CGRect(x: 85.5 * scale, y: 100.5 * scale, width: 12 * scale, height: 17 * scale))
}
save(lettered, filename: "fragment-cabinet-lettered.png")
