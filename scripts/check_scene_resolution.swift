#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO

// Full-scene assets must preserve source detail, rather than repeat a tiny 1x master.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let entries: [(String, String, String)] = [
    ("yard", "yard-closed", "Scenes/Yard/story-yard-base"),
    ("yard", "yard-open", "Scenes/Yard/story-yard-open"),
    ("hall", "hall", "Scenes/Hall/story-hall")
] + ["plane", "corridor", "corridor-open", "bedroom", "gelato"].map {
    let module = ["plane": "Plane", "corridor": "Corridor", "corridor-open": "Corridor",
                  "bedroom": "Bedroom", "gelato": "Gelato"][$0]!
    return ("wonderland", $0, "Scenes/" + module + "/hk-" + $0)
} + ["yard-garden", "hall-desk", "plane-window", "corridor-cart", "corridor-mirror", "bedroom-desk", "gelato-bench", "gelato-service"].map {
    let module = ["yard": "Yard", "hall": "Hall", "plane": "Plane", "corridor": "Corridor",
                  "bedroom": "Bedroom", "gelato": "Gelato"][String($0.split(separator: "-").first!)]!
    return ("exploration", $0, "Scenes/" + module + "/explore-" + $0)
}
func load(_ path: String) -> CGImage {
    let source = CGImageSourceCreateWithURL(root.appendingPathComponent(path) as CFURL, nil)!
    return CGImageSourceCreateImageAtIndex(source, 0, nil)!
}
var failures = 0
for (folder, original, asset) in entries {
    let name = String(asset.split(separator: "/").last!)
    let source = load("art/\(folder)/source/\(original).png")
    let image = load("ios/Ivy/Assets.xcassets/\(asset).imageset/\(name)@3x.png")
    let c = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8,
                      bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    let pixels = c.data!.assumingMemoryBound(to: UInt32.self)
    var repeated = 0, total = 0
    for y in stride(from: 0, to: image.height - 2, by: 3) {
        for x in stride(from: 0, to: image.width - 2, by: 3) {
            let first = pixels[y * image.width + x]
            if (0..<3).allSatisfy({ dy in (0..<3).allSatisfy { dx in pixels[(y+dy)*image.width+x+dx] == first } }) { repeated += 1 }
            total += 1
        }
    }
    let ratio = Double(repeated) / Double(total)
    let pass = image.width >= source.width && image.height >= source.height && ratio < 0.95
    print("\(pass ? "PASS" : "FAIL") \(name): source \(source.width)x\(source.height), 3x \(image.width)x\(image.height), repeated 3x3 blocks \(Int(ratio*100))%")
    if !pass { failures += 1 }
}
if failures > 0 { exit(1) }
