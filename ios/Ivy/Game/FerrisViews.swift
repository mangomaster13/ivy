import SwiftUI

/// All world objects use the existing 320 × 160 booth canvas and its support surfaces.
enum FerrisLayout {
    static let ipod = CGRect(x: 161, y: 81, width: 16, height: 25)
    static let dispenser = CGRect(x: 186, y: 109, width: 29, height: 14)
    static let ticket = CGRect(x: 189, y: 116, width: 23, height: 12)
    static let gate = CGRect(x: 112, y: 86, width: 28, height: 14)
    static let door = CGRect(x: 182, y: 45, width: 48, height: 83)
    static let phone = CGRect(x: 203, y: 113, width: 23, height: 14)
    static let spots: [ExplorationSpot] = [
        .init("Classic iPod", ipod.minX, ipod.minY, ipod.width, ipod.height, .memory(.ferris)),
        .init("Ticket dispenser", dispenser.minX, dispenser.minY, dispenser.width, 22, .memory(.ferrisTicket)),
        .init("Carriage entrance", 236, 85, 27, 46, .memory(.ferrisGate))
    ]
}

struct FerrisWorld: View {
    @Bindable var store: GameStore
    let scale: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            object("ferris-classic-ipod", rect: FerrisLayout.ipod)
            object("ferris-dispenser", rect: FerrisLayout.dispenser)
            if store.ferris.playlistSolved && !store.ferris.ticketTaken {
                object("ferris-ride-ticket", rect: FerrisLayout.ticket)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }

    private func object(_ name: String, rect: CGRect) -> some View {
        Image(name).resizable().interpolation(.high).scaledToFit()
            .frame(width: rect.width * scale, height: rect.height * scale)
            .position(x: rect.midX * scale, y: rect.midY * scale)
    }
}

