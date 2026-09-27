#!/usr/bin/env swift
import AppKit
import CoreText
import ImageIO
import UniformTypeIdentifiers

// Production export only: no app launch, screenshot or verification build.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = root.appendingPathComponent("art/perfume/laboratory/source")
let catalog = root.appendingPathComponent("ios/Ivy/Assets.xcassets/Scenes/LeLabo/Laboratory")
try FileManager.default.createDirectory(at: catalog, withIntermediateDirectories: true)
try Data("{\"info\":{\"author\":\"xcode\",\"version\":1}}".utf8).write(to: catalog.appendingPathComponent("Contents.json"))
CTFontManagerRegisterFontsForURL(root.appendingPathComponent("ios/Ivy/Fonts/Juniper-Regular.ttf") as CFURL, .process, nil)
let ink = NSColor(red: 0.08, green: 0.19, blue: 0.18, alpha: 1).cgColor

func load(_ url: URL) -> CGImage {
    let input = CGImageSourceCreateWithURL(url as CFURL, nil)!
    return CGImageSourceCreateImageAtIndex(input, 0, nil)!
}
func save(_ image: CGImage, _ url: URL) {
    let output = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(output, image, nil)
    precondition(CGImageDestinationFinalize(output))
}
func export(_ name: String, _ width: Int, _ height: Int, draw: (CGContext) -> Void) throws {
    let folder = catalog.appendingPathComponent(name + ".imageset")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    var images: [[String: String]] = []
    for scale in 1...3 {
        let ctx = CGContext(data: nil, width: width * scale, height: height * scale, bitsPerComponent: 8,
                            bytesPerRow: width * scale * 4, space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
        ctx.interpolationQuality = .high
        draw(ctx)
        let image = ctx.makeImage()!
        let filename = name + (scale == 1 ? "" : "@\(scale)x") + ".png"
        save(image, folder.appendingPathComponent(filename))
        images.append(["idiom": "universal", "scale": "\(scale)x", "filename": filename])
    }
    try JSONSerialization.data(withJSONObject: ["images": images, "info": ["author": "xcode", "version": 1]],
                               options: [.prettyPrinted, .sortedKeys]).write(to: folder.appendingPathComponent("Contents.json"))
}
func lettering(_ string: String, rect: CGRect, size: CGFloat, in ctx: CGContext) {
    let font = CTFontCreateWithName("Juniper-Regular" as CFString, size, nil)
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: string, attributes: [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): ink
    ]))
    let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
    let fit = min(1, min((rect.width - 4) / max(1, bounds.width), (rect.height - 2) / max(1, bounds.height)))
    ctx.saveGState()
    ctx.translateBy(x: rect.midX - bounds.width * fit / 2 - bounds.minX * fit,
                    y: rect.midY - bounds.height * fit / 2 - bounds.minY * fit)
    ctx.scaleBy(x: fit, y: fit)
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

for name in ["overview", "overview-empty", "samples", "blending", "empty-tray"] {
    let url = source.appendingPathComponent(name + ".png")
    if FileManager.default.fileExists(atPath: url.path) {
        let image = load(url)
        try export("ll5-" + name, 590, 295) { $0.draw(image, in: CGRect(x: 0, y: 0, width: 590, height: 295)) }
    }
}
let sprites = load(source.appendingPathComponent("paper-sprites.png"))
for (name, rect, w, h) in [
    ("paper-tool", CGRect(x: 145, y: 110, width: 630, height: 680), 70, 76),
    ("reference-closed", CGRect(x: 1020, y: 190, width: 550, height: 520), 84, 79)
] {
    let image = sprites.cropping(to: rect)!
    try export("ll5-" + name, w, h) { $0.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h)) }
}

