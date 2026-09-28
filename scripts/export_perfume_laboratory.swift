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
    ctx.textMatrix = .identity
    ctx.textPosition = .zero
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
// Compose the physical pages at export time. The game scales one complete spread,
// so lettering cannot acquire a different origin or fitting transform from its paper.
let blankBook = load(root.appendingPathComponent("ios/Ivy/Assets.xcassets/Scenes/LeLabo/ll4-notes.imageset/ll4-notes@3x.png"))
let swatchBook = load(source.appendingPathComponent("record-swatches.png"))
func artwork(_ name: String) -> CGImage {
    load(catalog.appendingPathComponent("\(name).imageset/\(name)@3x.png"))
}
func place(_ image: CGImage, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, in ctx: CGContext) {
    ctx.draw(image, in: CGRect(x: x - width / 2, y: 160 - y - height / 2, width: width, height: height))
}
let observationMarks = [["branch", "rings"], ["branch", "waves"], ["stars", "dashes"], ["stars", "mesh"]]
for page in ["wood", "citrus", "recipes", "reference"] {
    try export("ll5-record-" + page, 590, 295) { ctx in
        ctx.scaleBy(x: 590.0 / 320, y: 590.0 / 320)
        ctx.draw(page == "wood" || page == "citrus" ? swatchBook : blankBook,
                 in: CGRect(x: 0, y: 0, width: 320, height: 160))
        if page == "wood" || page == "citrus" {
            for side in 0..<2 {
                let observation = (page == "citrus" ? 2 : 0) + side
                let x: CGFloat = side == 0 ? 91 : 231
                place(artwork("ll5-observation-\(observation)"), x: x, y: 31, width: 112, height: 15.5, in: ctx)
                for mark in 0..<2 {
                    let markX: CGFloat = side == 0 ? (mark == 0 ? 62 : 121) : (mark == 0 ? 201 : 260)
                    place(artwork("ll5-mark-" + observationMarks[observation][mark]), x: markX, y: 69, width: 30, height: 30, in: ctx)
                }
            }
            if page != "citrus" {
                place(artwork("ll5-unchanged"), x: 87, y: 114, width: 99, height: 14, in: ctx)
                lettering("Cedar =", rect: CGRect(x: 184, y: 35, width: 65, height: 16), size: 12, in: ctx)
                place(artwork("ll5-mark-branch"), x: 263, y: 117, width: 24, height: 24, in: ctx)
            }
        } else if page == "recipes" {
            let ingredients = [["Gaiac Wood", "+ Incense"], ["Bergamot", "+ Cedar"], ["Oakmoss", "+ Patchouli"]]
            for index in 0..<3 {
                let x: CGFloat = index < 2 ? 87 : 234
                let y: CGFloat = index == 1 ? 89 : 32
                place(artwork("ll5-recipe-name-\(index)"), x: x, y: y, width: 112, height: 15.5, in: ctx)
                for row in 0..<2 {
                    lettering(ingredients[index][row], rect: CGRect(x: x - 52, y: 160 - y - 26 - CGFloat(row) * 16,
                                                                   width: 104, height: 14), size: 11, in: ctx)
                }
            }
        } else {
            place(artwork("ll5-reference-name"), x: 87, y: 70, width: 100, height: 14, in: ctx)
            place(artwork("ll5-mark-branch"), x: 234, y: 78, width: 44, height: 44, in: ctx)
        }
    }
}

// Source alpha is transparent outside the silhouette; trim only empty margins.
let strip = load(source.appendingPathComponent("scent-strip.png"))
    .cropping(to: CGRect(x: 280, y: 50, width: 472, height: 1390))!
for letter in ["A", "B", "C", "D", "E", "F"] {
    try export("ll5-token-" + letter, 48, 144) { ctx in
        ctx.draw(strip, in: CGRect(x: 0, y: 0, width: 48, height: 144))
        lettering(letter, rect: CGRect(x: 17, y: 100, width: 25, height: 28), size: 25, in: ctx)
    }
}
print("Exported perfume laboratory artwork and complete record pages.")
