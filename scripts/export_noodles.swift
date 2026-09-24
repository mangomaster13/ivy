#!/usr/bin/env swift
import AppKit
import CoreText
import ImageIO
import UniformTypeIdentifiers

// Production export only: never builds or launches the game. All scales use source art.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = root.appendingPathComponent("art/noodles-menu-design/source")
let catalog = root.appendingPathComponent("ios/Ivy/Assets.xcassets/Scenes/BigTop")
func read(_ name: String) -> CGImage {
    let data = CGImageSourceCreateWithURL(source.appendingPathComponent(name + ".png") as CFURL, nil)!
    return CGImageSourceCreateImageAtIndex(data, 0, nil)!
}
func canvas(_ width: Int, _ height: Int) -> CGContext {
    CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
              space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}
func export(_ name: String, width: Int, height: Int, draw: (CGContext, Int) -> Void) throws {
    let folder = catalog.appendingPathComponent(name + ".imageset")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    var variants: [[String: String]] = []
    for scale in 1...3 {
        let context = canvas(width * scale, height * scale)
        context.interpolationQuality = .high
        draw(context, scale)
        let filename = name + (scale == 1 ? "" : "@\(scale)x") + ".png"
        let target = CGImageDestinationCreateWithURL(folder.appendingPathComponent(filename) as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(target, context.makeImage()!, nil)
        precondition(CGImageDestinationFinalize(target))
        variants.append(["filename": filename, "idiom": "universal", "scale": "\(scale)x"])
    }
    try JSONSerialization.data(withJSONObject: ["images": variants, "info": ["author": "xcode", "version": 1]], options: [.prettyPrinted, .sortedKeys])
        .write(to: folder.appendingPathComponent("Contents.json"))
}
for name in ["counter", "counter-open", "menu", "ledger", "mirror"] {
    let original = read(name)
    try export("bt3-" + name, width: 640, height: 320) { context, scale in
        context.draw(original, in: CGRect(x: 0, y: 0, width: 640 * scale, height: 320 * scale))
    }
}

// Atlas is authored with transparent margins. Slice, then trim alpha, never redraw objects.
let atlas = read("sprites")
let symbolNames = ["bowl", "cup", "fish", "spoon", "leaf", "goose", "chopsticks", "teapot"]
var regions: [(String, CGRect)] = symbolNames.enumerated().map { index, name in
    ("bt3-symbol-" + name, CGRect(x: Double(index % 4) / 4, y: Double(index / 4) / 3, width: 0.25, height: 1.0 / 3))
}
regions += [
    ("tool-bigTopPencil", CGRect(x: 0, y: 0.71, width: 0.25, height: 0.28)),
    ("tool-bigTopInspectionMirror", CGRect(x: 0.25, y: 0.71, width: 0.28, height: 0.28)),
    ("bt3-wheel", CGRect(x: 0.54, y: 0.70, width: 0.20, height: 0.29))
]
for (name, region) in regions {
    let rect = CGRect(x: region.minX * Double(atlas.width), y: region.minY * Double(atlas.height),
                      width: region.width * Double(atlas.width), height: region.height * Double(atlas.height)).integral
    let crop = atlas.cropping(to: rect)!
    let context = canvas(crop.width, crop.height)
    context.draw(crop, in: CGRect(x: 0, y: 0, width: crop.width, height: crop.height))
    let bytes = context.data!.assumingMemoryBound(to: UInt8.self)
    var left = crop.width, right = 0, bottom = crop.height, top = 0
    for y in 0..<crop.height {
        for x in 0..<crop.width where bytes[(y * crop.width + x) * 4 + 3] > 8 {
            left = min(left, x); right = max(right, x); bottom = min(bottom, y); top = max(top, y)
        }
    }
    precondition(right > left && top > bottom, "Empty sprite: " + name)
    let trimmed = context.makeImage()!.cropping(to: CGRect(x: left, y: bottom, width: right - left + 1, height: top - bottom + 1))!
    let width = 160
    let height = max(1, Int((Double(trimmed.height) / Double(trimmed.width) * Double(width)).rounded()))
    try export(name, width: width, height: height) { destination, scale in
        destination.draw(trimmed, in: CGRect(x: 0, y: 0, width: width * scale, height: height * scale))
    }
    print("\(name): source alpha bounds \(left),\(bottom)–\(right),\(top)")
}

// Independent Juniper lettering supports persistent random order; no runtime native labels.
let fontURL = root.appendingPathComponent("ios/Ivy/Fonts/Juniper-Regular.ttf")
CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
let descriptors = CTFontManagerCreateFontDescriptorsFromURL(fontURL as CFURL) as! [CTFontDescriptor]
let font = CTFontCreateWithFontDescriptor(descriptors[0], 23, nil)
let dishes: [(Int, String)] = [(0, "Half Roast\nGoose"), (1, "Quarter Roast\nGoose"), (5, "Steamed Rice"),
    (6, "Rice Noodles"), (7, "Egg Fried Rice"), (8, "Wonton Noodles"), (15, "Lemon Tea"),
    (16, "Ovaltine"), (17, "Milk Tea"), (19, "Lemon Water")]
for (id, title) in dishes {
    try export("bt3-dish-\(id)", width: 188, height: 52) { context, scale in
        context.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
        let lines = title.components(separatedBy: "\n")
        for (index, text) in lines.enumerated() {
            let string = NSAttributedString(string: text, attributes: [
                NSAttributedString.Key(kCTFontAttributeName as String): font,
                NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(red: 0.17, green: 0.10, blue: 0.06, alpha: 1)
            ])
            let line = CTLineCreateWithAttributedString(string)
            let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
            context.textPosition = CGPoint(x: 2 - bounds.minX, y: (lines.count == 1 ? 25 : 39 - CGFloat(index) * 25) - bounds.midY)
            CTLineDraw(line, context)
        }
    }
}
print("Exported Noodles backgrounds, tools, symbols and ten menu lettering assets.")
