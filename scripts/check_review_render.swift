import Foundation
import CoreGraphics
import ImageIO
// Reject screenshots captured before a review's first rendered frame.
let url = URL(fileURLWithPath: CommandLine.arguments[1])
guard let src = CGImageSourceCreateWithURL(url as CFURL, nil), let image = CGImageSourceCreateImageAtIndex(src, 0, nil) else { exit(1) }
let c = CGContext(data: nil, width: 128, height: 64, bitsPerComponent: 8, bytesPerRow: 512,
                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
c.draw(image, in: CGRect(x: 0, y: 0, width: 128, height: 64))
let p = c.data!.assumingMemoryBound(to: UInt8.self)
var lit = 0
for i in 0..<(128 * 64) {
    if Int(p[i * 4]) + Int(p[i * 4 + 1]) + Int(p[i * 4 + 2]) > 190 { lit += 1 }
}
exit(lit > 400 ? 0 : 1)
