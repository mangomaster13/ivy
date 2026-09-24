import SwiftUI
import UIKit
import Vision

struct DictionaryInkPoint: Codable, Equatable, Sendable {
    var x: Double
    var y: Double
}

struct DictionaryProgress: Codable, Equatable {
    var strokes: [[DictionaryInkPoint]] = []
    var solved = false

    init(strokes: [[DictionaryInkPoint]] = [], solved: Bool = false) {
        self.strokes = strokes
        self.solved = solved
    }

    private enum CodingKeys: String, CodingKey { case strokes, solved }

    init(from decoder: Decoder) throws {
        // A damaged local draft must not invalidate the rest of a player's save.
        guard let values = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        solved = (try? values.decode(Bool.self, forKey: .solved)) ?? false
        let saved = (try? values.decode([[DictionaryInkPoint]].self, forKey: .strokes)) ?? []
        strokes = saved.filter { !$0.isEmpty && $0.allSatisfy {
            $0.x.isFinite && $0.y.isFinite && (0...1).contains($0.x) && (0...1).contains($0.y)
        } }
    }
}

extension GameStore {
    var dictionary: DictionaryProgress {
        get { memories.dictionary ?? DictionaryProgress() }
        set { memories.dictionary = newValue }
    }

    var canWriteDictionary: Bool {
        !isIntro && !isHallTransitioning && collectingEgg == nil
            && room == .dictionary && overlay == .memory(.dictionary) && !dictionary.solved
            && !collected.contains(.dictionary) && selectedTool == .fountainPen
            && exploration.tools.contains(.fountainPen)
    }

    func takeDictionaryPen() {
        guard canExplore, room == .dictionary, !dictionary.solved,
              !collected.contains(.dictionary), !memories.picked.contains(.fountainPen) else { return }
        memories.picked.insert(.fountainPen)
        acquire(.fountainPen)
        persistNow()
    }

    func addDictionaryPoint(_ point: DictionaryInkPoint, startingStroke: Bool) {
        guard canWriteDictionary, point.x.isFinite, point.y.isFinite,
              (0...1).contains(point.x), (0...1).contains(point.y) else { return }
        if startingStroke { dictionary.strokes.append([point]) }
        else if let index = dictionary.strokes.indices.last { dictionary.strokes[index].append(point) }
        dismissSceneHint()
        schedulePersist()
    }

    func undoDictionaryStroke() {
        guard canWriteDictionary, !dictionary.strokes.isEmpty else { return }
        dictionary.strokes.removeLast()
        dismissSceneHint()
        persistNow()
    }

    func submitDictionary() async {
        guard canWriteDictionary, !dictionary.strokes.isEmpty else { return }
        let submitted = dictionary.strokes
        do {
            // Only the player's ink is sent to Vision, never the printed clues or answer hints.
            let recognized = try await Task.detached(priority: .userInitiated) {
                try DictionaryHandwriting.read(submitted)
            }.value
            guard !Task.isCancelled, canWriteDictionary, dictionary.strokes == submitted else { return }
            guard recognized == "FOREVER" else {
                dismissSceneHint()
                return
            }
            dictionary.solved = true
            memories.opened.insert("dictionary")
            collected.insert(.dictionary)
            consume(.fountainPen)
            persistNow()
            replayKeepsake(.dictionary)
        } catch {
            guard !Task.isCancelled, canWriteDictionary, dictionary.strokes == submitted else { return }
            dismissSceneHint()
        }
    }

    func migrateDictionary() {
        if memories.opened.remove("sunset") != nil { memories.opened.insert("dictionary") }
        if collected.contains(.dictionary) || memories.opened.contains("dictionary") || dictionary.solved {
            dictionary.solved = true
            memories.opened.insert("dictionary")
            collected.insert(.dictionary)
            exploration.tools.remove(.fountainPen)
            memories.picked.insert(.fountainPen)
            memories.used.insert(.fountainPen)
            if selectedTool == .fountainPen { selectedTool = nil }
        }
    }
}

/// A whole-word decision, with no answer-biased vocabulary or spelling correction.
private enum DictionaryHandwriting {
    static func read(_ strokes: [[DictionaryInkPoint]]) throws -> String {
        let size = CGSize(width: 1000, height: 572)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            UIColor.white.setFill()
            renderer.fill(CGRect(origin: .zero, size: size))
            let context = renderer.cgContext
            context.setStrokeColor(UIColor.black.cgColor)
            context.setLineWidth(7)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            for stroke in strokes {
                guard let first = stroke.first else { continue }
                context.beginPath()
                context.move(to: CGPoint(x: 30 + first.x * 940, y: 30 + first.y * 512))
                for point in stroke.dropFirst() {
                    context.addLine(to: CGPoint(x: 30 + point.x * 940, y: 30 + point.y * 512))
                }
                context.strokePath()
            }
        }
        guard let cgImage = image.cgImage else { return "" }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = false
        try VNImageRequestHandler(cgImage: cgImage).perform([request])
        let words = (request.results ?? []).sorted { $0.boundingBox.minX < $1.boundingBox.minX }
            .compactMap { $0.topCandidates(1).first }
        guard !words.isEmpty, words.allSatisfy({ $0.confidence >= 0.5 }) else { return "" }
        return words.map(\.string).joined().filter { !$0.isWhitespace }.uppercased()
    }
}
