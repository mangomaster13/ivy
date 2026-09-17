import Foundation
import Observation
import SwiftUI
import UIKit

/// One collectible in the nine-slot bar. Yard ships `ivy` and `sep29`; the rest stay dark.
enum EggId: String, CaseIterable, Codable, Identifiable {
    case vuori
    case gelato
    case noodle
    case cinema
    case ivy
    case sep29
    case suitcase
    case keycard
    case pillow

    /// Stable slot order from the design spec (1...9).
    var id: String { rawValue }

    /// Slot index in the inventory bar, zero-based.
    var slotIndex: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    /// Color pixel icon once the egg is collected.
    var iconName: String { "icon-\(rawValue)" }

    /// Night-navy silhouette while the slot is still empty.
    var offIconName: String { "icon-\(rawValue)-off" }
}

/// Playable rooms. First scene walks yard ↔ hall after the lyric lock opens.
enum Room: String, Codable {
    case yard
    case hall

    /// Asset catalog name for the 320×160 base.
    var imageName: String {
        switch self {
        case .yard: "yard-base"
        case .hall: "hall"
        }
    }
}

/// Modal layer above the current room. Depth is always room → this → room.
enum GameOverlay: Equatable {
    case none
    case dialogue(String)
    case lyric
    case plaque
}

/// Source of a tap inside the 320×160 yard.
enum YardHotspot: String, Identifiable {
    case door
    case ivy
    case mailbox
    case miss

    var id: String { rawValue }
}

/// Persisted snapshot so killing the app keeps the yard lock and drafts.
struct GameSnapshot: Codable {
    var room: Room
    var collected: [EggId]
    var doorOpened: Bool
    var lyricDraft: String
    var plaqueDraft: String
    var lyricFailCount: Int
    var vineHintIndex: Int
    var overlay: OverlayKind
    var lyricHint: String
    var didFlashDoor: Bool

    /// Overlay cases that can be encoded without carrying dialogue copy twice.
    enum OverlayKind: String, Codable {
        case none
        case lyric
        case plaque
        case dialogue
    }
}

/// Single store for the gift. No Clinic modules, no NavigationStack.
@MainActor
@Observable
final class GameStore {
    /// Current 320×160 room.
    var room: Room = .yard
    /// Eggs already in the bar.
    var collected: Set<EggId> = []
    /// Front door has accepted `covered in you 817`.
    var doorOpened = false
    /// Layer above the room.
    var overlay: GameOverlay = .none
    /// Text still in the lyric field (kept across wrong tries and app switches).
    var lyricDraft = ""
    /// Text still in the plaque field.
    var plaqueDraft = ""
    /// Oral hint under the lyric field; empty until the first miss.
    var lyricHint = ""
    /// Oral hint under the plaque field; empty until the first miss.
    var plaqueHint = ""
    /// How many times the lyric gate has rejected input.
    var lyricFailCount = 0
    /// How far the vine breadcrumb has been read.
    var vineHintIndex = 0
    /// 0...1 black veil for the door-success cut.
    var worldDim: Double = 0
    /// Horizontal nudge in points for walk / shake.
    var worldOffsetX: CGFloat = 0
    /// Egg whose slot should punch to 1.12 this beat.
    var slotPulse: EggId?
    /// Door 1px flash after two idle minutes in the yard.
    var doorGlow: Double = 0
    /// True after the once-per-session door flash has played.
    var didFlashDoor = false
    /// Dialogue kept when the overlay is `.dialogue`.
    var dialogueLine = ""
    /// Mirrors `@Environment(\.accessibilityReduceMotion)` from the root view.
    var prefersReducedMotion = false
    /// Ping-pong 0...2 for the yard vine sway frames.
    var ivySwayFrame = 0
    /// Cloud strip origin in game pixels; wraps every `GameCanvas.cloudPeriod`.
    var cloudOffset = 0
    /// Boot card is up until Enter or the 2s timer.
    var isIntro = true

    private var persistTask: Task<Void, Never>?
    private var atmosphereTask: Task<Void, Never>?
    private static let persistKey = "ivy.game.snapshot.v1"
    /// Cloud x where `____` stays readable when Reduce Motion freezes the sky.
    private static let readableCloudOffset = 242

