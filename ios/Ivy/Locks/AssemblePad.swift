import SwiftUI

/// Which assemble lock is on screen. Door is 4×4; mailbox is a 3×3 of nine tiles.
enum AssembleKind {
    /// Front door. Answer `coveredinyou`.
    case lyric
    /// Mailbox date key, answer `817`.
    case plaque

    /// Exact stave. No spaces, no aliases.
    var answer: String {
        switch self {
        case .lyric: LockLayout.lyricAnswer
        case .plaque: LockLayout.plaqueAnswer
        }
    }

    /// Unique pad glyphs. Shuffled each time the screen opens.
    var glyphs: [String] {
        switch self {
        case .lyric: LockLayout.lyricGlyphs
        case .plaque: LockLayout.plaqueGlyphs
        }
    }

    /// Pad columns. Lyric 4, plaque 3.
    var columns: Int {
        switch self {
        case .lyric: 4
        case .plaque: 3
        }
    }
}

/// Shared layout on the rounded enamel plate. Coordinates stay in game pixels.
enum LockLayout {
    /// Unique glyphs on the 4×4 door pad, including decoys `a`, `s`, `9`.
    static let lyricGlyphs = ["a", "c", "d", "e", "i", "n", "o", "r", "s", "u", "v", "y", "1", "7", "8", "9"]
    /// Door stave. No spaces, no aliases.
    static let lyricAnswer = "coveredinyou"
    /// Nine mailbox tiles: `2`+`9` plus decoys, including 817 as the real day.
    static let plaqueGlyphs = ["1", "2", "7", "8", "9", "a", "e", "n", "s"]
    /// Mailbox stave. Digits only; no `8.17` / `0817`.
    static let plaqueAnswer = "817"
    /// Back-compat alias for the door pad.
    static var glyphs: [String] { lyricGlyphs }
    /// Back-compat alias for the door answer.
    static var answer: String { lyricAnswer }
    /// Iron groove that holds assembled marks.
    static let stave = CGRect(x: 133, y: 22, width: 163, height: 17)
    /// Top-left of the first 4×4 tile well.
    static let padOrigin = CGPoint(x: 134, y: 46)
    /// Stone plate size.
    static let tile: CGFloat = 23
    /// Gap between wells.
    static let gap: CGFloat = 3
    /// Pitch from well to well.
    static let pitch: CGFloat = 26
    /// Leave the lock for the yard.
    static let back = CGRect(x: 16, y: 12, width: 44, height: 22)
    /// Drop the last stave glyph.
    static let del = CGRect(x: 251, y: 51, width: 45, height: 22)
    /// Clear the whole stave.
    static let reset = CGRect(x: 251, y: 85, width: 45, height: 22)
    /// Check the stave. Sits in the wood right of the pad, clear of the ivy.
    static let enter = CGRect(x: 251, y: 119, width: 45, height: 24)
    /// Plate ivy covering the mailbox engraving. Wells stay outside this hit.
    static let plateIvy = CGRect(x: 24, y: 57, width: 93, height: 49)
    /// Longest stave the groove will accept.
    static let staveCap = 20

    /// Top-left of a pad with `columns` wells, centered on the 4×4 iron plate.
    static func padOrigin(columns: Int) -> CGPoint {
        guard columns != 4 else { return padOrigin }
        let span4 = tile + 3 * pitch
        let span = tile + CGFloat(columns - 1) * pitch
        let inset = (span4 - span) / 2
        return CGPoint(x: padOrigin.x + inset, y: padOrigin.y + inset)
    }

    /// Game rect for a pad index, row-major.
    static func tileRect(index: Int, columns: Int = 4) -> CGRect {
        let origin = padOrigin(columns: columns)
        let col = CGFloat(index % columns)
        let row = CGFloat(index / columns)
        return CGRect(
            x: origin.x + col * pitch,
            y: origin.y + row * pitch,
            width: tile,
            height: tile
        )
    }
}

