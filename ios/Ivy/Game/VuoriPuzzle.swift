import SwiftUI

/// The saved word is also the ordered path: every supplied letter occurs once.
enum VuoriPuzzle {
    static let letters = Array("lvaoutrie")
    // The saved draft uses letters, so changing their positions preserves old progress.
    static let displayIndices = Array("arlvoieut").compactMap { letters.firstIndex(of: $0) }
    static let answer = "vuori"
    static let limit = 5

    static func normalizedDraft(_ draft: String) -> String {
        var result = ""
        for letter in draft.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            guard letters.contains(letter), !result.contains(letter), result.count < limit else { break }
            result.append(letter)
        }
        return result
    }

    static func indices(for draft: String) -> [Int] {
        draft.compactMap { letters.firstIndex(of: $0) }
    }
}

extension GameStore {
    var vuoriPath: [Int] { VuoriPuzzle.indices(for: vuoriDraft) }
    private var canConnectVuori: Bool {
        room == .hall && overlay == .vuori && !collected.contains(.vuori) &&
        collectingEgg == nil && !isHallTransitioning
    }

    func tapVuori() {
        guard room == .hall, !isHallTransitioning, collectingEgg == nil else { return }
        if collected.contains(.vuori) { reopenVuoriFromBar(); return }
        sceneHint = ""
        overlay = .vuori
    }

    func beginVuoriConnection() {
        guard canConnectVuori else { return }
        vuoriDraft = ""
        vuoriMiss = false
        dismissSceneHint()
    }

    /// Dragging back one node erases it; revisiting any other node is ignored.
    func connectVuoriLetter(_ index: Int) {
        guard canConnectVuori, VuoriPuzzle.letters.indices.contains(index) else { return }
        let path = vuoriPath
        if path.count > 1, path[path.count - 2] == index {
            eraseVuoriConnection()
            return
        }
        guard !path.contains(index), path.count < VuoriPuzzle.limit else { return }
        vuoriDraft.append(VuoriPuzzle.letters[index])
        vuoriMiss = false
        dismissSceneHint()
        IvyHaptics.light()
        schedulePersist()
    }

    /// Called on finger lift or an accessibility/tap selection, never mid-drag.
    func finishVuoriConnection() {
        guard canConnectVuori else { return }
        guard vuoriDraft.count == VuoriPuzzle.limit else {
            vuoriDraft = ""
            schedulePersist()
            return
        }
        guard vuoriDraft == VuoriPuzzle.answer else {
            vuoriDraft = ""
            vuoriMiss = true
            showWrongAnswer()
            IvyHaptics.warning()
            schedulePersist()
            return
        }
        vuoriDraft = ""
        vuoriMiss = false
        sceneHint = ""
        overlay = .none
        collect(.vuori)
        persistNow()
    }

    func eraseVuoriConnection() {
        guard canConnectVuori, !vuoriDraft.isEmpty else { return }
        vuoriDraft.removeLast()
        vuoriMiss = false
        dismissSceneHint()
        IvyHaptics.soft()
        schedulePersist()
    }

    /// Replays the keepsake from any room without recollecting or moving the player.
    func reopenVuoriFromBar() {
        guard collected.contains(.vuori), !isIntro, !isHallTransitioning,
              collectingEgg == nil, overlay != .vuoriMemory else { return }
        vuoriMemoryReturnOverlay = overlay
        overlay = .vuoriMemory
        IvyHaptics.soft()
    }

    func dismissVuoriMemory() {
        guard overlay == .vuoriMemory else { return }
        overlay = vuoriMemoryReturnOverlay
        vuoriMemoryReturnOverlay = .none
    }
}