    /// Restores on-device progress if this phone has already played.
    init() {
        load()
        #if DEBUG
        if ProcessInfo.processInfo.environment["IVY_PREVIEW_DIALOGUE"] == "1" {
            overlay = .dialogue(GameCopy.skyFlavor)
        }
        if ProcessInfo.processInfo.environment["IVY_PREVIEW_ICONS"] == "1" {
            collected = Set(EggId.allCases)
        }
        if ProcessInfo.processInfo.environment["IVY_PREVIEW_YARD"] == "1" {
            room = .yard
            overlay = .none
            doorOpened = false
            collected = []
        }
        if let vines = ProcessInfo.processInfo.environment["IVY_PREVIEW_VINES"],
           let stage = Int(vines) {
            room = .yard
            overlay = .none
            collected = []
            if stage >= 1 { collected.insert(.ivy) }
            if stage >= 2 { collected.insert(.sep29) }
        }
            isIntro = false
        }
        #endif
        if !isIntro {
            startAtmosphere()
        }
    }

    /// Leaves the title card and starts the yard wind.
    func dismissIntro() {
        guard isIntro else { return }
        isIntro = false
        startAtmosphere()
    }

    /// True when the lyric or plaque keyboard is up.
    var isEntering: Bool {
        overlay == .lyric || overlay == .plaque
    }

    /// True when the ivy egg is already in the bar.
    var hasIvy: Bool {
        collected.contains(.ivy)
    }

    /// True when the 9.29 plaque is already in the bar.
    var hasSep29: Bool {
        collected.contains(.sep29)
    }

    /// Bilateral vine density: 0 at first visit, +1 per yard egg (`ivy`, `sep29`).
    var yardVineStage: Int {
        min(2, (hasIvy ? 1 : 0) + (hasSep29 ? 1 : 0))
    }

    /// Opens the lyric keyboard. After a correct answer the door is just a door.
    func tapYardDoor() {
        if doorOpened {
            IvyHaptics.light()
            walk(to: .hall, dx: 2)
            return
        }
        IvyHaptics.light()
        overlay = .lyric
        schedulePersist()
    }

    /// Vine never asks for the password; it only talks.
    func tapYardIvy() {
        IvyHaptics.soft()
        let lines = GameCopy.vineHints
        let index = min(vineHintIndex, lines.count - 1)
        say(lines[index])
        if vineHintIndex < lines.count - 1 {
            vineHintIndex += 1
        }
        schedulePersist()
    }

    /// Mailbox is the 9.29 egg. Re-reading after collect does not charge the bar again.
    func tapYardMailbox() {
        IvyHaptics.light()
        if hasSep29 {
            say(GameCopy.plaqueReread)
            return
        }
        overlay = .plaque
        schedulePersist()
    }

    /// Empty yard taps: sky, grass, or house stones.
    func tapYardMiss(gamePoint: CGPoint) {
        IvyHaptics.soft()
        if gamePoint.y < 70 {
            say(GameCopy.skyFlavor)
        } else if gamePoint.y > 132 {
            say(GameCopy.grassFlavor)
        } else {
            say(GameCopy.stoneFlavor)
        }
    }

    /// Hall only walks back through the night door in this build.
    func tapHallExit() {
        IvyHaptics.light()
        walk(to: .yard, dx: -2)
    }

    /// Other hall furniture waits for later rooms.
    func tapHallRest() {
        IvyHaptics.soft()
        say(GameCopy.hallRest)
    }

    /// Dismisses talk or input. Drafts stay.
    func cancelOverlay() {
        overlay = .none
        schedulePersist()
    }

    /// Dismisses the dialogue box.
    func dismissDialogue() {
        guard case .dialogue = overlay else { return }
        overlay = .none
    }

    /// Checks the lyric field against `covered in you 817` and staged misses.
    func submitLyric() {
        switch LyricGate.verdict(lyricDraft) {
        case .correct:
            IvyHaptics.success()
            overlay = .none
            lyricHint = ""
            doorOpened = true
            collect(.ivy, playHaptic: false)
            Task { await cutToHall() }
        case .missingDate:
            registerLyricMiss(GameCopy.lyricMissingDate)
        case .plaqueDate:
            registerLyricMiss(GameCopy.lyricPlaqueDate)
        case .dateOnly:
            registerLyricMiss(GameCopy.lyricDateOnly)
        case .tooShortTitle:
            registerLyricMiss(GameCopy.lyricTooShort)
        case .wrong:
            registerLyricMiss(GameCopy.lyricHint(forFailCount: lyricFailCount + 1))
        }
        schedulePersist()
    }

    /// Checks the mailbox field against 929 / 9.29 / 0929.
    func submitPlaque() {
        if LyricGate.plaqueMatches(plaqueDraft) {
            IvyHaptics.success()
            overlay = .none
            collect(.sep29, playHaptic: false)
            say(GameCopy.plaqueCollected)
        } else {
            plaqueHint = GameCopy.plaqueWrong
            IvyHaptics.warning()
            shakeWorld()
        }
        schedulePersist()
    }

    /// Two idle minutes in the locked yard: flash the door once.
    func considerDoorNudge() {
        guard !didFlashDoor, !doorOpened, room == .yard, !isEntering else { return }
        didFlashDoor = true
        withAnimation(.linear(duration: 0.35).repeatCount(3, autoreverses: true)) {
            doorGlow = 1
        }
        Task {
            try? await Task.sleep(for: .milliseconds(2100))
            doorGlow = 0
            schedulePersist()
        }
    }

    /// Writes progress after a short coalesced delay.
    func schedulePersist() {
        persistTask?.cancel()
        persistTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            self?.persist()
        }
    }

    /// Immediate disk write used when leaving the scene.
    func persistNow() {
        persistTask?.cancel()
        persist()
    }

    /// Starts the yard's 1px cloud drift and 3-frame ivy sway. Idempotent.
    func startAtmosphere() {
        guard atmosphereTask == nil else { return }
        atmosphereTask = Task { [weak self] in
            var dir = 1
            var ticks = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(125))
                guard let self, !Task.isCancelled else { return }
                if self.prefersReducedMotion {
                    if self.ivySwayFrame != 0 {
                        self.ivySwayFrame = 0
                    }
                    if self.cloudOffset != Self.readableCloudOffset {
                        self.cloudOffset = Self.readableCloudOffset
                    }
                    continue
                }
                ticks += 1
                if ticks.isMultiple(of: 4) {
                    self.ivySwayFrame += dir
                    if self.ivySwayFrame >= 2 {
                        self.ivySwayFrame = 2
                        dir = -1
                    } else if self.ivySwayFrame <= 0 {
                        self.ivySwayFrame = 0
                        dir = 1
                    }
                }
                if ticks.isMultiple(of: 2) {
                    self.cloudOffset = (self.cloudOffset + 1) % GameCanvas.cloudPeriod
                }
            }
        }
    }

    /// Re-reads a collected egg from the bar.
    func speakReread(_ line: String) {
        IvyHaptics.soft()
        say(line)
    }

    /// Collects an egg, pulses its slot, and keeps the bar.
    private func collect(_ egg: EggId, playHaptic: Bool = true) {
        guard !collected.contains(egg) else { return }
        collected.insert(egg)
        withAnimation(.snappy(duration: 0.18)) {
            slotPulse = egg
        }
        if playHaptic {
            IvyHaptics.medium()
        }
        Task {
            try? await Task.sleep(for: .milliseconds(180))
            withAnimation(.snappy(duration: 0.12)) {
                slotPulse = nil
            }
        }
    }

    /// Shows one spoken line in the dialogue box.
    private func say(_ line: String) {
        dialogueLine = line
        withAnimation(.smooth(duration: 0.2)) {
            overlay = .dialogue(line)
        }
    }

    /// Shared miss path: keep the typed text, bump the oral hint.
    private func registerLyricMiss(_ hint: String) {
        lyricFailCount += 1
        lyricHint = hint
        IvyHaptics.warning()
        shakeWorld()
    }

    /// 2pt shake; skipped visually when Reduce Motion is on at the call site.
    private func shakeWorld() {
        if prefersReducedMotion { return }
        Task {
            for _ in 0..<3 {
                withAnimation(.linear(duration: 0.05)) { worldOffsetX = 2 }
                try? await Task.sleep(for: .milliseconds(50))
                withAnimation(.linear(duration: 0.05)) { worldOffsetX = -2 }
                try? await Task.sleep(for: .milliseconds(50))
            }
            worldOffsetX = 0
        }
    }

    /// First unlock: black cut into the hall. Later walks skip this.
    private func cutToHall() async {
        withAnimation(.smooth(duration: 0.12)) {
            worldDim = 1
        }
        try? await Task.sleep(for: .milliseconds(160))
        var cut = Transaction()
        cut.animation = nil
        withTransaction(cut) {
            room = .hall
        }
        withAnimation(.smooth(duration: 0.12)) {
            worldDim = 0
        }
        schedulePersist()
    }

    /// Ordinary door walk after the house already knows him.
    private func walk(to next: Room, dx: CGFloat) {
        if prefersReducedMotion {
            room = next
            schedulePersist()
            return
        }
        Task {
            withAnimation(.linear(duration: 0.08)) {
                worldOffsetX = dx
            }
            try? await Task.sleep(for: .milliseconds(90))
            var cut = Transaction()
            cut.animation = nil
            withTransaction(cut) {
                room = next
                worldOffsetX = 0
            }
            schedulePersist()
        }
    }

    /// Decodes the last snapshot from UserDefaults.
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.persistKey),
              let snap = try? JSONDecoder().decode(GameSnapshot.self, from: data)
        else { return }
        room = snap.room
        collected = Set(snap.collected)
        doorOpened = snap.doorOpened
        lyricDraft = snap.lyricDraft
        plaqueDraft = snap.plaqueDraft
        lyricFailCount = snap.lyricFailCount
        vineHintIndex = snap.vineHintIndex
        lyricHint = snap.lyricHint
        didFlashDoor = snap.didFlashDoor
        switch snap.overlay {
        case .lyric: overlay = .lyric
        case .plaque: overlay = .plaque
        case .dialogue:
            overlay = .none
        case .none:
            overlay = .none
        }
    }

    /// Encodes progress. Dialogue is not restored (copy is cheap to tap again).
    private func persist() {
        let kind: GameSnapshot.OverlayKind
        switch overlay {
        case .lyric: kind = .lyric
        case .plaque: kind = .plaque
        default: kind = .none
        }
        let snap = GameSnapshot(
            room: room,
            collected: EggId.allCases.filter { collected.contains($0) },
            doorOpened: doorOpened,
            lyricDraft: lyricDraft,
            plaqueDraft: plaqueDraft,
            lyricFailCount: lyricFailCount,
            vineHintIndex: vineHintIndex,
            overlay: kind,
            lyricHint: lyricHint,
            didFlashDoor: didFlashDoor
        )
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: Self.persistKey)
        }
    }
}

