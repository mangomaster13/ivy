#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = root.appendingPathComponent("art/exploration/source")
let catalog = root.appendingPathComponent("ios/Ivy/Assets.xcassets")
let info: [String: Any] = ["info": ["author": "xcode", "version": 1]]
let names = ["yard-garden", "hall-desk", "plane-window", "corridor-cart", "corridor-mirror", "bedroom-desk", "gelato-bench", "gelato-service"]
let sceneGroups = ["yard-garden": "Yard", "hall-desk": "Hall", "plane-window": "Plane",
                   "corridor-cart": "Corridor", "corridor-mirror": "Corridor", "bedroom-desk": "Bedroom",
                   "gelato-bench": "Gelato", "gelato-service": "Gelato"]
func read(_ url: URL) -> CGImage {
    let src = CGImageSourceCreateWithURL(url as CFURL, nil)!
    return CGImageSourceCreateImageAtIndex(src, 0, nil)!
}
func export(_ image: CGImage, name: String, width: Int, height: Int) throws {
    let group: String
    if name.hasPrefix("explore-") { group = "Scenes/" + sceneGroups[String(name.dropFirst(8))]! }
    else if name == "tool-notebook" { group = "Shared/Notes" }
    else { group = "Shared/Tools" }
    let parent = catalog.appendingPathComponent(group)
    let folder = parent.appendingPathComponent(name + ".imageset")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    try JSONSerialization.data(withJSONObject: info, options: .prettyPrinted).write(to: parent.appendingPathComponent("Contents.json"))
    var variants: [[String: String]] = []
    for scale in 1...3 {
        let w = width * scale, h = height * scale
        let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        c.interpolationQuality = .high
        c.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        let filename = name + (scale == 1 ? "" : "@\(scale)x") + ".png"
        let dest = CGImageDestinationCreateWithURL(folder.appendingPathComponent(filename) as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, c.makeImage()!, nil)
        precondition(CGImageDestinationFinalize(dest))
        variants.append(["filename": filename, "idiom": "universal", "scale": "\(scale)x"])
    }
    try JSONSerialization.data(withJSONObject: ["images": variants, "info": ["author": "xcode", "version": 1]], options: [.prettyPrinted, .sortedKeys]).write(to: folder.appendingPathComponent("Contents.json"))
}
for name in names {
    let image = read(source.appendingPathComponent(name + ".png"))
    precondition(image.width >= 1700 && image.height >= 850, "Do not package thumbnail scene art")
    try export(image, name: "explore-" + name, width: 960, height: 480)
    print("PASS \(name): source \(image.width)×\(image.height), direct 1x/2x/3x")
}
let toolURL = source.appendingPathComponent("tools.png")
if FileManager.default.fileExists(atPath: toolURL.path) {
    let sheet = read(toolURL)
    let tools = ["brassKey", "pencil", "magnifier", "cloth", "sewingKit", "coin", "scoop", "notebook"]
    for (index, name) in tools.enumerated() {
        let rect = CGRect(x: (index % 4) * sheet.width / 4, y: (index / 4) * sheet.height / 2, width: sheet.width / 4, height: sheet.height / 2)
        try export(sheet.cropping(to: rect)!, name: "tool-" + name, width: 160, height: 160)
    }
}
