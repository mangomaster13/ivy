#!/usr/bin/env swift
import AppKit
import CoreText
import ImageIO
import UniformTypeIdentifiers

// Asset production only; no game build or device validation.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = root.appendingPathComponent("art/finale/letters/source")
let catalog = root.appendingPathComponent("ios/Ivy/Assets.xcassets/Scenes")
func load(_ name: String) -> CGImage {
    let url = source.appendingPathComponent(name + ".png")
    return CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL, nil)!, 0, nil)!
}
func context(_ width: Int, _ height: Int) -> CGContext {
    CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
              space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}
func png(_ image: CGImage, _ url: URL) throws {
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, nil)
    precondition(CGImageDestinationFinalize(destination), "PNG export failed")
}
func export(_ image: CGImage, _ name: String, group: String = "Hall", width: Int = 592) throws {
    let folder = catalog.appendingPathComponent(group + "/" + name + ".imageset")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    var entries: [[String: String]] = []
    for scale in 1...3 {
        let w = width * scale
        let h = Int((Double(w) * Double(image.height) / Double(image.width)).rounded())
        let c = context(w, h)
        c.interpolationQuality = .high
        c.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        let filename = name + (scale == 1 ? "" : "@\(scale)x") + ".png"
        try png(c.makeImage()!, folder.appendingPathComponent(filename))
        entries.append(["filename": filename, "idiom": "universal", "scale": "\(scale)x"])
    }
    try JSONSerialization.data(withJSONObject: ["images": entries, "info": ["author": "xcode", "version": 1]],
                               options: [.prettyPrinted, .sortedKeys]).write(to: folder.appendingPathComponent("Contents.json"))
}

try export(load("closed"), "letter-sealed")
try export(load("envelope"), "story-envelope", group: "Yard", width: 480)
for state in ["idle", "lever", "envelope-half", "envelope-full", "heart"] {
    try export(load("machine-" + state), "lottery-machine-" + state)
}

CTFontManagerRegisterFontsForURL(root.appendingPathComponent("ios/Ivy/Fonts/Kiddos.ttf") as CFURL, .process, nil)
let paper = load("paper")
// Original 1774×887 artwork: paper x=400...1390, y=58...808.
// Lettering stays x=565...1285, y=176...745, clear of ivy and paper edges.
let letters: [(String, [(String, CGFloat, CGFloat)])] = [
    ("letter-finale", [
        ("One day, then forever.", 182, 54),
        ("I’ve loved these days with you.", 332, 40),
        ("I want all the ordinary ones ahead.", 391, 40),
        ("One day, then another—", 450, 40),
        ("until we call it forever.", 509, 40),
        ("Love always leads me home—to you.", 655, 40)
    ]),
    ("letter-first", [
        ("for you, always", 192, 58),
        ("A little house full of us.", 357, 46),
        ("with love,", 505, 44),
        ("in every room", 561, 44),
        ("fold this moment away", 692, 32)
    ])
]
for (name, lines) in letters {
    let c = context(paper.width, paper.height)
    c.draw(paper, in: CGRect(x: 0, y: 0, width: paper.width, height: paper.height))
    c.scaleBy(x: CGFloat(paper.width) / 1774, y: CGFloat(paper.height) / 887)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: c, flipped: false)
    for (text, top, size) in lines {
        let font = NSFont(name: "KidDos-Font", size: size)!
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: NSColor(red: 0.17, green: 0.13, blue: 0.09, alpha: 1),
            .paragraphStyle: paragraph
        ]
        // A production guard against copy/font changes overflowing the writable surface.
        precondition((text as NSString).size(withAttributes: attributes).width <= 720, "Letter line exceeds paper")
        (text as NSString).draw(in: CGRect(x: 565, y: 887 - top - 80, width: 720, height: 80), withAttributes: attributes)
    }
    NSGraphicsContext.restoreGraphicsState()
    try png(c.makeImage()!, source.appendingPathComponent(name + ".png"))
    try export(c.makeImage()!, name)
}