/// Normalizes typed answers without putting the lyric on screen.
enum LyricGate {
    /// How a lyric submission should be answered.
    enum Verdict {
        case correct
        case missingDate
        case plaqueDate
        case dateOnly
        case tooShortTitle
        case wrong
    }

    /// Letters-only form of the chorus tail.
    private static let lyricLetters = "coveredinyou"
    /// Optional longer tails from the same line.
    private static let lyricLetterAliases: Set<String> = [
        "coveredinyou",
        "imcoveredinyou",
        "iamcoveredinyou",
        "nowimcoveredinyou",
        "andnowimcoveredinyou"
    ]

    /// Verdict for the front-door field.
    static func verdict(_ raw: String) -> Verdict {
        let letters = raw.lowercased().filter(\.isLetter)
        let digits = raw.filter(\.isNumber)
        let date = normalizeDate(digits)
        let lyricOK = lyricLetterAliases.contains(letters)
        let dateOK = date == "817"

        if lyricOK && dateOK { return .correct }
        if lyricOK && (date == "929") { return .plaqueDate }
        if lyricOK && digits.isEmpty { return .missingDate }
        if lyricOK { return .missingDate }
        if dateOK && letters.isEmpty { return .dateOnly }
        if dateOK { return .dateOnly }
        if letters == "ivy" || letters == "ivygrows" || letters == "yourivygrows" {
            return .tooShortTitle
        }
        if letters.hasPrefix("ivy"), letters.count <= 12 {
            return .tooShortTitle
        }
        if date == "929" { return .plaqueDate }
        return .wrong
    }