let lines = [
    ("observation-0", "Cedar + Incense"), ("observation-1", "Cedar + Patchouli"),
    ("observation-2", "Bergamot + Gaiac Wood"), ("observation-3", "Bergamot + Oakmoss"),
    ("unchanged", "Cedar unchanged."), ("reference-name", "Cedar"),
    ("recipe-name-0", "Gaiac 10"), ("recipe-name-1", "Bergamote 22"),
    ("recipe-name-2", "Mousse de Chene 30"),
    ("recipe-0", "Gaiac Wood + Incense"), ("recipe-1", "Bergamot + Cedar"),
    ("recipe-2", "Oakmoss + Patchouli")
]
for (name, text) in lines {
    try export("ll5-" + name, 260, 36) { lettering(text, rect: CGRect(x: 0, y: 0, width: 260, height: 36), size: 29, in: $0) }
}
for letter in ["A", "B", "C", "D", "E", "F"] {
    try export("ll5-id-" + letter, 32, 32) { lettering(letter, rect: CGRect(x: 0, y: 0, width: 32, height: 32), size: 27, in: $0) }
    // A die-cut, punched paper tag authored as a vector asset, not a runtime UI rectangle.
    try export("ll5-token-" + letter, 64, 42) { ctx in
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 7, y: 3))
        for point in [CGPoint(x: 59, y: 4), CGPoint(x: 61, y: 31), CGPoint(x: 51, y: 39), CGPoint(x: 6, y: 37)] { path.addLine(to: point) }
        path.closeSubpath()
        ctx.setFillColor(NSColor(red: 0.89, green: 0.80, blue: 0.61, alpha: 1).cgColor)
        ctx.setStrokeColor(NSColor(red: 0.34, green: 0.23, blue: 0.12, alpha: 1).cgColor)
        ctx.setLineWidth(1.2); ctx.addPath(path); ctx.drawPath(using: .fillStroke)
        ctx.setFillColor(ink); ctx.fillEllipse(in: CGRect(x: 50, y: 29, width: 3, height: 3))
        lettering(letter, rect: CGRect(x: 12, y: 7, width: 35, height: 28), size: 27, in: ctx)
    }
}
for name in ["branch", "rings", "waves", "stars", "dashes", "mesh"] {
    try export("ll5-mark-" + name, 64, 64) { ctx in
        ctx.setStrokeColor(ink); ctx.setFillColor(ink); ctx.setLineWidth(2.3); ctx.setLineCap(.round); ctx.setLineJoin(.round)
        func stroke(_ points: [CGPoint]) {
            ctx.beginPath(); ctx.move(to: points[0]); points.dropFirst().forEach { ctx.addLine(to: $0) }; ctx.strokePath()
        }
        switch name {
        case "branch":
            stroke([CGPoint(x: 17, y: 8), CGPoint(x: 45, y: 56)])
            for i in 0..<4 {
                let x = CGFloat(22 + i * 6), y = CGFloat(17 + i * 10)
                stroke([CGPoint(x: x - 12, y: y + 8), CGPoint(x: x, y: y), CGPoint(x: x + 14, y: y + 2)])
            }
        case "rings":
            ctx.strokeEllipse(in: CGRect(x: 8, y: 8, width: 48, height: 48))
            ctx.strokeEllipse(in: CGRect(x: 13, y: 13, width: 38, height: 38))
        case "waves":
            for y in [17.0, 31.0, 45.0] {
                ctx.beginPath(); ctx.move(to: CGPoint(x: 7, y: y))
                ctx.addCurve(to: CGPoint(x: 57, y: y), control1: CGPoint(x: 24, y: y + 17), control2: CGPoint(x: 39, y: y - 17)); ctx.strokePath()
            }
        case "stars":
            for (x, y) in [(19.0, 43.0), (45.0, 37.0), (29.0, 17.0)] {
                stroke([CGPoint(x: x - 6, y: y), CGPoint(x: x + 6, y: y)])
                stroke([CGPoint(x: x, y: y - 7), CGPoint(x: x, y: y + 7)])
                ctx.fillEllipse(in: CGRect(x: x - 2, y: y - 2, width: 4, height: 4))
            }
        case "dashes":
            for i in 0..<3 { let y = CGFloat(16 + i * 16); stroke([CGPoint(x: 13, y: y), CGPoint(x: 47, y: y + 4)]) }
        default:
            for i in 0..<4 {
                let p = CGFloat(10 + i * 14)
                stroke([CGPoint(x: 9, y: p), CGPoint(x: 55, y: p)])
                stroke([CGPoint(x: p, y: 9), CGPoint(x: p, y: 55)])
            }
        }
    }
}
print("Exported perfume laboratory artwork and lettering.")
