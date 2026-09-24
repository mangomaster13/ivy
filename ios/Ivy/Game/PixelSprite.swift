import SwiftUI
import UIKit

/// One packed pixel atlas: row-major cells, nearest-neighbor crop at paint time.
enum SpriteSheet {
    /// Three compact 24x72 anchored sway poses, shared by both yard walls.
    case storyVine
    /// Twelve high-resolution scroll poses, 4 columns × 3 rows. Render at half world scale.
    case letterScroll

    /// Asset catalog name for the packed sheet.
    var imageName: String {
        switch self {
        case .storyVine: "story-vine-sheet"
        case .letterScroll: "story-scroll-sheet"
        }
    }

    /// One cell in game pixels.
    var cell: CGSize {
        switch self {
        case .storyVine: CGSize(width: 24, height: 72)
        case .letterScroll: CGSize(width: 448, height: 300)
        }
    }

    /// Texture density is independent of the logical size of a sprite pose.
    var texelsPerLogicalUnit: CGFloat { self == .storyVine ? 4 : 1 }

    /// Cells per row in the packed PNG.
    var columns: Int {
        switch self {
        case .storyVine: 3
        case .letterScroll: 4
        }
    }

}

/// Holds each catalog sheet in memory so frame cuts do not decode the PNG again.
@MainActor
enum SpriteAtlas {
    private static var sheets: [String: UIImage] = [:]
    private static var frames: [String: UIImage] = [:]

    /// Decode named sheets on first use (intro warm, first yard paint).
    static func warm(_ names: String...) {
        for name in names {
            _ = sheet(named: name)
        }
    }

    /// Large one-shot atlases do not need to stay in our decoded-frame cache after dismissal.
    static func release(_ sheet: SpriteSheet) {
        sheets.removeValue(forKey: sheet.imageName)
        frames = frames.filter { !$0.key.hasPrefix(sheet.imageName + ":") }
    }

    /// Crop one cell. Coordinates are game pixels times the bitmap scale.
    static func cell(sheet: SpriteSheet, index: Int) -> UIImage? {
        guard index >= 0 else { return nil }
        let key = "\(sheet.imageName):\(index)"
        if let cached = frames[key] { return cached }
        guard let image = self.sheet(named: sheet.imageName), let cgImage = image.cgImage else {
            return nil
        }
        let col = index % sheet.columns
        let row = index / sheet.columns
        let scale = image.scale * sheet.texelsPerLogicalUnit
        let rect = CGRect(
            x: CGFloat(col) * sheet.cell.width * scale,
            y: CGFloat(row) * sheet.cell.height * scale,
            width: sheet.cell.width * scale,
            height: sheet.cell.height * scale
        ).integral
        guard rect.maxX <= CGFloat(cgImage.width), rect.maxY <= CGFloat(cgImage.height) else {
            return nil
        }
        guard let cropped = cgImage.cropping(to: rect) else {
            return nil
        }
        let frame = UIImage(cgImage: cropped, scale: scale, orientation: image.imageOrientation)
        frames[key] = frame
        return frame
    }

    private static func sheet(named name: String) -> UIImage? {
        if let cached = sheets[name] {
            return cached
        }
        guard let image = UIImage(named: name) else {
            return nil
        }
        sheets[name] = image
        return image
    }
}

/// One nearest-neighbor cell from a packed sheet, sized in screen points.
struct PixelSpriteFrame: View {
    /// Packed atlas.
    let sheet: SpriteSheet
    /// Row-major cell index.
    let index: Int
    /// Points per game pixel (shared with `PixelCanvas`).
    let scale: CGFloat

    var body: some View {
        let width = sheet.cell.width * scale
        let height = sheet.cell.height * scale
        Group {
            if let image = SpriteAtlas.cell(sheet: sheet, index: index) {
                Image(uiImage: image)
                    .interpolation((sheet == .letterScroll || sheet == .storyVine) ? .high : .none)
                    .resizable()
                    .frame(width: width, height: height)
            }
        }
        .frame(width: width, height: height)
        .transaction { $0.animation = nil }
    }
}
