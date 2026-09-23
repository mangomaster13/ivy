#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = root.appendingPathComponent("art/memories/source")
let catalog = root.appendingPathComponent("ios/Ivy/Assets.xcassets")
let info: [String: Any] = ["info": ["author": "xcode", "version": 1]]
func group(for name: String) -> String {
    let stem = name.replacingOccurrences(of: "memory-", with: "")
    switch stem {
    case "bath", "blanket-open", "blanket-closed", "box", "box-closed", "box-puzzle",
         "bouquet-final", "bouquet-folded", "bouquet-half", "bouquet-unwrapped": return "Scenes/Bedroom"
    case "cabinet", "cabinet-closed", "gelato-cup", "flavor-0", "flavor-1", "flavor-2", "flavor-3": return "Scenes/Gelato"
    case "cinema", "cinema-ticket": return "Scenes/Cinema"
    case "drawer", "drawer-closed", "shirt-final": return "Scenes/Hall"
    case "ferris", "ferris-ticket": return "Scenes/Ferris"
    case "linen", "linen-empty": return "Scenes/Corridor"
    case "noodle", "order-slip": return "Scenes/BigTop"
    case "perfume", "scents": return "Scenes/LeLabo"
    case "pot", "pot-covered": return "Scenes/Yard"
    case "sunset": return "Scenes/Sunset"
    case "taxi", "taxi-receipt": return "Scenes/Taxi"
    case "ticket": return "Scenes/Plane"
    case "twine": return "Shared/Tools"
    default: fatalError("Unclassified memory asset: \(name)")
    }
}
func read(_ url: URL) -> CGImage {
    let src = CGImageSourceCreateWithURL(url as CFURL, nil)!
    return CGImageSourceCreateImageAtIndex(src, 0, nil)!
}
func export(_ image: CGImage, name: String, width: Int, height: Int) throws {
    let parent = catalog.appendingPathComponent(group(for: name))
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
for file in try FileManager.default.contentsOfDirectory(at: source, includingPropertiesForKeys: nil).filter({ $0.pathExtension == "png" && !["bouquet", "bouquet-clean", "shirt", "flavors", "supermarket"].contains($0.deletingPathExtension().lastPathComponent) }) {
    let image = read(file)
    let name = file.deletingPathExtension().lastPathComponent
    precondition(image.width >= 1000, "Source must be full resolution")
    let width = image.width > image.height ? 960 : 480
    let height = Int(Double(width) * Double(image.height) / Double(image.width))
    try export(image, name: "memory-" + name, width: width, height: height)
    print("PASS \(name): \(image.width)x\(image.height), direct 1x/2x/3x")
}

let flavorURL = source.appendingPathComponent("flavors.png")
if FileManager.default.fileExists(atPath: flavorURL.path) {
    let image = read(flavorURL)
    for i in 0..<4 {
        let rect = CGRect(x: (i % 2) * image.width / 2, y: (i / 2) * image.height / 2, width: image.width / 2, height: image.height / 2)
        try export(image.cropping(to: rect)!, name: "memory-flavor-\(i)", width: 240, height: 240)
    }
}