/// Letter pad: stave, tiles, and chrome plates. Scenes customize through properties and `backdrop`.
struct AssemblePad<Backdrop: View>: View {
    /// Shuffled glyphs currently in the wells.
    let glyphs: [String]
    /// Wells per row.
    let columns: Int
    /// Concatenated stave text.
    let draft: String
    /// Shared canvas scale.
    let scale: CGFloat
    /// Horizontal miss shake in points; ignored when Reduce Motion is on.
    var shakeX: CGFloat = 0
    /// Append one pad glyph.
    let onGlyph: (String) -> Void
    /// Drop the last stave glyph.
    let onBackspace: () -> Void
    /// Clear the stave and stay on the pad.
    let onReset: () -> Void
    /// Check the stave.
    let onSubmit: () -> Void
    /// Leave the pad for the room.
    let onCancel: () -> Void
    /// Scene-owned layer under the tiles (plate ivy). Empty by default.
    @ViewBuilder var backdrop: (_ scale: CGFloat) -> Backdrop

    /// Skip the 2pt stave shake when Reduce Motion is on.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Full pad with a scene backdrop under the wells.
    init(
        glyphs: [String],
        columns: Int,
        draft: String,
        scale: CGFloat,
        shakeX: CGFloat = 0,
        onGlyph: @escaping (String) -> Void,
        onBackspace: @escaping () -> Void,
        onReset: @escaping () -> Void,
        onSubmit: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        @ViewBuilder backdrop: @escaping (_ scale: CGFloat) -> Backdrop
    ) {
        self.glyphs = glyphs
        self.columns = columns
        self.draft = draft
        self.scale = scale
        self.shakeX = shakeX
        self.onGlyph = onGlyph
        self.onBackspace = onBackspace
        self.onReset = onReset
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        self.backdrop = backdrop
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            backdrop(scale)
            staveMarks
            ForEach(Array(glyphs.enumerated()), id: \.offset) { index, glyph in
                StoryPlateButton(
                    text: glyph,
                    rect: LockLayout.tileRect(index: index, columns: columns),
                    scale: scale,
                    label: glyph
                ) {
                    onGlyph(glyph)
                }
            }
            Button(action: onBackspace) {
                Image(systemName: "delete.left").font(.system(size: 23))
                    .frame(width: 48, height: 48)
            }.accessibilityLabel(GameCopy.lockDel)
                .position(x: LockLayout.stave.maxX * scale - 24, y: LockLayout.stave.midY * scale)
            StoryPlateButton(
                text: "enter",
                rect: LockLayout.enter,
                scale: scale,
                label: GameCopy.lockEnter,
                action: onSubmit
            )
        }
        .gameBackAction(onCancel)
    }

    /// Live handwriting in a shallow enamel recess, with no baked glyphs or hard image edges.
    private var staveMarks: some View {
        Text(draft.isEmpty ? "..." : draft)
            .font(IvyType.hand(12 * scale))
            .foregroundStyle(IvyType.cream.opacity(draft.isEmpty ? 0.5 : 1))
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .padding(.horizontal, 7 * scale)
            .frame(width: LockLayout.stave.width * scale, height: LockLayout.stave.height * scale, alignment: .leading)
            .background {
                Capsule().fill(IvyType.ink.opacity(0.45))
                    .overlay(Capsule().strokeBorder(IvyType.cream.opacity(0.2), lineWidth: 0.6 * scale))
            }
            .offset(x: reduceMotion ? 0 : shakeX)
            .position(x: LockLayout.stave.midX * scale, y: LockLayout.stave.midY * scale)
            .allowsHitTesting(false)
            .accessibilityLabel(draft.isEmpty ? "Empty line" : "Assembled: \(draft)")
    }
}

