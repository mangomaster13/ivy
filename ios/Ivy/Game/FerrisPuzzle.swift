import Foundation

struct FerrisProgress: Codable, Equatable {
    static let initialOrder = [3, 0, 4, 2, 1]
    static let songs = [
        "Taylor Swift — Enchanted",
        "Dean Lewis — I don’t want to say goodbye",
        "The 1975 — Part of the band",
        "林忆莲 — 也许",
        "Taylor Swift — Lover"
    ]
    var order = initialOrder
    var playlistSolved = false
    var ticketTaken = false
    var ticketUsed = false
    var phoneTaken = false
    var photoTaken = false

    private enum CodingKeys: String, CodingKey {
        case order, playlistSolved, ticketTaken, ticketUsed, phoneTaken, photoTaken
    }

    init() {}

    init(from decoder: Decoder) throws {
        // A malformed local draft must not invalidate all thirteen keepsakes.
        guard let values = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        order = (try? values.decode([Int].self, forKey: .order)) ?? Self.initialOrder
        playlistSolved = (try? values.decode(Bool.self, forKey: .playlistSolved)) ?? false
        ticketTaken = (try? values.decode(Bool.self, forKey: .ticketTaken)) ?? false
        ticketUsed = (try? values.decode(Bool.self, forKey: .ticketUsed)) ?? false
        phoneTaken = (try? values.decode(Bool.self, forKey: .phoneTaken)) ?? false
        photoTaken = (try? values.decode(Bool.self, forKey: .photoTaken)) ?? false
        sanitize()
    }

    mutating func sanitize() {
        if order.count != 5 || Set(order) != Set(0..<5) { order = Self.initialOrder }
        if photoTaken { phoneTaken = true }
        if phoneTaken { ticketUsed = true }
        if ticketUsed { ticketTaken = true }
        if ticketTaken { playlistSolved = true }
        if playlistSolved { order = Array(0..<5) }
    }
}

extension GameStore {
    var ferris: FerrisProgress {
        get { memories.ferris ?? FerrisProgress() }
        set { memories.ferris = newValue }
    }

    private var ferrisActive: Bool {
        room == .ferris && !isIntro && !isHallTransitioning && collectingEgg == nil
    }

    func moveFerrisSong(_ song: Int, to destination: Int) {
        guard ferrisActive, overlay == .memory(.ferris), !ferris.playlistSolved,
              (0..<5).contains(destination), let source = ferris.order.firstIndex(of: song),
              source != destination else { return }
        var order = ferris.order
        order.remove(at: source)
        order.insert(song, at: destination)
        ferris.order = order
        dismissSceneHint()
        persistNow()
    }

    func submitFerrisPlaylist() {
        guard ferrisActive, overlay == .memory(.ferris), !ferris.playlistSolved else { return }
        guard ferris.order == Array(0..<5) else {
            dismissSceneHint()
            return
        }
        ferris.playlistSolved = true
        persistNow()
        openMemory(.ferrisTicket)
    }

    func takeFerrisTicket() {
        guard ferrisActive, overlay == .memory(.ferrisTicket), ferris.playlistSolved,
              !ferris.ticketTaken else { return }
        ferris.ticketTaken = true
        acquire(.ferrisTicket)
    }

    func useFerrisTicket() {
        guard ferrisActive, overlay == .memory(.ferrisGate), ferris.playlistSolved,
              ferris.ticketTaken, !ferris.ticketUsed else { return }
        guard use(.ferrisTicket) else { return }
        ferris.ticketUsed = true
        consume(.ferrisTicket)
        dismissSceneHint()
    }

    func enterFerrisCabin() {
        guard ferrisActive, overlay == .memory(.ferrisGate), ferris.ticketUsed else { return }
        openMemory(.ferrisCabin)
    }

    func takeFerrisPhone() {
        guard ferrisActive, overlay == .memory(.ferrisCabin), ferris.ticketUsed,
              !ferris.phoneTaken, !ferris.photoTaken else { return }
        ferris.phoneTaken = true
        acquire(.ferrisPhone)
    }

    func openFerrisCamera() {
        guard ferrisActive, overlay == .memory(.ferrisCabin), ferris.ticketUsed else { return }
        if ferris.photoTaken { replayKeepsake(.ferris); return }
        guard ferris.phoneTaken, selectedTool == .ferrisPhone,
              exploration.tools.contains(.ferrisPhone) else {
            hintForTool(.ferrisPhone)
            return
        }
        openMemory(.ferrisCamera)
    }

    func takeFerrisSelfie() {
        guard ferrisActive, overlay == .memory(.ferrisCamera), ferris.ticketUsed,
              !ferris.photoTaken else { return }
        guard ferris.phoneTaken, selectedTool == .ferrisPhone,
              exploration.tools.contains(.ferrisPhone) else { hintForTool(.ferrisPhone); return }
        ferris.photoTaken = true
        memories.opened.insert("ferris")
        collected.insert(.ferris)
        consume(.ferrisPhone)
        toolsVisible = false
        persistNow()
        replayKeepsake(.ferris)
    }

    func migrateFerris() {
        let legacy = memories.ferris == nil
        var progress = ferris
        if collected.contains(.ferris) || memories.opened.contains("ferris") {
            progress.photoTaken = true
        } else if legacy && memories.ferrisMatches == [0, 1] {
            // A fully matched old pair retains its solved puzzle, with a ticket ready to take.
            progress.playlistSolved = true
        }
        // Players already beyond this stop retain their old access without a new award.
        if legacy && (room == .taxi || collected.contains(.taxi) || exploration.views["taxi"] != nil) {
            progress.ticketUsed = true
        }
        progress.sanitize()
        ferris = progress
        if progress.photoTaken {
            memories.opened.insert("ferris")
            collected.insert(.ferris)
        }
        for (tool, taken, used) in [(AdventureTool.ferrisTicket, progress.ticketTaken, progress.ticketUsed),
                                    (.ferrisPhone, progress.phoneTaken, progress.photoTaken)] {
            if taken { memories.picked.insert(tool) }
            if used {
                memories.used.insert(tool)
                exploration.tools.remove(tool)
                if selectedTool == tool { selectedTool = nil }
            } else if taken {
                memories.used.remove(tool)
                exploration.tools.insert(tool)
            } else {
                exploration.tools.remove(tool)
                if selectedTool == tool { selectedTool = nil }
            }
        }
    }
}
