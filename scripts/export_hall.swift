#!/usr/bin/env swift
// Package ImageGen originals. Pixel world and high-resolution close-ups use separate export paths.
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let art = root.appendingPathComponent("art/hall")
let source = art.appendingPathComponent("source")
let catalog = root.appendingPathComponent("ios/Ivy/Assets.xcassets")
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
var manifest: [[String: Any]] = []

func context(_ width: Int, _ height: Int, smooth: Bool = false) -> CGContext {
    let c = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                      bytesPerRow: width * 4, space: colorSpace,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.interpolationQuality = smooth ? .high : .none
    c.setShouldAntialias(smooth)
    return c
}

func load(_ name: String) -> CGImage {
    let url = source.appendingPathComponent(name + ".png")
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
        fatalError("Missing source: \(url.path)")
    }
    return image
}

func trim(_ image: CGImage) -> CGImage {
    let c = context(image.width, image.height)
    c.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    let bytes = c.data!.assumingMemoryBound(to: UInt8.self)
    var x0 = image.width, y0 = image.height, x1 = 0, y1 = 0
    for y in 0..<image.height {
        for x in 0..<image.width where bytes[(y * image.width + x) * 4 + 3] > 32 {
            x0 = min(x0, x); y0 = min(y0, y); x1 = max(x1, x); y1 = max(y1, y)
        }
    }
    precondition(x0 <= x1 && y0 <= y1, "Empty sprite")
    return image.cropping(to: CGRect(x: x0, y: y0, width: x1 - x0 + 1, height: y1 - y0 + 1))!
}

func resize(_ image: CGImage, _ width: Int, _ height: Int, smooth: Bool = false) -> CGImage {
    let c = context(width, height, smooth: smooth)
    c.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return c.makeImage()!
}

func png(_ image: CGImage, _ url: URL) throws {
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    precondition(CGImageDestinationFinalize(dest), "PNG export failed")
}

func export(name: String, group: String, width: Int, height: Int, frames: Int = 1,
            pipeline: String, render: (Int) -> CGImage) throws {
    let folder = catalog.appendingPathComponent(group).appendingPathComponent(name + ".imageset")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    var variants: [[String: String]] = []
    for scale in 1...3 {
        let filename = name + (scale == 1 ? "" : "@\(scale)x") + ".png"
        let image = render(scale)
        precondition(image.width == width * scale && image.height == height * scale)
        try png(image, folder.appendingPathComponent(filename))
        variants.append(["filename": filename, "idiom": "universal", "scale": "\(scale)x"])
    }
    let json: [String: Any] = ["images": variants, "info": ["author": "xcode", "version": 1],
                              "properties": ["template-rendering-intent": "original"]]
    try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        .write(to: folder.appendingPathComponent("Contents.json"))
    manifest.append(["name": name, "pointWidth": width, "pointHeight": height,
                     "scales": [1, 2, 3], "frames": frames, "group": group, "pipeline": pipeline])
    print("\(name): \(width)x\(height) pt / \(frames) frames / \(pipeline)")
}


let group = "Scenes/Hall"
let hall = load("hall")
try export(name: "story-hall", group: group, width: 960, height: 480, pipeline: "direct original each scale; independent of world coordinates") {
    resize(hall, 960 * $0, 480 * $0, smooth: true)
}
let garment = trim(load("vuori"))
try export(name: "hall-vuori-world", group: group, width: 160, height: 160, pipeline: "direct original each scale; world size remains 40x40") {
    resize(garment, 160 * $0, 160 * $0, smooth: true)
}
try export(name: "hall-vuori-detail", group: group, width: 400, height: 400, pipeline: "direct original each scale") {
    resize(garment, 400 * $0, 400 * $0, smooth: true)
}
for inactive in [false, true] {
    try export(name: inactive ? "icon-vuori-off" : "icon-vuori", group: group, width: 32, height: 32, pipeline: "direct original each scale") { scale in
        let c = context(32 * scale, 32 * scale, smooth: true)
        c.draw(garment, in: CGRect(x: 2 * scale, y: 2 * scale, width: 28 * scale, height: 28 * scale))
        if inactive {
            c.setBlendMode(.sourceIn)
            c.setFillColor(CGColor(red: 0.12, green: 0.13, blue: 0.18, alpha: 1))
            c.fill(CGRect(x: 0, y: 0, width: 32 * scale, height: 32 * scale))
        }
        return c.makeImage()!
    }
}
try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted,.sortedKeys]).write(to: art.appendingPathComponent("assets.json"))