/// A soft hand-cut silhouette. Native shape keeps rounded edges at every device scale.
struct HandcutKey: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        return Path { p in
            p.move(to: CGPoint(x: w * 0.24, y: h * 0.025))
            p.addCurve(to: CGPoint(x: w * 0.80, y: h * 0.045), control1: CGPoint(x: w * 0.40, y: 0), control2: CGPoint(x: w * 0.64, y: h * 0.015))
            p.addQuadCurve(to: CGPoint(x: w * 0.98, y: h * 0.27), control: CGPoint(x: w, y: h * 0.05))
            p.addCurve(to: CGPoint(x: w * 0.96, y: h * 0.77), control1: CGPoint(x: w, y: h * 0.44), control2: CGPoint(x: w, y: h * 0.61))
            p.addQuadCurve(to: CGPoint(x: w * 0.77, y: h * 0.97), control: CGPoint(x: w * 0.96, y: h))
            p.addCurve(to: CGPoint(x: w * 0.21, y: h * 0.96), control1: CGPoint(x: w * 0.61, y: h), control2: CGPoint(x: w * 0.40, y: h * 0.98))
            p.addQuadCurve(to: CGPoint(x: w * 0.035, y: h * 0.73), control: CGPoint(x: w * 0.02, y: h * 0.96))
            p.addCurve(to: CGPoint(x: w * 0.04, y: h * 0.25), control1: CGPoint(x: 0, y: h * 0.58), control2: CGPoint(x: w * 0.015, y: h * 0.4))
            p.addQuadCurve(to: CGPoint(x: w * 0.24, y: h * 0.025), control: CGPoint(x: w * 0.055, y: h * 0.035))
            p.closeSubpath()
        }
    }
}

/// One shared key for both locks, with real lettering and a 44pt minimum hit area.
struct StoryPlateButton: View {
    let text: String
    let rect: CGRect
    let scale: CGFloat
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                HandcutKey()
                    .fill(IvyType.ink.opacity(0.7))
                    .frame(width: rect.width * scale, height: rect.height * scale)
                    .offset(y: 1.2 * scale)
                HandcutKey()
                    .fill(text == "enter" ? Color(red: 0.80, green: 0.72, blue: 0.45) : IvyType.cream)
                    .overlay(HandcutKey().stroke(IvyType.ink.opacity(0.65), lineWidth: 0.65 * scale))
                    .frame(width: rect.width * scale, height: rect.height * scale)
                Text(text)
                    .font(IvyType.hand((text.count == 1 ? 16 : 10) * scale))
                    .foregroundStyle(IvyType.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 3 * scale)
            }
            .frame(width: max(48, rect.width * scale), height: max(48, rect.height * scale))
            .contentShape(Rectangle())
        }
        .buttonStyle(StoryPressStyle(scale: scale))
        .position(x: rect.midX * scale, y: rect.midY * scale)
        .accessibilityLabel(label)
    }
}

struct StoryPressStyle: ButtonStyle {
    let scale: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.12 : 0)
            .offset(y: configuration.isPressed && !reduceMotion ? scale : 0)
    }
}

extension AssemblePad where Backdrop == EmptyView {
    /// Pad with no scene backdrop. Door and mailbox both start here.
    init(
        glyphs: [String],
        columns: Int,
        draft: String,
        scale: CGFloat,
        shakeX: CGFloat = 0,
        onGlyph: @escaping (String) -> Void,
        onBackspace: @escaping () -> Void,
        onReset: @escaping () -> Void,
        onSubmit: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.init(
            glyphs: glyphs,
            columns: columns,
            draft: draft,
            scale: scale,
            shakeX: shakeX,
            onGlyph: onGlyph,
            onBackspace: onBackspace,
            onReset: onReset,
            onSubmit: onSubmit,
            onCancel: onCancel,
            backdrop: { _ in EmptyView() }
        )
    }
}

/// Nearest-neighbor plate with a 44pt hit around a game-pixel rect.
struct PixelPlateButton: View {
    /// Asset catalog name.
    let imageName: String
    /// Rectangle in game pixels.
    let rect: CGRect
    /// Shared canvas scale.
    let scale: CGFloat
    /// VoiceOver name.
    let label: String
    /// Fire on tap.
    let action: () -> Void

    var body: some View {
        let drawW = rect.width * scale
        let drawH = rect.height * scale
        Button(action: action) {
            Image(imageName)
                .interpolation(.none)
                .resizable()
                .frame(width: drawW, height: drawH)
        }
        .buttonStyle(PixelPressStyle(scale: scale))
        .frame(width: max(44, drawW), height: max(44, drawH))
        .contentShape(Rectangle())
        .position(x: rect.midX * scale, y: rect.midY * scale)
        .accessibilityLabel(label)
    }
}

