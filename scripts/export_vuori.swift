#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Every device scale reads the full-resolution original, never a catalog variant.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = root.appendingPathComponent("art/vuori/source/vuori-desk.png")
let imageSource = CGImageSourceCreateWithURL(source as CFURL, nil)!
let original = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)!
let folder = root.appendingPathComponent("ios/Ivy/Assets.xcassets/Scenes/Hall/vuori-desk.imageset")
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
var variants: [[String: String]] = []
for scale in 1...3 {
    let width = 800 * scale, height = 400 * scale
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                            bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.interpolationQuality = .high
    context.draw(original, in: CGRect(x: 0, y: 0, width: width, height: height))
    let filename = "vuori-desk" + (scale == 1 ? "" : "@\(scale)x") + ".png"
    let destination = CGImageDestinationCreateWithURL(folder.appendingPathComponent(filename) as CFURL,
                                                       UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    precondition(CGImageDestinationFinalize(destination))
    variants.append(["filename": filename, "idiom": "universal", "scale": "\(scale)x"])
}
try JSONSerialization.data(withJSONObject: ["images": variants, "info": ["author": "xcode", "version": 1]],
                           options: [.prettyPrinted, .sortedKeys])
    .write(to: folder.appendingPathComponent("Contents.json"))
print("Exported vuori-desk at 1x/2x/3x from \(original.width)×\(original.height) original")
