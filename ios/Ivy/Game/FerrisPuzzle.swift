import Foundation

struct FerrisProgress: Codable, Equatable {
    // Seven ascending staff positions, E4 through D5. One duration, no ear training.
    static let melody = [0, 2, 4, 3, 1, 5, 6, 2, 0]
    static let noteNames = ["E, bottom line", "F, first space", "G, second line", "A, second space", "B, third line", "C, third space", "D, fourth line"]
    static let landmarks = ["Pier warehouse", "Clock tower", "Hill observatory"]
    var musicSolved = false
    var notes: [Int] = []
    var recording = false
    var lastNote: Int? = nil
    var ticketTaken = false
    var ticketUsed = false
    var height = 0
    // Legacy pickup/placement facts remain decodable; new cards start inside the press.
    var postcardTaken = false
    var postcardPlaced = false
    var stamps = [2, 0, 1]
    var stamped = false
    var cardRetrieved = false
    var posted = false
    var exitUnlocked = false

    private enum CodingKeys: String, CodingKey {
        case musicSolved, notes, recording, lastNote, ticketTaken, ticketUsed, height
        case postcardTaken, postcardPlaced, stamps, stamped, cardRetrieved, posted, exitUnlocked
        case playlistSolved, phoneTaken, photoTaken // Decode retired facts only.
    }

    init() {}

    init(from decoder: Decoder) throws {
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        musicSolved = (try? c.decode(Bool.self, forKey: .musicSolved)) ?? (try? c.decode(Bool.self, forKey: .playlistSolved)) ?? false
        notes = (try? c.decode([Int].self, forKey: .notes)) ?? []
        recording = (try? c.decode(Bool.self, forKey: .recording)) ?? false
        lastNote = try? c.decode(Int.self, forKey: .lastNote)
        ticketTaken = (try? c.decode(Bool.self, forKey: .ticketTaken)) ?? false
        ticketUsed = (try? c.decode(Bool.self, forKey: .ticketUsed)) ?? false
        height = (try? c.decode(Int.self, forKey: .height)) ?? 0
        postcardTaken = (try? c.decode(Bool.self, forKey: .postcardTaken)) ?? (try? c.decode(Bool.self, forKey: .phoneTaken)) ?? false
        postcardPlaced = (try? c.decode(Bool.self, forKey: .postcardPlaced)) ?? false
        stamps = (try? c.decode([Int].self, forKey: .stamps)) ?? [2, 0, 1]
        stamped = (try? c.decode(Bool.self, forKey: .stamped)) ?? false
        cardRetrieved = (try? c.decode(Bool.self, forKey: .cardRetrieved)) ?? false
        posted = (try? c.decode(Bool.self, forKey: .posted)) ?? (try? c.decode(Bool.self, forKey: .photoTaken)) ?? false
        exitUnlocked = (try? c.decode(Bool.self, forKey: .exitUnlocked)) ?? false
        sanitize()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(musicSolved, forKey: .musicSolved)
        try c.encode(notes, forKey: .notes)
        try c.encode(recording, forKey: .recording)
        try c.encodeIfPresent(lastNote, forKey: .lastNote)
        try c.encode(ticketTaken, forKey: .ticketTaken)
        try c.encode(ticketUsed, forKey: .ticketUsed)
        try c.encode(height, forKey: .height)
        try c.encode(postcardTaken, forKey: .postcardTaken)
        try c.encode(postcardPlaced, forKey: .postcardPlaced)
        try c.encode(stamps, forKey: .stamps)
        try c.encode(stamped, forKey: .stamped)
        try c.encode(cardRetrieved, forKey: .cardRetrieved)
        try c.encode(posted, forKey: .posted)
        try c.encode(exitUnlocked, forKey: .exitUnlocked)
    }

    mutating func sanitize() {
        notes = Array(notes.filter { (0..<7).contains($0) }.prefix(Self.melody.count))
        if let note = lastNote, !(0..<7).contains(note) { lastNote = nil }
        height = min(2, max(0, height))
        if stamps.count != 3 || stamps.contains(where: { !(0..<3).contains($0) }) { stamps = [2, 0, 1] }
        if posted { cardRetrieved = true; exitUnlocked = true }
        if cardRetrieved { stamped = true }
        if stamped { postcardPlaced = true; stamps = [0, 1, 2] }
        if postcardPlaced { postcardTaken = true }
        if postcardTaken { ticketUsed = true }
        if ticketUsed { ticketTaken = true }
        if ticketTaken { musicSolved = true }
        if musicSolved { notes = Self.melody; recording = false }
    }
}

extension GameStore {
    var ferris: FerrisProgress {
        get { memories.ferris ?? FerrisProgress() }
        set { memories.ferris = newValue }
    }

    var ferrisCabinImage: String { "ferris-harbour-\(ferris.height)" }

    private var ferrisActive: Bool {
        room == .ferris && !isIntro && !isHallTransitioning && collectingEgg == nil
    }

    func strikeFerrisNote(_ note: Int) {
        guard ferrisActive, overlay == .memory(.ferris), !ferris.musicSolved, (0..<7).contains(note) else { return }
        ferris.lastNote = note
        IvyHaptics.light()
        if ferris.recording, ferris.notes.count < FerrisProgress.melody.count { ferris.notes.append(note) }
        dismissSceneHint()
        persistNow()
    }

    func toggleFerrisRecording() {
        guard ferrisActive, overlay == .memory(.ferris), !ferris.musicSolved else { return }
        ferris.recording.toggle()
        dismissSceneHint()
        persistNow()
    }

