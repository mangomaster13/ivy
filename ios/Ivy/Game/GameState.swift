import Foundation
import Observation
import SwiftUI
import UIKit

/// Thirteen keepsakes. The mailbox awards the letter; the door is navigation only.
enum EggId: String, CaseIterable, Codable, Identifiable {
    case letter
    case vuori
    case plane
    case keycard
    case city
    case rose
    case gelato
    case noodle
    case perfume
    case cinema
    case sunset
    case ferris
    case taxi

    /// Stable slot order from PRODUCT (letter first).
    var id: String { rawValue }

    /// Slot index in the inventory bar, zero-based.
    var slotIndex: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    /// Independent transparent keepsake artwork shared by the bar and tap celebration.
    var iconName: String { self == .noodle ? "bt-dinner" : self == .perfume ? "ll-perfume-trio" : self == .keycard ? "sheraton-keycard" : self == .city ? "city-jigsaw-master" : "keepsake-\(rawValue)" }

    /// Physical memory and puzzle artwork, separate from the transparent keepsake icon.
    var collectionImageName: String {
        switch self {
        case .letter: "story-envelope"
        case .vuori: "memory-shirt-final"
        case .rose: "rose-bouquet"
        case .perfume: "ll-perfume-trio"
        case .plane: "memory-ticket"
        case .gelato: "memory-gelato-cup"
        case .cinema: "memory-cinema-ticket"
        case .noodle: "bt-dinner"
        case .taxi: "memory-taxi-receipt"
        case .ferris: "memory-ferris-ticket"
        case .sunset: "memory-sunset"
        case .keycard: "sheraton-keycard"
        case .city: "city-jigsaw-master"
        default: iconName
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        // Previous yard revisions used ivy for the first slot. Keep old saves readable.
        let current = value == "ivy" ? "letter" : value == "supermarket" ? "perfume" : value
        guard let egg = Self(rawValue: current) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown egg: \(value)")
        }
        self = egg
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// Playable rooms. Yard and hall are the cottage; the rest is Wonderland HK.
enum Room: String, Codable {
    case yard
    case hall
    case plane
    case corridor
    case bedroom
    case gelato
    case noodle
    case perfume
    case cinema
    case sunset
    case ferris
    case taxi

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        guard let room = Self(rawValue: value == "supermarket" ? "perfume" : value) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown room: \(value)")
        }
        self = room
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    /// Asset catalog name for the 320×160 base.
    var imageName: String {
        switch self {
        case .yard: "story-yard-base"
        case .hall: "story-hall"
        case .plane: "hk-plane-no-ticket"
        case .corridor: "hk-corridor"
        case .bedroom: "hk-bedroom"
        case .gelato: "bt2-gelato"
        case .noodle: "bt2-room"
        case .perfume: "ll4-street"
        case .cinema: "memory-cinema"
        case .sunset: "memory-sunset"
        case .ferris: "memory-ferris"
        case .taxi: "memory-taxi"
        }
    }
}

/// Modal layer above the current room. Depth is always room → this → room.
enum GameOverlay: Equatable {
    case none
    case dialogue(String)
    case lyric
    case plaque
    case envelope
    case vuori
    case prize
    case vuoriMemory
    case hotelLock
    case rose
    case gelato
    case observation(EggId)
    case adventure(AdventurePanel)
    case memory(MemoryPanel)
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
    var lyricPad: [String]
    var plaqueDraft: String
    var plaquePad: [String]
    var lyricFailCount: Int
    var vineHintIndex: Int
    var overlay: OverlayKind
    var lyricHint: String
    var didFlashDoor: Bool
    /// Mailbox engraving has been uncovered by tapping plate ivy.
    var plaqueHintRevealed: Bool?
    /// Rules letter has already unrolled once; later opens hold the last cell.
    var envelopeDidUnroll: Bool?

    /// Mailbox `817` has already been accepted. Not an egg.
    var mailboxOpened: Bool?
    /// Title card has been dismissed on this device.
    var introSeen: Bool?
    /// Hotel corridor code has been accepted. Not an egg.
    var corridorUnlocked: Bool?

    var vuoriDraft: String?
    var lotteryDrawn: Bool?
    var corridorDigits: [Int]?
    var petalHeld: Bool?
    var gelatoSelection: [GelatoFlavor]?
    var exploration: ExplorationProgress?
    var memories: MemoryProgress? = nil

    /// Overlay cases that can be encoded without carrying dialogue copy twice.
    enum OverlayKind: String, Codable {
        case none
        case lyric
        case plaque
        case envelope
        case dialogue
    }
}

/// Single store for the gift. No Clinic modules, no NavigationStack.
@MainActor
@Observable
final class GameStore {
    /// Current 320×160 room.
    var room: Room = .yard
    var yardImageName: String { doorOpened ? "story-yard-open" : "story-yard-base" }
    var roomImageName: String {
        if let sideImageName { return sideImageName }
        if room == .yard { return yardImageName }
        if room == .corridor { return roomDoorIsOpen ? "hk-corridor-open-empty" : "hk-corridor-empty" }
        return room.imageName
    }
    /// Eggs already in the bar.
    var collected: Set<EggId> = []
    /// Front door has accepted `coveredinyou`.
    var doorOpened = false
    /// Mailbox has accepted `817` and awarded the first keepsake.
    var mailboxOpened = false
    /// Hotel bedroom door has accepted this save’s generated code. Navigation does not award an egg.
    var corridorUnlocked = false
    var roomDoorIsOpen: Bool { collected.contains(.keycard) || memories.legacyRoomAccess == true }
    var elementReturnOverlay: GameOverlay? = nil
    /// Layer above the room.
    var overlay: GameOverlay = .none
    /// Concatenated stave on the lyric lock (kept across wrong tries and app switches).
    var lyricDraft = ""
    /// Shuffled 4×4 pad; frozen while the lock screen is up.
    var lyricPad: [String] = []
    /// Text still in the plaque stave.
    var plaqueDraft = ""
    /// Shuffled 3×3 mailbox pad; frozen while that lock is up.
    var plaquePad: [String] = []
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
    /// Newly earned items waiting for the shared reveal-and-flight presentation. Never persisted.
    private(set) var collectionQueue: [EggId] = []
    var collectingEgg: EggId? { collectionQueue.first }
    /// A repeat tap is presentation only: it never enters the reward queue or the save.
    private(set) var replayingEgg: EggId?
    /// Door 1px flash after two idle minutes in the yard.
    var doorGlow: Double = 0
    /// True after the once-per-session door flash has played.
    var didFlashDoor = false
    /// Dialogue kept when the overlay is `.dialogue`.
    var dialogueLine = ""
    /// Mirrors `@Environment(\.accessibilityReduceMotion)` from the root view.
    var prefersReducedMotion = false
    /// True after he has tapped the plate ivy covering `the date we met`.
    var plaqueHintRevealed = false
    /// Covering vine opacity. Recedes on first tap; 0 once the engraving is readable.
    var plateIvyOpacity: Double = 1
    /// Frozen sway cell while the covering vine recedes. Nil means follow the yard clock.
    var plateIvyHoldFrame: Int?
    /// Ping-pong 0...2 for the yard vine sway frames. Plate ivy shares this clock.
    var ivySwayFrame = 0
    /// Bumped when the rules letter should unroll from the bound roll.
    var envelopePlayID = 0
    /// True after the first unroll (or a skipped / restored open). Later opens hold the last cell.
    var envelopeDidUnroll = false
    /// Cloud strip origin in game pixels; wraps every `GameCanvas.cloudPeriod`.
    var cloudOffset = 0
    /// Boot card is up until Enter.
    var isIntro = true
    var vuoriDraft = ""
    var vuoriMiss = false
    /// Ephemeral return context for a keepsake opened from the inventory.
    var vuoriMemoryReturnOverlay: GameOverlay = .none
    var lotteryDrawn = false
    var corridorDigits = [0, 0, 0, 0]
    var corridorMiss = false
    var keycardJustDispensed = false
    var petalHeld = false
    var gelatoSelection: Set<GelatoFlavor> = []
    var exploration = ExplorationProgress()
    var memories = MemoryProgress()
    var memoryNavigation: [MemoryPanel] = []
    var notebookReturnOverlay: GameOverlay? = nil
    var selectedTool: AdventureTool?
    // Shared transient selection lets the footer return a box bottle by tap.
    var selectedPerfumeBottle: AdventureTool?
    var toolsVisible = false
    var notebookClueFlash = false
    // Transient drag geometry never enters the saved progress snapshot.
    var draggedRosePetal: Int?
    var roseDragLocation: CGPoint = .zero
    var roseDropFrame: CGRect = .null
    var roseThreaded = false
    var returnToRecipe = false
    var returnToGelato = false
    var sceneHint = ""
    var sceneHintTone: IvyMessageTone = .ordinary
    var sceneHintPresentation: IvyMessagePresentation = .puzzle
    var assembleHintTone: IvyMessageTone = .ordinary
    var isHallTransitioning = false
    var lotteryReady: Bool { EggId.allCases.allSatisfy { collected.contains($0) } }


