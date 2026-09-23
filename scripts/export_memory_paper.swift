#!/usr/bin/env swift
import AppKit
import CoreText
import ImageIO
import UniformTypeIdentifiers
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let dir = root.appendingPathComponent("art/memories/source")
for font in (try? FileManager.default.contentsOfDirectory(at: root.appendingPathComponent("ios/Ivy/Fonts"), includingPropertiesForKeys: nil)) ?? [] {
    CTFontManagerRegisterFontsForURL(font as CFURL, .process, nil)
}
let pieces = [
    ("ferris-ticket", "TWO SEATS ABOVE THE CITY", "MOON + LEAF", "one carriage, together", "a little closer to the sky"),
    ("ticket", "OUR FIRST JOURNEY", "HGH  →  HKG", "HANGZHOU                         HONG KONG", "one journey, together"),
    ("cinema-ticket", "TWO SEATS, ONE MEMORY", "HOPE", "C3                         C4", "closer in the dark"),
    ("order-slip", "A LITTLE HONG KONG MEMORY", "BIG TOP", "an order worth keeping", "the name is the joke"),
    ("taxi-receipt", "ONE LAST RIDE", "STAY", "no hurry home", "a little longer, with you")
]
for (name, heading, route, detail, note) in pieces {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1800, pixelsHigh: 900, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSColor(calibratedRed: 0.94, green: 0.88, blue: 0.73, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 35,y: 45,width: 1730,height: 810), xRadius: 26,yRadius: 26).fill()
    let ink = NSColor(calibratedRed: 0.08, green: 0.23, blue: 0.24, alpha: 1)
    ink.setStroke(); let border = NSBezierPath(roundedRect: NSRect(x: 65,y: 75,width: 1670,height: 750),xRadius: 20,yRadius: 20); border.lineWidth=4; border.stroke()
    func text(_ string:String,_ y:CGFloat,_ size:CGFloat,_ script:Bool=false) {
        let style=NSMutableParagraphStyle();style.alignment = .center
        let font = NSFont(name:script ? "Juniper-Regular" : "KidDos-Font",size:size) ?? NSFont.systemFont(ofSize:size)
        (string as NSString).draw(in:NSRect(x:120,y:y,width:1560,height:size*1.8),withAttributes:[.font:font,.foregroundColor:ink,.paragraphStyle:style])
    }
    text(heading,660,48);text(route,390,150);text(detail,260,45);text(note,125,62,true)
    let line=NSBezierPath();line.move(to:NSPoint(x:150,y:350));line.line(to:NSPoint(x:1650,y:350));line.lineWidth=2;line.stroke()
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using:.png,properties:[:])!.write(to:dir.appendingPathComponent(name+".png"))
}