struct FerrisCloseupView: View {
    @Bindable var store: GameStore
    let panel: MemoryPanel
    @State private var selectedSong: Int?
    @State private var draggingSong: Int?
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        Group {
            switch panel {
            case .ferrisTicket: ticket
            case .ferrisGate: gate
            case .ferrisCabin: cabin
            case .ferrisCamera: camera
            default: playlist
            }
        }
        .overlay {
            if !store.sceneHint.isEmpty {
                ZStack(alignment: .bottom) {
                    Color.clear.contentShape(Rectangle()).onTapGesture { store.dismissSceneHint() }
                        .accessibilityHidden(true)
                    DialogueBox(line: store.sceneHint, tone: store.sceneHintTone, onDismiss: store.dismissSceneHint)
                        .padding(.horizontal, 24).padding(.bottom, 12)
                }
            }
        }
        .gameBackAction(store.backFromMemory)
        .onDisappear {
            draggingSong = nil
            selectedSong = nil
            store.persistNow()
        }
    }

    private var playlist: some View {
        GeometryReader { geometry in
            let size = geometry.size
            // The camera crops the iPod's LCD bezel, not the song list. Five 48pt rows
            // need 240pt height; the supported 533×266 minimum content fits without scrolling.
            let screenHeight = min(280, max(240, size.height - 20))
            let screenWidth = min(380, size.width - 124)
            let origin = CGPoint(x: (size.width - 100 - screenWidth) / 2,
                                 y: (size.height - screenHeight) / 2)
            ZStack(alignment: .topLeading) {
                InspectionBackdrop(surface: .defocusedScene("later-ferris-exterior-background"))
                // Screen and text share one authored surface; the source crop includes ivory bezel.
                Image("ferris-ipod-screen").resizable().interpolation(.high)
                    .frame(width: screenWidth + 16, height: screenHeight + 16)
                    .position(x: origin.x + screenWidth / 2, y: origin.y + screenHeight / 2)
                    .accessibilityHidden(true)
                VStack(spacing: 0) {
                    ForEach(Array(store.ferris.order.enumerated()), id: \.element) { index, song in
                        songRow(song, index: index, height: screenHeight / 5, width: screenWidth)
                    }
                }
                .frame(width: screenWidth, height: screenHeight)
                .position(x: origin.x + screenWidth / 2, y: origin.y + screenHeight / 2)
                PuzzleActionRail {
                    if store.ferris.playlistSolved {
                        PuzzleButton("Ticket", width: PuzzleActionLayout.width) { store.openMemory(.ferrisTicket) }
                    } else {
                        if let song = selectedSong, let index = store.ferris.order.firstIndex(of: song) {
                            PuzzleButton("Up", width: PuzzleActionLayout.width) { store.moveFerrisSong(song, to: index - 1) }
                                .disabled(index == 0)
                            PuzzleButton("Down", width: PuzzleActionLayout.width) { store.moveFerrisSong(song, to: index + 1) }
                                .disabled(index == 4)
                        }
                        PuzzleButton("Play", width: PuzzleActionLayout.width, action: store.submitFerrisPlaylist)
                    }
                }
            }
        }
    }

    private func songRow(_ song: Int, index: Int, height: CGFloat, width: CGFloat) -> some View {
        Image("ferris-track-\(song)").resizable().interpolation(.high).scaledToFit()
            .frame(width: width - 16, height: 44, alignment: .leading)
            .frame(width: width, height: height)
            .background(selectedSong == song ? IvyType.cream.opacity(0.16) : .clear)
            .contentShape(Rectangle())
            .offset(y: draggingSong == song ? dragOffset : 0)
            .zIndex(draggingSong == song ? 1 : 0)
            .onTapGesture { if !store.ferris.playlistSolved { selectedSong = song } }
            .gesture(DragGesture(minimumDistance: 8)
                .onChanged { value in
                    guard !store.ferris.playlistSolved else { return }
                    draggingSong = song
                    selectedSong = song
                    dragOffset = value.translation.height
                }
                .onEnded { value in
                    guard !store.ferris.playlistSolved else { return }
                    let destination = min(4, max(0, index + Int((value.translation.height / height).rounded())))
                    draggingSong = nil
                    dragOffset = 0
                    store.moveFerrisSong(song, to: destination)
                })
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(FerrisProgress.songs[song])
            .accessibilityValue("Position \(index + 1) of 5")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { selectedSong = song }
            .accessibilityAction(named: "Move up") { store.moveFerrisSong(song, to: index - 1) }
            .accessibilityAction(named: "Move down") { store.moveFerrisSong(song, to: index + 1) }
    }

    private var ticket: some View {
        SceneDetailStage(bounds: CGRect(x: 181, y: 105, width: 39, height: 27)) {
            GeometryReader { geometry in
                let scale = geometry.size.width / 320
                Image("later-ferris-exterior-background").resizable().accessibilityHidden(true)
                FerrisWorld(store: store, scale: scale)
                if !store.ferris.ticketTaken {
                    target(FerrisLayout.ticket, scale: scale, label: "Take the Ferris wheel ticket", action: store.takeFerrisTicket)
                }
            }
        }
    }

    private var gate: some View {
        FittedSceneStage {
            GeometryReader { geometry in
                let scale = geometry.size.width / 320
                Image(store.ferris.ticketUsed ? "later-ferris-cabin-open" : "later-ferris-cabin-closed")
                    .resizable().accessibilityHidden(true)
                Image("ferris-dispenser").resizable().scaledToFit()
                    .frame(width: FerrisLayout.gate.width * scale, height: FerrisLayout.gate.height * scale)
                    .position(x: FerrisLayout.gate.midX * scale, y: FerrisLayout.gate.midY * scale)
                    .accessibilityHidden(true)
                if store.ferris.ticketUsed {
                    target(FerrisLayout.door, scale: scale, label: "Enter the carriage", action: store.enterFerrisCabin)
                } else {
                    target(FerrisLayout.door, scale: scale, label: "Closed carriage door") {
                        store.showSceneHint("The gate is waiting for a ticket.", presentation: .interaction)
                    }
                    target(FerrisLayout.gate, scale: scale, label: "Use your ticket in the gate", accepting: [.ferrisTicket]) {
                        if store.ferris.ticketTaken { store.useFerrisTicket() }
                        else { store.showSceneHint("The gate is waiting for a ticket.", presentation: .interaction) }
                    }
                }
            }
        }
    }

    private var cabin: some View {
        FittedSceneStage {
            GeometryReader { geometry in
                let scale = geometry.size.width / 320
                Image("ferris-cabin-interior").resizable().accessibilityHidden(true)
                if !store.ferris.phoneTaken {
                    Image("ferris-selfie-phone").resizable().scaledToFit()
                        .frame(width: 11 * scale, height: 21 * scale)
                        .rotationEffect(.degrees(76))
                        .position(x: FerrisLayout.phone.midX * scale, y: FerrisLayout.phone.midY * scale)
                        .accessibilityHidden(true)
                    target(FerrisLayout.phone, scale: scale, label: "Take the phone from the seat", action: store.takeFerrisPhone)
                }
                if store.ferris.photoTaken {
                    Image("ferris-selfie").resizable().scaledToFit()
                        .frame(width: 27 * scale, height: 27 * scale)
                        .rotationEffect(.degrees(-6))
                        .position(x: FerrisLayout.phone.midX * scale, y: 113 * scale)
                        .accessibilityHidden(true)
                    target(CGRect(x: 200, y: 99, width: 29, height: 29), scale: scale,
                           label: "Remember our selfie") { store.replayKeepsake(.ferris) }
                } else if store.ferris.phoneTaken {
                    target(CGRect(x: 86, y: 22, width: 148, height: 57), scale: scale,
                           label: "Take a selfie by the window", accepting: [.ferrisPhone], action: store.openFerrisCamera)
                }
            }
        }
    }

    private var camera: some View {
        ZStack {
            InspectionBackdrop(surface: .defocusedScene("ferris-cabin-interior"))
            GeometryReader { geometry in
                let available = PuzzleActionLayout.interactionRect(in: geometry.size)
                Image("ferris-selfie").resizable().interpolation(.high).scaledToFit()
                    .frame(width: available.width, height: geometry.size.height - 16)
                    .position(x: available.midX, y: geometry.size.height / 2)
                    .accessibilityLabel("Both of us, with the harbour behind us")
            }
            PuzzleActionRail {
                if store.ferris.photoTaken {
                    PuzzleButton("Remember", width: PuzzleActionLayout.width) { store.replayKeepsake(.ferris) }
                } else {
                    PuzzleButton("Photo", width: PuzzleActionLayout.width, action: store.takeFerrisSelfie)
                        .disabled(store.selectedTool != .ferrisPhone)
                        .accessibilityLabel("Shutter: take our selfie")
                }
            }
        }
    }

    private func target(_ rect: CGRect, scale: CGFloat, label: String, accepting: [AdventureTool] = [],
                        action: @escaping () -> Void) -> some View {
        Button(action: action) { Color.clear.contentShape(Rectangle()) }
            .buttonStyle(.plain)
            .frame(width: max(48, rect.width * scale), height: max(48, rect.height * scale))
            .inventoryToolDrop(store: store, accepting: accepting) { _ in action() }
            .position(x: rect.midX * scale, y: rect.midY * scale)
            .accessibilityLabel(label)
    }
}