    private var persistTask: Task<Void, Never>?
    private var atmosphereTask: Task<Void, Never>?
    var atmosphereActive = true
    /// Clears the hairline caption after a short hold.
    private var captionHideTask: Task<Void, Never>?
    var notebookFlashTask: Task<Void, Never>?
    /// Plays the plate-ivy recede, then the engraving caption.
    private var plateIvyTask: Task<Void, Never>?
    /// Holds a solved assemble stave when a cut still needs a beat.
    private var assembleFinishTask: Task<Void, Never>?
    /// Isolated in tests so suites never share the phone snapshot.
    private let defaults: UserDefaults
    private static let persistKey = "ivy.game.snapshot.v4"
    /// Cloud x where `____` stays readable when Reduce Motion freezes the sky.
    private static let readableCloudOffset = 242

    /// Restores on-device progress if this phone has already played.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        if env["IVY_PREVIEW_DIALOGUE"] == "1" {
            overlay = .dialogue(GameCopy.doorNeedsLetter)
            isIntro = false
        }
        if env["IVY_PREVIEW_ICONS"] == "1" {
            collected = Set(EggId.allCases)
            isIntro = false
        }
        if env["IVY_PREVIEW_YARD"] == "1" {
            room = .yard
            overlay = .none
            doorOpened = false
            collected = []
            isIntro = false
        }
        if env["IVY_PREVIEW_LOCK"] == "1" {
            room = .yard
            overlay = .lyric
            lyricPad = AssembleKind.lyric.glyphs.shuffled()
            isIntro = false
        }
        if let vines = env["IVY_PREVIEW_VINES"], let stage = Int(vines) {
            room = .yard
            overlay = .none
            collected = []
            if stage >= 1 { mailboxOpened = true; collected.insert(.letter) }
            if stage >= 2 { doorOpened = true }
            isIntro = false
        }
        if let review = env["IVY_REVIEW"] {
            exploration = ExplorationProgress()
            memories = MemoryProgress()
            selectedTool = nil
            toolsVisible = false
            isIntro = false
            room = .yard
            overlay = .none
            mailboxOpened = false
            doorOpened = false
            collected = []
            plaqueHintRevealed = false
            plateIvyOpacity = 1
            plaqueDraft = ""
            lyricDraft = ""
            vuoriDraft = ""
            if ["hall", "hall-ready", "vuori", "vuori-linked", "vuori-wrong", "vuori-memory", "vuori-bar", "prize"].contains(review) {
                room = .hall
                mailboxOpened = true
                doorOpened = true
                collected = [.letter]
                if review == "hall-ready" || review == "prize" { collected = Set(EggId.allCases) }
                if review == "vuori" { overlay = .vuori }
                if review == "vuori-linked" { overlay = .vuori; vuoriDraft = "vuo" }
                if review == "vuori-wrong" {
                    overlay = .vuori; vuoriDraft = "lvaou"; vuoriMiss = true
                    sceneHint = "That doesn't feel familiar."; sceneHintTone = .wrong
                }
                if review == "vuori-memory" || review == "vuori-bar" {
                    collected.insert(.vuori)
                    if review == "vuori-memory" { overlay = .vuoriMemory }
                }
                if review == "prize" { overlay = .prize }
            } else if ["plane", "corridor", "corridor-open", "hotel-lock", "bedroom", "rose", "rose-complete", "rose-collect", "city", "gelato", "flavors"].contains(review) {
                mailboxOpened = true
                doorOpened = true
                collected = [.letter, .vuori]
                corridorUnlocked = review == "corridor-open" || ["bedroom", "rose", "rose-complete", "rose-collect", "city", "gelato", "flavors"].contains(review)
                switch review {
                case "plane": room = .plane
                case "corridor", "corridor-open": room = .corridor
                case "hotel-lock": room = .corridor; overlay = .hotelLock
                case "rose", "rose-complete", "rose-collect":
                    room = .bedroom; overlay = .memory(.bouquet)
                    memories.rose = RoseProgress(revealed: Set(0..<3), found: Set(0..<3))
                    if review == "rose-complete" { collected.insert(.rose) }
                    if review == "rose-collect" { collected.insert(.rose); collectionQueue = [.rose] }
                case "city": room = .bedroom; overlay = .observation(.city)
                case "gelato": room = .gelato
                case "flavors": room = .gelato; overlay = .gelato
                default: room = .bedroom
                }
            } else if review == "mailbox" || review == "mailbox-revealed" {
                overlay = .plaque
                plaquePad = AssembleKind.plaque.glyphs
                plaqueHintRevealed = review == "mailbox-revealed"
                plateIvyOpacity = plaqueHintRevealed ? 0 : 1
            } else if review == "door" || review == "long-draft" {
                mailboxOpened = true
                overlay = .lyric
                lyricPad = AssembleKind.lyric.glyphs
                lyricDraft = review == "long-draft" ? "coveredinyou817aaaaaa" : ""
            } else if review == "grown" {
                mailboxOpened = true
                doorOpened = true
                collected = [.letter]
            } else if review == "dialogue" {
                overlay = .dialogue(GameCopy.doorNeedsLetter)
            } else if review == "letter" || review == "envelope" {
                mailboxOpened = true
                collected = [.letter]
                envelopeDidUnroll = review == "letter"
                presentEnvelope()
            } else if review == "collect" {
                mailboxOpened = true
                collect(.letter, playHaptic: false)
            }
        }
        if let name = env["IVY_REVIEW"], name.hasPrefix("explore-") {
            isIntro = false
            mailboxOpened = true
            doorOpened = true
            collected = [.letter]
            exploration = ExplorationProgress()
            memories = MemoryProgress()
            exploration.hotelCode = [4, 7, 2, 9]
            let part = String(name.dropFirst(8))
            switch part {
            case "yard-garden": room = .yard; exploration.views[room.rawValue] = 1
            case "hall-desk": room = .hall; exploration.views[room.rawValue] = 1
            case "plane-window": room = .plane; exploration.views[room.rawValue] = 1
            case "corridor-cart": room = .corridor; exploration.views[room.rawValue] = -1
            case "corridor-mirror": room = .corridor; exploration.views[room.rawValue] = 1
            case "bedroom-desk": room = .bedroom; exploration.views[room.rawValue] = 1
            case "gelato-bench": room = .gelato; exploration.views[room.rawValue] = -1
            case "gelato-service": room = .gelato; exploration.views[room.rawValue] = 1
            case "notebook":
                room = .corridor
                exploration.clues = Set(AdventureClue.allCases)
                overlay = .adventure(.notebook)
            case "mirror":
                room = .corridor; overlay = .adventure(.mirror); exploration.clues.insert(.mirror)
            case "music": room = .bedroom; overlay = .adventure(.musicBox)
            case "stitch":
                room = .bedroom; overlay = .memory(.bouquet)
                memories.rose = RoseProgress(revealed: Set(0..<3), found: Set(0..<3))
            case "recipe":
                room = .gelato; overlay = .adventure(.recipe); exploration.clues.insert(.recipe)
            case "freezer": room = .gelato; overlay = .adventure(.freezer)
            case "gelato":
                room = .gelato; overlay = .gelato; exploration.freezerTemperature = -12
                exploration.scoops = [.pistachio, .pistachio]
            case "walk":
                room = .yard; overlay = .none
                Task { [weak self] in
                    try? await Task.sleep(for: .milliseconds(1400))
                    self?.tapYardDoor()
                }
            default: room = .yard
            }
            exploration.tools = Set(AdventureTool.allCases)
            toolsVisible = true
        }
        if let review = env["IVY_REVIEW"], review.hasPrefix("memory-") {
            let name = String(review.dropFirst(7)).replacingOccurrences(of: "-open", with: "")
            if let panel = MemoryPanel(rawValue: name) {
                room = panel.room; overlay = .memory(panel); isIntro = false
                exploration = ExplorationProgress(); memories = MemoryProgress()
                exploration.tools = [.brassKey, .eraser, .cloth, .coin, .scoop]
                if review.hasSuffix("-open") { memories.opened.insert(panel.rawValue) }
                if panel == .flight { memories.origin = "Hangzhou"; memories.destination = "Hong Kong" }
                if panel == .ticket { exploration.clues.insert(.travelOrder) }
                if panel == .tasting { memories.menuSolved = true }
                sceneHint = ""
            }
        }
        if let review = env["IVY_REVIEW"], review.hasPrefix("rub-") {
            exploration = ExplorationProgress(); memories = MemoryProgress(); sceneHint = ""
            let clue: AdventureClue
            if review.contains("mirror") {
                room = .corridor; overlay = .adventure(.mirror); clue = .mirror
                exploration.tools = [.cloth]; selectedTool = .cloth
            } else if review.contains("rain") {
                room = .gelato; overlay = .adventure(.recipe); clue = .recipe
                exploration.tools = [.napkin]; selectedTool = .napkin
            } else {
                room = .plane; overlay = .memory(.ticket); clue = .travelOrder
                exploration.tools = [.eraser]; selectedTool = .eraser
            }
            if review.hasSuffix("partial") {
                var p = RubbingProgress()
                let size = CGSize(width: 320, height: 120)
                p.begin(at: CGPoint(x: 35, y: 70), size: size)
                p.append(CGPoint(x: 85, y: 45), size: size)
                p.append(CGPoint(x: 125, y: 65), size: size)
                exploration.rubbing = [clue.rawValue: p]
            }
        }
        if let review = env["IVY_REVIEW"], ["gelato-kept", "gelato-joke", "gelato-wrong", "gelato-menu-solved", "gelato-recipe-wet"].contains(review) {
            room = .gelato; isIntro = false; overlay = .memory(.tasting)
            memories.menuSolved = true; memories.menu = [0, 1, 2, 3]
            exploration.tools.insert(.scoop)
            if review == "gelato-wrong" { memories.flavor = 0; confirmTaste() }
            if review == "gelato-menu-solved" { overlay = .memory(.menu) }
            if review == "gelato-recipe-wet" {
                overlay = .adventure(.recipe); exploration.tools.insert(.napkin); selectedTool = .napkin
            }
            if ["gelato-kept", "gelato-joke"].contains(review) {
                collected.insert(.gelato); memories.flavor = 2; memories.opened.insert("dispenser")
                memories.picked.insert(.scoop); memories.used.insert(.scoop); exploration.tools.remove(.scoop)
            }
            if review == "gelato-joke" { recallGelatoJoke() }
        }
        if let review = env["IVY_REVIEW"], review.hasPrefix("prompts-") {
            switch review {
            case "prompts-garden":
                room = .yard; exploration.views[room.rawValue] = 1
            case "prompts-short":
                room = .yard; exploration.views[room.rawValue] = 1
                sceneHint = "The ivy rustles."; sceneHintPresentation = .interaction
            case "prompts-long":
                sceneHint = "Some words hide behind clouds. Some stay with you."; sceneHintPresentation = .interaction
            case "prompts-wrap":
                sceneHint = "Some words hide behind clouds. Some stay with you. The house keeps a little warmth for the two of us, even on the longest nights."; sceneHintPresentation = .interaction
            case "prompts-success":
                sceneHint = "A new clue is in your notebook."; sceneHintTone = .success
            case "prompts-wrong":
                sceneHint = "This key does not fit."; sceneHintTone = .wrong
            case "prompts-mailbox":
                overlay = .plaque; plaquePad = AssembleKind.plaque.glyphs
                plaqueDraft = "816"; plaqueHint = GameCopy.plaqueWrong; assembleHintTone = .wrong
                plaqueHintRevealed = true; plateIvyOpacity = 0
            case "prompts-door":
                overlay = .lyric; lyricPad = AssembleKind.lyric.glyphs
                lyricDraft = "ivy"; lyricHint = GameCopy.lyricWrong; assembleHintTone = .wrong
            case "prompts-word":
                room = .bedroom; overlay = .memory(.wholeBox)
                memories.wholeDraft = "whole"; showInputError("You once asked what I loved about you.")
            case "prompts-closeup":
                room = .hall; overlay = .memory(.drawer)
                sceneHint = "This key does not fit."; sceneHintTone = .wrong
            case "prompts-hotel":
                room = .corridor; overlay = .hotelLock
                showInputError("Not our door. Not yet.")
            default: break
            }
        }
        #endif
        // Materialize once, before either world or closeup reads the shuffled sign.
        if memories.bigTop == nil { memories.bigTop = BigTopProgress() }
        if !isIntro {
            startAtmosphere()
        }
    }

    /// Leaves the title card and starts the yard wind.
    func dismissIntro() {
        guard isIntro else { return }
        isIntro = false
        startAtmosphere()
        schedulePersist()
    }

    /// True when a pad assemble screen is up (door or mailbox).
    var isAssembleLock: Bool {
        overlay == .lyric || overlay == .plaque
    }

    /// True when the front-door assemble screen is up.
    var isLyricLock: Bool {
        overlay == .lyric
    }

    /// Which pad is showing, if any.
    var assembleKind: AssembleKind? {
        switch overlay {
        case .lyric: .lyric
        case .plaque: .plaque
        default: nil
        }
    }

    /// Stave for the open pad.
    var assembleDraft: String {
        get { overlay == .plaque ? plaqueDraft : lyricDraft }
        set {
            if overlay == .plaque {
                plaqueDraft = newValue
            } else {
                lyricDraft = newValue
            }
        }
    }

    /// Shuffled tiles for the open pad.
    var assemblePad: [String] {
        get { overlay == .plaque ? plaquePad : lyricPad }
        set {
            if overlay == .plaque {
                plaquePad = newValue
            } else {
                lyricPad = newValue
            }
        }
    }

    /// Hairline caption for the open pad.
    var assembleHint: String {
        overlay == .plaque ? plaqueHint : lyricHint
    }

    /// Legacy letter view eligibility; the mailbox itself is no longer an egg.
    var hasLetter: Bool {
        mailboxOpened
    }

    /// Bilateral vine density: date remembered, then the door opened.
    var yardVineStage: Int {
        min(2, (mailboxOpened ? 1 : 0) + (doorOpened ? 1 : 0))
    }

    /// Opens the lyric lock after the mailbox key is his. Until then the door only speaks.
    func tapYardDoor() {
        guard !isHallTransitioning, collectingEgg == nil else { return }
        if doorOpened {
            IvyHaptics.light()
            transition(to: .hall)
            return
        }
        if !mailboxOpened {
            IvyHaptics.soft()
            say(GameCopy.doorNeedsLetter)
            return
        }
        IvyHaptics.light()
        lyricPad = AssembleKind.lyric.glyphs.shuffled()
        overlay = .lyric
        schedulePersist()
    }

    /// Vine never asks for the password; it only talks.
    func tapYardIvy() {
        IvyHaptics.soft()
        let lines = GameCopy.vineHints
        let index = min(vineHintIndex, lines.count - 1)
        say(lines[index])
        if vineHintIndex < lines.count {
            vineHintIndex += 1
        }
        schedulePersist()
    }

    /// Mailbox is the date key. After `817`, tapping it rereads the letter.
    func tapYardMailbox() {
        IvyHaptics.light()
        if mailboxOpened {
            presentEnvelope()
            return
        }
        plaquePad = AssembleKind.plaque.glyphs.shuffled()
        overlay = .plaque
        schedulePersist()
    }

    /// Look closer on the mailbox plate: ivy recedes, then the hairline names the engraving.
    func tapPlateIvy() {
        guard overlay == .plaque else { return }
        if plaqueHintRevealed {
            guard plateIvyTask == nil else { return }
            revealCaption(\.plaqueHint, GameCopy.plaqueEngraving)
            return
        }
        guard plateIvyTask == nil else { return }
        plaqueHintRevealed = true
        plateIvyHoldFrame = ivySwayFrame
        IvyHaptics.light()
        schedulePersist()
        plateIvyTask = Task { [weak self] in
            await self?.recedePlateIvy()
            self?.plateIvyTask = nil
        }
    }

    /// Empty yard taps stay quiet. Soft haptic only.
    func tapYardMiss(gamePoint _: CGPoint) {
        tapMiss()
    }

    func tapLottery() {
        guard room == .hall, !isHallTransitioning, collectingEgg == nil else { return }
        guard lotteryReady else {
            showSceneHint("The little machine is waiting for all thirteen memories.", tone: .wrong)
            IvyHaptics.soft()
            return
        }
        lotteryDrawn = true
        overlay = .prize
        IvyHaptics.success()
        schedulePersist()
    }

    /// Hall night door walks back to the yard.
    func tapHallExit() {
        tapDiegetic(.hallExit)
    }

    /// Furniture that is not a walk object stays quiet.
    func tapHallRest() {
        tapMiss()
    }

    /// Sky, stones, unused furniture. Soft haptic only.
    func tapMiss() {
        IvyHaptics.soft()
        showSceneHint(selectedTool == nil ? ambientLine : "Nothing here needs the " + selectedTool!.label + ".", tone: selectedTool == nil ? .ordinary : .wrong, presentation: .interaction)
    }

    /// Walk a diegetic object; the hotel door requires committed room access.
    func tapDiegetic(_ edge: DiegeticEdge) {
        guard canExplore, sceneView == 0 else { return }
        if room == .gelato, edge == .gelatoForward, !bigTop.signSolved { openMemory(.bigTopSign); return }
        if room == .noodle, edge == .noodleForward, !bigTop.orderSolved && !bigTop.streetUnlocked && !collected.contains(.noodle) {
            showSceneHint("Our table is still waiting.", presentation: .interaction); return
        }
        if room == .perfume, edge == .perfumeForward, !perfumery.cinemaUnlocked && !collected.contains(.perfume) {
            showSceneHint("That familiar scent, somewhere nearby.", presentation: .interaction); return
        }
        if room == .plane, edge == .planeDepart { openMemory(.flight); return }
        if room == .corridor, edge == .corridorForward, !roomDoorIsOpen {
            overlay = corridorUnlocked ? .memory(.keycard) : .hotelLock
            corridorMiss = false
            return
        }
        guard let next = RoomGraph.destination(
            from: room,
            edge: edge,
            corridorUnlocked: roomDoorIsOpen
        ) else {
            IvyHaptics.soft()
            return
        }
        IvyHaptics.light()
        transition(to: next)
    }

    /// Dismisses talk or input. Drafts stay. Envelope returns to the yard.
    func cancelOverlay() {
        if overlay == .adventure(.notebook) { closeNotebook(); return }
        if case .observation = overlay, let previous = elementReturnOverlay {
            elementReturnOverlay = nil
            overlay = previous
            sceneHint = ""
            return
        }
        if overlay == .vuoriMemory { dismissVuoriMemory(); return }
        guard assembleFinishTask == nil else { return }
        plateIvyTask?.cancel()
        plateIvyTask = nil
        if plaqueHintRevealed {
            plateIvyOpacity = 0
            plateIvyHoldFrame = nil
        }
        memoryNavigation = []
        notebookReturnOverlay = nil
        returnToRecipe = false
        overlay = returnToGelato ? .gelato : .none
        returnToGelato = false
        sceneHint = ""
        schedulePersist()
    }

    /// Opens the letter. Unrolls only the first time.
    private func presentEnvelope() {
        if !envelopeDidUnroll {
            envelopePlayID += 1
        }
        overlay = .envelope
        schedulePersist()
    }

    /// The readable sheet is on screen. Later opens skip the roll.
    func markEnvelopeUnrolled() {
        guard !envelopeDidUnroll else { return }
        envelopeDidUnroll = true
        schedulePersist()
    }

    /// Closes the letter. The date key is already remembered.
    func dismissEnvelope() {
        guard overlay == .envelope else { return }
        overlay = .none
        schedulePersist()
    }

    /// Bar slot re-reads the letter without charging the egg again.
    func reopenEnvelopeFromBar() {
        guard hasLetter, !isHallTransitioning, collectingEgg == nil else { return }
        IvyHaptics.soft()
        presentEnvelope()
    }

    /// Dismisses the dialogue box.
    func dismissDialogue() {
        guard case .dialogue = overlay else { return }
        overlay = .none
    }

    /// Appends one pad glyph. Enter is what checks the stave.
    func appendAssembleGlyph(_ glyph: String) {
        guard isAssembleLock else { return }
        guard assembleDraft.count < LockLayout.staveCap else {
            IvyHaptics.warning()
            shakeWorld()
            return
        }
        clearAssembleFeedback()
        assembleDraft += glyph
        IvyHaptics.light()
        schedulePersist()
    }

    /// Checks the stave only after Enter. Empty line is a no-op.
    func submitAssemble() {
        guard assembleFinishTask == nil, worldDim < 0.1 else { return }
        guard let kind = assembleKind else { return }
        guard !assembleDraft.isEmpty else {
            IvyHaptics.soft()
            return
        }
        if assembleDraft == kind.answer {
            finishAssemble(kind)
        } else {
            let hint = kind == .plaque ? GameCopy.plaqueWrong : GameCopy.lyricWrong
            registerAssembleMiss(hint)
            schedulePersist()
        }
    }

    /// Drops the last stave glyph. Does not count as a miss.
    func backspaceAssemble() {
        guard isAssembleLock, !assembleDraft.isEmpty else { return }
        clearAssembleFeedback()
        assembleDraft.removeLast()
        schedulePersist()
    }

    /// Clears the stave and stays on the lock. Pad order does not reshuffle.
    func resetAssembleStave() {
        guard isAssembleLock, !assembleDraft.isEmpty else { return }
        clearAssembleFeedback()
        assembleDraft = ""
        IvyHaptics.light()
        schedulePersist()
    }

    /// Two idle minutes in the locked yard: flash the door once.
    func considerDoorNudge() {
        guard !didFlashDoor, !doorOpened, room == .yard, !isAssembleLock, !isIntro else { return }
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

    #if DEBUG
    /// DEBUG only: restart in the Jellycat bedroom with the hotel door unlocked.
    func resetToUnlockedRoom(persistResult: Bool = true) {
        let earlierRooms: Set<Room> = [.yard, .hall, .plane, .corridor]
        let earlierTools: Set<AdventureTool> = [.brassKey, .magnifier, .eraser, .ticket, .cloth]
        let earlierClues: Set<AdventureClue> = [.gardenDate, .label, .travelOrder, .mirror]
        let previousExploration = exploration
        let previousMemories = memories
        persistTask?.cancel()
        persistTask = nil
        captionHideTask?.cancel()
        captionHideTask = nil
        plateIvyTask?.cancel()
        plateIvyTask = nil
        assembleFinishTask?.cancel()
        assembleFinishTask = nil
        room = .bedroom
        exploration = ExplorationProgress()
        memories = MemoryProgress()
        memories.bigTop = BigTopProgress()
        exploration.hotelCode = previousExploration.hotelCode
        exploration.drawerOpened = previousExploration.drawerOpened
        exploration.tools = previousExploration.tools.intersection(earlierTools)
        exploration.clues = previousExploration.clues.intersection(earlierClues)
        exploration.rubbing = previousExploration.rubbing?.filter { entry in
            earlierClues.contains { $0.rawValue == entry.key }
        }
        exploration.views = previousExploration.views.filter { entry in
            earlierRooms.contains { $0.rawValue == entry.key }
        }
        memories.opened = previousMemories.opened.filter { id in
            guard let panel = MemoryPanel(rawValue: id) else { return false }
            return earlierRooms.contains(panel.room)
        }
        memories.picked = previousMemories.picked.intersection(earlierTools)
        memories.used = previousMemories.used.intersection(earlierTools)
        memories.origin = "Hangzhou"
        memories.destination = "Hong Kong"
        memories.flightDeparted = true
        memoryNavigation = []
        notebookReturnOverlay = nil
        returnToRecipe = false
        selectedTool = nil
        toolsVisible = false
        roseThreaded = false
        returnToGelato = false
        vuoriDraft = ""
        vuoriMiss = false
        vuoriMemoryReturnOverlay = .none
        corridorDigits = exploration.hotelCode
        corridorMiss = false
        petalHeld = false
        gelatoSelection = []
        sceneHint = ""
        lotteryDrawn = false
        isHallTransitioning = false
        collected = collected.intersection([.letter, .vuori, .plane, .keycard])
        collected.formUnion([.letter, .vuori, .plane])
        doorOpened = true
        mailboxOpened = true
        corridorUnlocked = true
        memories.legacyRoomAccess = true
        overlay = .none
        lyricDraft = ""
        lyricPad = []
        plaqueDraft = ""
        plaquePad = []
        lyricHint = ""
        plaqueHint = ""
        lyricFailCount = 0
        vineHintIndex = 0
        worldDim = 0
        worldOffsetX = 0
        slotPulse = nil
        collectionQueue = []
        replayingEgg = nil
        doorGlow = 0
        didFlashDoor = false
        dialogueLine = ""
        plateIvyHoldFrame = nil
        ivySwayFrame = 0
        envelopePlayID = 0
        envelopeDidUnroll = false
        cloudOffset = 0
        isIntro = false
        if persistResult { persistNow() }
    }

    /// DEBUG only: keep the prefix, then reopen the selected keepsake's scene.
    func reset(before egg: EggId) {
        let index = egg.slotIndex
        let savedExploration = exploration
        let savedMemories = memories
        resetToUnlockedRoom(persistResult: false)

        if index < EggId.city.slotIndex {
            if index <= EggId.letter.slotIndex {
                exploration = ExplorationProgress()
                memories = MemoryProgress()
                doorOpened = false
                mailboxOpened = false
                corridorUnlocked = false
                plaqueHintRevealed = false
                plateIvyOpacity = 1
                envelopeDidUnroll = false
            } else if index <= EggId.vuori.slotIndex {
                exploration = ExplorationProgress()
                memories = MemoryProgress()
                doorOpened = true
                mailboxOpened = true
                corridorUnlocked = false
            } else if index <= EggId.plane.slotIndex {
                exploration = ExplorationProgress()
                memories = MemoryProgress()
                exploration.hotelCode = savedExploration.hotelCode
                exploration.drawerOpened = savedExploration.drawerOpened
                exploration.views = savedExploration.views.filter { ["yard", "hall"].contains($0.key) }
                exploration.tools = savedExploration.tools.intersection([.brassKey, .magnifier, .eraser])
                exploration.clues = savedExploration.clues.intersection([.gardenDate, .label])
                memories.opened = savedMemories.opened.filter { ["pot", "drawer"].contains($0) }
                memories.picked = savedMemories.picked.intersection([.brassKey, .magnifier, .eraser])
                memories.used = savedMemories.used.intersection([.brassKey, .magnifier, .eraser])
                corridorUnlocked = false
            } else {
                exploration = ExplorationProgress()
                memories = MemoryProgress()
                exploration.hotelCode = savedExploration.hotelCode
                exploration.drawerOpened = savedExploration.drawerOpened
                exploration.views = savedExploration.views.filter { ["yard", "hall", "plane"].contains($0.key) }
                exploration.tools = savedExploration.tools.intersection([.brassKey, .magnifier, .eraser, .ticket])
                exploration.clues = savedExploration.clues.intersection([.gardenDate, .label, .travelOrder])
                exploration.rubbing = savedExploration.rubbing?.filter { $0.key == AdventureClue.travelOrder.rawValue }
                memories.opened = savedMemories.opened.filter { ["pot", "drawer", "flight", "ticket", "travelBook", "yunnan"].contains($0) }
                memories.picked = savedMemories.picked.intersection([.brassKey, .magnifier, .eraser, .ticket])
                memories.used = savedMemories.used.intersection([.brassKey, .magnifier, .eraser, .ticket])
                memories.origin = savedMemories.origin
                memories.destination = savedMemories.destination
                memories.flightDeparted = true
                corridorUnlocked = false
                memories.legacyRoomAccess = false
            }
        } else if index > EggId.city.slotIndex {
            exploration = savedExploration
            memories = savedMemories
            let roomOrder: [Room] = [.yard, .hall, .plane, .corridor, .bedroom, .gelato, .noodle, .perfume, .cinema, .sunset, .ferris, .taxi]
            let targetRoomIndex = index == EggId.rose.slotIndex ? 4 : index - 1
            exploration.views = exploration.views.filter { key, _ in
                (roomOrder.firstIndex { $0.rawValue == key } ?? roomOrder.count) < targetRoomIndex
            }
            memories.opened = memories.opened.filter { id in
                guard let panel = MemoryPanel(rawValue: id),
                      let roomIndex = roomOrder.firstIndex(of: panel.room) else { return true }
                return roomIndex < targetRoomIndex
            }
            if index <= EggId.rose.slotIndex {
                memories.rose = nil
                memories.bedroomLampOn = nil
                memories.bathWarm = false
                memories.bathRevealed = false
                exploration.musicBoxOpened = false
                exploration.musicInput = []
                exploration.tools.remove(.sewingKit)
                memories.picked.remove(.sewingKit)
                memories.used.remove(.sewingKit)
            }
            if index <= EggId.gelato.slotIndex {
                memories.menuSolved = false
                memories.flavor = nil
                memories.gelatoWater = nil
                exploration.freezerTemperature = -4
                exploration.scoops = []
                exploration.clues.subtract([.recipe, .temperature, .rainRelation])
                exploration.tools.subtract([.coin, .scoop])
                memories.picked.subtract([.coin, .scoop])
                memories.used.subtract([.coin, .scoop])
            }
            if index <= EggId.noodle.slotIndex {
                memories.bigTop = BigTopProgress()
                memories.bigTopDraft = ""
                memories.wholeDraft = ""
                exploration.tools.remove(.dinnerMenu)
                memories.picked.remove(.dinnerMenu)
                memories.used.remove(.dinnerMenu)
            }
            if index <= EggId.perfume.slotIndex {
                memories.perfumery = PerfumeProgress()
                exploration.clues.subtract([.gaiacFormula, .bergamoteFormula, .mousseFormula, .perfumeOrder])
                let bottles = Set(PerfumeIngredient.all.map(\.tool))
                exploration.tools.subtract(bottles)
                memories.picked.subtract(bottles)
                memories.used.subtract(bottles)
            }
            if index <= EggId.cinema.slotIndex {
                memories.cinemaSeats = []
                memories.cinemaDraft = ""
            }
            if index <= EggId.sunset.slotIndex { memories.sunsetFrame = 0.15 }
            if index <= EggId.ferris.slotIndex { memories.ferrisMatches = [] }
            if index <= EggId.taxi.slotIndex { memories.taxiDraft = "" }
        }

        collected = Set(EggId.allCases.prefix(index))
        if index > EggId.letter.slotIndex { mailboxOpened = true; doorOpened = true }
        if index > EggId.plane.slotIndex {
            memories.flightDeparted = true
            exploration.clues.insert(.travelOrder)
        }
        if index > EggId.keycard.slotIndex {
            corridorUnlocked = true
            memories.legacyRoomAccess = true
        }
        if index > EggId.city.slotIndex {
            memories.citySolved = true
            memories.cityBoard = Array(0..<9).map { Optional($0) }
        }
        if index > EggId.gelato.slotIndex {
            memories.menuSolved = true
            var progress = bigTop
            progress.signSolved = true
            bigTop = progress
        }
        if index > EggId.noodle.slotIndex {
            var progress = bigTop
            progress.orderSolved = true
            progress.streetUnlocked = true
            bigTop = progress
        }
        if index > EggId.perfume.slotIndex {
            var progress = perfumery
            progress.cinemaUnlocked = true
            perfumery = progress
        }

        room = switch egg {
        case .letter: .yard
        case .vuori: .hall
        case .plane: .plane
        case .keycard: .corridor
        case .city, .rose: .bedroom
        case .gelato: .gelato
        case .noodle: .noodle
        case .perfume: .perfume
        case .cinema: .cinema
        case .sunset: .sunset
        case .ferris: .ferris
        case .taxi: .taxi
        }
        exploration.views[room.rawValue] = 0
        corridorDigits = exploration.hotelCode
        persistNow()
    }
    #endif

    /// Starts the yard's 1px cloud drift and 3-frame ivy sway. Idempotent.
    func startAtmosphere() {
        guard atmosphereTask == nil else { return }
        atmosphereTask = Task { [weak self] in
            var dir = 1
            var ticks = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(125))
                guard let self, !Task.isCancelled else { return }
                guard self.atmosphereActive, self.room == .yard else { continue }
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
                self.cloudOffset = (self.cloudOffset + 1) % GameCanvas.cloudPeriod
            }
        }
    }

    /// Re-reads a collected egg from the bar.
    func speakReread(_ line: String) {
        IvyHaptics.soft()
        say(line)
    }

    /// Unlock when Enter accepted the exact locked answer.
    private func finishAssemble(_ kind: AssembleKind) {
        switch kind {
        case .lyric:
            finishLyricIfComplete()
        case .plaque:
            finishPlaque()
        }
    }

    /// Award the letter; after it lands in slot one, show the scroll.
    private func finishPlaque() {
        IvyHaptics.success()
        captionHideTask?.cancel()
        plaqueHint = ""
        mailboxOpened = true
        plaqueDraft = ""
        overlay = .none
        collect(.letter, playHaptic: false)
    }

    /// Unlock when Enter accepted the exact locked answer.
    private func finishLyricIfComplete() {
        guard LyricGate.staveState(lyricDraft) == .correct else { return }
        IvyHaptics.success()
        captionHideTask?.cancel()
        lyricHint = ""
        lyricPad = []
        doorOpened = true
        overlay = .none
        schedulePersist()
    }

    /// One entry point for every scene: commit ownership now, then queue the visual celebration.
    func collect(_ egg: EggId, playHaptic: Bool = true) {
        guard !collected.contains(egg) else { return }
        collected.insert(egg)
        toolsVisible = false
        collectionQueue.append(egg)
        if egg == .keycard { corridorUnlocked = true; persistNow() }
        else { schedulePersist() }
        if playHaptic {
            IvyHaptics.medium()
        }
    }

    /// Assembly rewards unlock immediately; their existing view transitions into Element.
    /// No collection flight or second pickup interrupts the completed object.
    func unlockAssemblyKeepsake(_ egg: EggId) {
        let complete: Bool
        switch egg {
        case .city: complete = memories.citySolved
        case .rose: complete = roseProgress.placed.count == 3
        default: return
        }
        guard complete, !collected.contains(egg) else { return }
        collected.insert(egg)
        toolsVisible = false
        persistNow()
    }

    func closeElementForFooter() {
        if case .observation = overlay {
            overlay = elementReturnOverlay ?? .none
            elementReturnOverlay = nil
            sceneHint = ""
        } else if overlay == .memory(.yunnan) {
            cancelOverlay()
        }
    }

    func replayKeepsake(_ egg: EggId) {
        guard collected.contains(egg), collectingEgg == nil, replayingEgg == nil,
              !isIntro, !isHallTransitioning else { return }
        if case .observation = overlay {
            // Switching memories retains the original return path.
        } else {
            elementReturnOverlay = overlay
        }
        sceneHint = ""
        overlay = .observation(egg)
        IvyHaptics.soft()
    }

    func finishKeepsakeReplay(_ egg: EggId) {
        guard replayingEgg == egg else { return }
        replayingEgg = nil
    }

    /// The view calls this after landing (or the reduced-motion fade). Duplicate callbacks are safe.
    func finishCollection(_ egg: EggId) {
        guard collectionQueue.first == egg else { return }
        collectionQueue.removeFirst()
        if egg == .keycard, room == .corridor {
            withAnimation(prefersReducedMotion ? nil : .easeInOut(duration: 0.6)) {
                overlay = .none
                exploration.views[Room.corridor.rawValue] = 0
                memoryNavigation = []
                sceneHint = ""
            }
            persistNow()
        }
        if egg == .plane, room == .plane, memories.flightDeparted {
            transition(to: .corridor)
        }
        slotPulse = egg
        IvyHaptics.light()
        Task {
            try? await Task.sleep(for: .milliseconds(280))
            guard slotPulse == egg else { return }
            withAnimation(.snappy(duration: 0.12)) {
                slotPulse = nil
            }
        }
        if egg == .letter, mailboxOpened, room == .yard {
            presentEnvelope()
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
    private func registerAssembleMiss(_ hint: String) {
        captionHideTask?.cancel()
        assembleHintTone = .wrong
        if overlay == .plaque {
            plaqueHint = hint
        } else {
            lyricFailCount += 1
            lyricHint = hint
        }
        IvyHaptics.warning()
        shakeWorld()
    }

    /// Covering vine leaves first; the caption names the line after a short look.
    private func recedePlateIvy() async {
        let fade = prefersReducedMotion ? 0.1 : 0.5
        withAnimation(.smooth(duration: fade)) {
            plateIvyOpacity = 0
        }
        try? await Task.sleep(for: .milliseconds(Int(fade * 1000) + 20))
        guard !Task.isCancelled else { return }
        plateIvyHoldFrame = nil
        if !prefersReducedMotion {
            try? await Task.sleep(for: .milliseconds(140))
            guard !Task.isCancelled else { return }
        }
        revealCaption(\.plaqueHint, GameCopy.plaqueEngraving)
    }

    /// Reading time scales with copy length; replacement cancels the old hold.
    private func revealCaption(_ keyPath: ReferenceWritableKeyPath<GameStore, String>, _ line: String) {
        if keyPath != \.sceneHint { assembleHintTone = .ordinary }
        withAnimation(prefersReducedMotion ? .easeInOut(duration: 0.1) : .smooth(duration: 0.4)) {
            self[keyPath: keyPath] = line
        }
        captionHideTask?.cancel()
        captionHideTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(max(5, Double(line.count) / 16)))
            guard !Task.isCancelled, let self else { return }
            withAnimation(self.prefersReducedMotion ? .easeInOut(duration: 0.1) : .smooth(duration: 0.4)) {
                self[keyPath: keyPath] = ""
            }
            self.schedulePersist()
        }
    }

    func revealSceneCaption(_ text: String) { revealCaption(\.sceneHint, text) }

    func dismissSceneHint() {
        captionHideTask?.cancel()
        sceneHint = ""
        sceneHintTone = .ordinary
        sceneHintPresentation = .puzzle
    }

    func clearAssembleFeedback() {
        captionHideTask?.cancel()
        plaqueHint = ""
        lyricHint = ""
        assembleHintTone = .ordinary
    }

    /// Input validation remains visible until the player edits or leaves the puzzle.
    func showInputError(_ text: String) {
        sceneHintPresentation = .puzzle
        captionHideTask?.cancel()
        sceneHintTone = .wrong
        sceneHint = text
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

    /// Hold the solved stave, black-cut, then unroll the letter.
    private func cutToEnvelope() async {
        let hold = prefersReducedMotion ? 80 : 200
        let veil = prefersReducedMotion ? 0.1 : 0.18
        let veilMs = prefersReducedMotion ? 120 : 200
        try? await Task.sleep(for: .milliseconds(hold))
        guard !Task.isCancelled else { return }
        withAnimation(.smooth(duration: veil)) {
            worldDim = 1
        }
        try? await Task.sleep(for: .milliseconds(veilMs))
        guard !Task.isCancelled else { return }
        plaqueDraft = ""
        var cut = Transaction()
        cut.animation = nil
        withTransaction(cut) {
            overlay = .envelope
        }
        withAnimation(.smooth(duration: veil)) {
            worldDim = 0
        }
        try? await Task.sleep(for: .milliseconds(veilMs))
        guard !Task.isCancelled else { return }
        if !envelopeDidUnroll {
            envelopePlayID += 1
        }
        schedulePersist()
    }

    /// One fade path for doors and local exploration. Room geometry never slides or shakes.
    func transition(to next: Room, view: Int = 0) {
        guard !isHallTransitioning, collectingEgg == nil else { return }
        let nextViews = Self.sceneViews(in: next)
        guard nextViews.contains(view) else { return }
        if prefersReducedMotion {
            room = next
            exploration.views[next.rawValue] = view
            worldOffsetX = 0
            overlay = .none
            sceneHint = ""
            persistNow()
            return
        }
        isHallTransitioning = true
        assembleFinishTask?.cancel()
        assembleFinishTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isHallTransitioning = false; self.assembleFinishTask = nil }
            // Prepare destination decoding while the old room remains covered.
            withAnimation(.easeInOut(duration: 0.08)) { self.worldDim = 1 }
            do { try await Task.sleep(for: .milliseconds(80)) } catch { return }
            var cut = Transaction()
            cut.disablesAnimations = true
            withTransaction(cut) {
                self.room = next
                self.exploration.views[next.rawValue] = view
                self.worldOffsetX = 0
                self.overlay = .none
                self.sceneHint = ""
                _ = SceneArtwork.image(named: self.roomImageName)
            }
            // Give the destination one render pass before the short cut-in.
            do { try await Task.sleep(for: .milliseconds(16)) } catch { return }
            withAnimation(.easeInOut(duration: 0.1)) { self.worldDim = 0 }
            do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
            self.persistNow()
        }
    }

    /// Decodes the last snapshot from UserDefaults.
    private func load() {
        guard let data = defaults.data(forKey: Self.persistKey),
              let snap = try? JSONDecoder().decode(GameSnapshot.self, from: data)
        else { return }
        isIntro = false
        room = snap.room
        memories = snap.memories ?? MemoryProgress()
        exploration = snap.exploration ?? ExplorationProgress()
        exploration.sanitize()
        collected = Set(snap.collected)
        doorOpened = snap.doorOpened
        mailboxOpened = (snap.mailboxOpened ?? false) || doorOpened || collected.contains(.letter)
        if mailboxOpened { collected.insert(.letter) }
        corridorUnlocked = snap.corridorUnlocked ?? false
        lyricDraft = snap.lyricDraft
        lyricPad = snap.lyricPad
        plaqueDraft = snap.plaqueDraft
        plaquePad = snap.plaquePad
        lyricFailCount = snap.lyricFailCount
        vineHintIndex = snap.vineHintIndex
        lyricHint = snap.lyricHint
        vuoriDraft = VuoriPuzzle.normalizedDraft(snap.vuoriDraft ?? "")
        lotteryDrawn = snap.lotteryDrawn ?? false
        if let digits = snap.corridorDigits, digits.count == 4, digits.allSatisfy({ (0...9).contains($0) }) { corridorDigits = digits }
        petalHeld = (snap.petalHeld ?? false) && !collected.contains(.rose)
        gelatoSelection = Set(snap.gelatoSelection ?? []).intersection(GelatoFlavor.correct)
        didFlashDoor = snap.didFlashDoor
        plaqueHintRevealed = snap.plaqueHintRevealed ?? false
        plateIvyOpacity = plaqueHintRevealed ? 0 : 1
        plateIvyHoldFrame = nil
        envelopeDidUnroll = snap.envelopeDidUnroll ?? false
        migrateMemories()
        switch snap.overlay {
        case .lyric:
            overlay = .lyric
            if Set(lyricPad) != Set(AssembleKind.lyric.glyphs) || lyricPad.count != AssembleKind.lyric.glyphs.count {
                lyricPad = AssembleKind.lyric.glyphs.shuffled()
            }
        case .plaque:
            overlay = .plaque
            if Set(plaquePad) != Set(AssembleKind.plaque.glyphs) || plaquePad.count != AssembleKind.plaque.glyphs.count {
                plaquePad = AssembleKind.plaque.glyphs.shuffled()
            }
        case .envelope:
            overlay = mailboxOpened ? .envelope : .none
            envelopeDidUnroll = true
        case .dialogue:
            overlay = .none
        case .none:
            overlay = .none
        }
    }

    /// Encodes progress. Dialogue is not restored (copy is cheap to tap again).
    private func persist() {
        #if DEBUG
        // Art-review launches are deliberately ephemeral and never overwrite the normal save.
        if ProcessInfo.processInfo.environment["IVY_REVIEW"] != nil { return }
        #endif
        let kind: GameSnapshot.OverlayKind
        switch overlay {
        case .lyric: kind = .lyric
        case .plaque: kind = .plaque
        case .envelope: kind = .envelope
        default: kind = .none
        }
        let snap = GameSnapshot(
            room: room,
            collected: EggId.allCases.filter { collected.contains($0) },
            doorOpened: doorOpened,
            lyricDraft: lyricDraft,
            lyricPad: lyricPad,
            plaqueDraft: plaqueDraft,
            plaquePad: plaquePad,
            lyricFailCount: lyricFailCount,
            vineHintIndex: vineHintIndex,
            overlay: kind,
            lyricHint: lyricHint,
            didFlashDoor: didFlashDoor,
            plaqueHintRevealed: plaqueHintRevealed,
            envelopeDidUnroll: envelopeDidUnroll,
            mailboxOpened: mailboxOpened,
            introSeen: !isIntro,
            corridorUnlocked: corridorUnlocked,
            vuoriDraft: vuoriDraft,
            lotteryDrawn: lotteryDrawn,
            corridorDigits: corridorDigits,
            petalHeld: petalHeld,
            gelatoSelection: GelatoFlavor.allCases.filter { gelatoSelection.contains($0) },
            exploration: exploration, memories: memories
        )
        if let data = try? JSONEncoder().encode(snap) {
            defaults.set(data, forKey: Self.persistKey)
        }
    }
}