/// Answer entry shares the painted input; the system keyboard supplies characters.
struct AssembleLockScreen<Clue: View>: View {
    @Bindable var store: GameStore
    @ViewBuilder let clue: Clue
    @State private var isEditing = false

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 190 && !isEditing
            let layout = compact ? AnyLayout(HStackLayout(spacing: 12)) : AnyLayout(VStackLayout(spacing: 8))
            ZStack(alignment: .topLeading) {
                InspectionBackdrop(surface: .puzzle)
                VStack(spacing: 8) {
                    Spacer(minLength: 0)
                    layout {
                        if !isEditing { clue.frame(maxWidth: .infinity) }
                        input.frame(width: isEditing ? min(320, geometry.size.width - 32)
                                                     : compact ? min(240, geometry.size.width * 0.55)
                                                               : min(320, geometry.size.width - 64))
                    }
                    Spacer(minLength: 0)
                    if !isEditing {
                        PuzzleFeedbackText(text: store.assembleHint, tone: store.assembleHintTone)
                            .frame(height: 32)
                    }
                }
                .padding(.horizontal, 24).padding(.vertical, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: store.assembleDraft) { _, _ in
            store.clearAssembleFeedback()
            store.schedulePersist()
        }
        .statusBarHidden(true)
        .gameBackAction(store.cancelOverlay)
    }

    private var input: some View {
        PuzzleInputLine(text: Binding(get: { store.assembleDraft }, set: { store.assembleDraft = $0 }),
                        limit: LockLayout.staveCap,
                        mode: store.assembleKind == .plaque ? .digits : .letters,
                        submit: store.submitAssemble,
                        onFocusChange: { isEditing = $0 })
    }
}

enum PuzzleInputMode: Equatable {
    case letters, phrase, digits

    func filtered(_ value: String, limit: Int) -> String {
        var result = ""
        for character in value.lowercased() {
            let allowed = switch self {
            case .letters: "abcdefghijklmnopqrstuvwxyz".contains(character)
            case .phrase: "abcdefghijklmnopqrstuvwxyz".contains(character) ||
                (character == " " && !result.isEmpty && !result.hasSuffix(" "))
            case .digits: "0123456789".contains(character)
            }
            if allowed { result.append(character) }
            if result.count == limit { break }
        }
        return result
    }
}

struct PuzzleInputLine: View {
    @Binding var text: String
    let limit: Int
    let mode: PuzzleInputMode
    let submit: () -> Void
    var onFocusChange: (Bool) -> Void = { _ in }
    @FocusState private var focused: Bool

    init(text: Binding<String>, limit: Int, mode: PuzzleInputMode,
         submit: @escaping () -> Void, onFocusChange: @escaping (Bool) -> Void = { _ in }) {
        self._text = text
        self.limit = limit
        self.mode = mode
        self.submit = submit
        self.onFocusChange = onFocusChange
    }

    var body: some View {
        GeometryReader { geometry in
            TextField("", text: Binding(get: { text }, set: { text = mode.filtered($0, limit: limit) }),
                      prompt: Text("…"))
                .textFieldStyle(.plain)
                .font(IvyType.script(min(23, max(16, geometry.size.width * 0.1))))
                .foregroundStyle(IvyType.cream)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(mode == .digits ? .numbersAndPunctuation : .asciiCapable)
                .submitLabel(.done)
                .onSubmit {
                    focused = false
                    submit()
                }
                .focused($focused)
                .padding(.horizontal, 20)
                .frame(width: geometry.size.width, height: 48)
                .background {
                    Image("ivy-input-v2").resizable().interpolation(.high)
                        .frame(width: geometry.size.width * 228 / 220, height: 76)
                        .position(x: geometry.size.width / 2, y: 26)
                }
                .accessibilityLabel("Answer")
                .accessibilityValue(text.isEmpty ? "Empty" : text)
                .onChange(of: focused) { _, value in onFocusChange(value) }
                .preference(key: GameTextInputFocusKey.self, value: focused)
        }
        .frame(height: 48)
    }
}