    func undoFerrisNote() {
        guard ferrisActive, overlay == .memory(.ferris), !ferris.musicSolved, !ferris.notes.isEmpty else { return }
        ferris.notes.removeLast()
        dismissSceneHint()
        persistNow()
    }

    func submitFerrisMusic() {
        guard ferrisActive, overlay == .memory(.ferris), !ferris.musicSolved else { return }
        guard ferris.notes == FerrisProgress.melody else { showWrongAnswer(); return }
        ferris.musicSolved = true
        ferris.recording = false
        persistNow()
        backFromMemory()
    }

    func takeFerrisTicket() {
        guard ferrisActive, overlay == .memory(.ferrisTicket), ferris.musicSolved, !ferris.ticketTaken else { return }
        ferris.ticketTaken = true
        acquire(.ferrisTicket)
    }

    func useFerrisTicket() {
        guard ferrisActive, overlay == .memory(.ferrisGate), !ferris.ticketUsed else { return }
        guard ferris.musicSolved, ferris.ticketTaken else { hintForTool(.ferrisTicket); return }
        guard use(.ferrisTicket) else { return }
        ferris.ticketUsed = true
        consume(.ferrisTicket)
        dismissSceneHint()
    }

    func enterFerrisCabin() {
        guard ferrisActive, overlay == .memory(.ferrisGate), ferris.ticketUsed else { return }
        openMemory(.ferrisCabin)
    }

    func changeFerrisHeight(_ delta: Int) {
        guard ferrisActive, overlay == .memory(.ferrisCabin), ferris.ticketUsed, (delta == -1 || delta == 1) else { return }
        ferris.height = min(2, max(0, ferris.height + delta))
        dismissSceneHint()
        persistNow()
    }

    func turnFerrisStamp(_ slot: Int, by delta: Int = 1) {
        guard ferrisActive, overlay == .memory(.ferrisCamera), ferris.ticketUsed,
              !ferris.stamped, (0..<3).contains(slot), (delta == -1 || delta == 1) else { return }
        ferris.stamps[slot] = (ferris.stamps[slot] + delta + 3) % 3
        dismissSceneHint()
        persistNow()
    }

    func pressFerrisPostcard() {
        guard ferrisActive, overlay == .memory(.ferrisCamera), ferris.ticketUsed,
              !ferris.stamped else { return }
        // A short observation interlude following the full music puzzle, not a brute-force-resistant main puzzle.
        guard ferris.stamps == [0, 1, 2] else { showWrongAnswer(); return }
        ferris.stamped = true
        dismissSceneHint()
        persistNow()
    }

    func retrieveFerrisPostcard() {
        guard ferrisActive, overlay == .memory(.ferrisCamera), ferris.stamped, !ferris.cardRetrieved else { return }
        ferris.cardRetrieved = true
        ferris.postcardTaken = true
        acquire(.ferrisPostcard)
    }

    func postFerrisPostcard() {
        guard ferrisActive, overlay == .memory(.ferrisPostbox), ferris.ticketUsed else { return }
        if ferris.posted { replayKeepsake(.ferris); return }
        guard ferris.stamped, ferris.cardRetrieved else {
            showSceneHint("The postcard still has a little journey to make.", presentation: .interaction)
            return
        }
        guard use(.ferrisPostcard) else { return }
        ferris.posted = true
        ferris.exitUnlocked = true
        memories.opened.insert("ferris")
        collected.insert(.ferris)
        toolsVisible = false
        consume(.ferrisPostcard)
        persistNow()
        replayKeepsake(.ferris)
    }

    func leaveFerrisPlatform() {
        guard ferrisActive, overlay == .memory(.ferrisPostbox) else { return }
        guard ferris.exitUnlocked || collected.contains(.ferris) else {
            showSceneHint("A postcard is still waiting to be sent.", presentation: .interaction)
            return
        }
        transition(to: .taxi)
    }

    func migrateFerris() {
        let legacy = memories.ferris == nil
        var progress = ferris
        if collected.contains(.ferris) || memories.opened.contains("ferris") { progress.posted = true }
        else if legacy && memories.ferrisMatches == [0, 1] { progress.musicSolved = true }
        if room == .taxi || collected.contains(.taxi) || exploration.views["taxi"] != nil {
            progress.exitUnlocked = true
            progress.ticketUsed = true
        }
        if exploration.tools.contains(.ferrisPhone) || memories.picked.contains(.ferrisPhone) { progress.postcardTaken = true }
        progress.sanitize()
        ferris = progress
        if progress.posted { memories.opened.insert("ferris"); collected.insert(.ferris) }
        exploration.tools.remove(.ferrisPhone)
        if selectedTool == .ferrisPhone { selectedTool = nil }
        if progress.postcardTaken { exploration.clues.insert(.ferrisHarbour) }
        if progress.musicSolved { exploration.clues.insert(.ferrisScore) }
        for (tool, taken, used, placed) in [
            (AdventureTool.ferrisTicket, progress.ticketTaken, progress.ticketUsed, false),
            (.ferrisPostcard, progress.cardRetrieved, progress.posted, false)
        ] {
            if taken { memories.picked.insert(tool) }
            if used {
                memories.used.insert(tool)
                exploration.tools.remove(tool)
            } else if taken && !placed {
                memories.used.remove(tool)
                exploration.tools.insert(tool)
            } else { exploration.tools.remove(tool) }
            if !exploration.tools.contains(tool), selectedTool == tool { selectedTool = nil }
        }
    }
}