    /// Plaque accepts 929, 9.29, and 0929 after stripping punctuation.
    static func plaqueMatches(_ raw: String) -> Bool {
        let digits = raw.filter(\.isNumber)
        return digits == "929" || digits == "0929"
    }

    /// 0817 and 817 are the same August day.
    private static func normalizeDate(_ digits: String) -> String {
        if digits == "0817" || digits == "817" { return "817" }
        if digits == "0929" || digits == "929" { return "929" }
        if digits.hasSuffix("0817") { return "817" }
        if digits.hasSuffix("817") && digits.count <= 6 { return "817" }
        return digits
    }
}

/// UIKit generators used as the first beat of feedback.
@MainActor
enum IvyHaptics {
    /// Light tap on a hotspot that will open something.
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Soft tap on flavor-only hits.
    static func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    /// Slot accepts an egg.
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Door or plaque accepted.
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Door or plaque rejected; text stays.
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

/// Game-pixel rectangles on the 320×160 yard / hall plates.
enum RoomHotspots {
    /// Wooden front door, right of the lantern.
    static let yardDoor = CGRect(x: 164, y: 96, width: 32, height: 38)
    /// Climbing vine on the left wall. Stops above the mailbox.
    static let yardIvy = CGRect(x: 110, y: 48, width: 28, height: 62)
    /// Climbing vine on the right wall. Same breadcrumb as the left flank.
    static let yardIvyRight = CGRect(x: 198, y: 48, width: 24, height: 72)
    /// Mailbox post in the grass; this is the 9.29 plaque egg.
    static let yardMailbox = CGRect(x: 130, y: 110, width: 26, height: 36)
    /// Hall door that still shows the night yard.
    static let hallExit = CGRect(x: 50, y: 28, width: 28, height: 58)
}
