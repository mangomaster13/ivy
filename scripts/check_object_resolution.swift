#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO

// Actual shipped textures: enough pixels for scaled world objects, and no repeated tiny masters.
let catalog = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("ios/Ivy/Assets.xcassets")
let objects: [(String, Int)] = [
    ("Scenes/Hall/hall-vuori-world", 360), ("Scenes/Bedroom/rose-world", 315),
    ("Scenes/Bedroom/rose-world-complete", 315), ("Scenes/Bedroom/rose-petal-world", 90),
    ("Scenes/Hall/hall-vuori-detail", 1000), ("Scenes/Yard/story-cloud", 1200),
    ("Scenes/Yard/story-vine-sheet", 800), ("Scenes/Yard/icon-letter", 96), ("Scenes/Hall/icon-vuori", 96)
] + ["plane", "keycard", "city", "rose", "gelato"].map { ("Keepsakes/icon-" + $0, 96) }
var failures = 0
for (asset, minWidth) in objects {
    let name = String(asset.split(separator: "/").last!)
    let url = catalog.appendingPathComponent(asset + ".imageset/" + name + "@3x.png")
    let source = CGImageSourceCreateWithURL(url as CFURL, nil)!
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
    let c = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8,
                      bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    let bytes = c.data!.assumingMemoryBound(to: UInt8.self)
    let pixels = c.data!.assumingMemoryBound(to: UInt32.self)
    var flat = 0, total = 0
    for y in stride(from: 0, to: image.height - 2, by: 3) {
        for x in stride(from: 0, to: image.width - 2, by: 3) {
            // Ignore transparent padding; otherwise cutouts look artificially low-detail.
            guard bytes[((y + 1) * image.width + x + 1) * 4 + 3] > 32 else { continue }
            let first = pixels[y * image.width + x]
            if (0..<3).allSatisfy({ dy in (0..<3).allSatisfy { dx in pixels[(y+dy)*image.width+x+dx] == first } }) { flat += 1 }
            total += 1
        }
    }
    let ratio = Double(flat) / Double(max(1, total))
    let pass = image.width >= minWidth && total > 0 && ratio < 0.95
    print("\(pass ? "PASS" : "FAIL") \(name): \(image.width)x\(image.height), repeated visible 3x3 blocks \(Int(ratio * 100))%")
    if !pass { failures += 1 }
}
if failures > 0 { exit(1) }