/// Stave matching for the front door. Plaque still normalizes typed dates.
enum LyricGate {
    /// Result of comparing the current stave to `coveredinyou`.
    enum StaveState {
        case correct
        case prefix
        case wrong
    }

    /// Exact door line. Spaces never appear on the pad.
    static let answer = LockLayout.answer

    /// Prefix / exact / miss for one concatenated stave.
    static func staveState(_ stave: String) -> StaveState {
        if stave == answer { return .correct }
        if answer.hasPrefix(stave) { return .prefix }
        return .wrong
    }

    /// Plaque accepts only `817`. No aliases.
    static func plaqueMatches(_ raw: String) -> Bool {
        raw.filter(\.isNumber) == LockLayout.plaqueAnswer
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
    static let yardDoor = CGRect(x: 172, y: 66, width: 43, height: 61)
    /// Climbing vine on the left wall. Stops above the mailbox.
    static let yardIvy = CGRect(x: 103, y: 54, width: 24, height: 72)
    /// Climbing vine on the right wall. Same breadcrumb as the left flank.
    static let yardIvyRight = CGRect(x: 276, y: 52, width: 24, height: 72)
    /// Mailbox post in the grass; the date key lives here.
    static let yardMailbox = CGRect(x: 54, y: 89, width: 36, height: 54)
    /// Hall door that still shows the night yard.
    static let hallExit = CGRect(x: 19, y: 30, width: 61, height: 84)

    /// Device-space hit rect, at least 44pt, centered on the art.
    static func hitRect(_ rect: CGRect, scale: CGFloat) -> CGRect {
        let draw = CGRect(
            x: rect.minX * scale,
            y: rect.minY * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )
        let hitW = max(44, draw.width)
        let hitH = max(44, draw.height)
        return CGRect(
            x: draw.midX - hitW / 2,
            y: draw.midY - hitH / 2,
            width: hitW,
            height: hitH
        )
    }
}
