import SwiftUI

/// The promenade, booth, gate and cabin each use the same 320 × 160 canvas.
enum FerrisLayout {
    // The earbud wire connects both people to the iPod held by the yellow-shirt man.
    static let earphones = CGRect(x: 85, y: 76, width: 60, height: 42)
    // Booth front: the ticket emerges directly below the brass-edged physical slot.
    static let dispenser = CGRect(x: 125, y: 112, width: 17, height: 16)
    static let ticket = CGRect(x: 126, y: 117, width: 15, height: 10)
    static let boothQueue = CGRect(x: 216, y: 70, width: 83, height: 67)
    // Boarding plate: waist-high slot and carriage door are separate surfaces.
    static let gate = CGRect(x: 132, y: 94, width: 18, height: 20)
    static let door = CGRect(x: 226, y: 43, width: 35, height: 77)
    // Cabin right cushion: both removable objects share one support surface.
    static let phone = CGRect(x: 247, y: 129, width: 25, height: 15)
    static let photo = CGRect(x: 246, y: 121, width: 28, height: 28)
    static let promenadeSpots: [ExplorationSpot] = [
        .init("Shared earphones", earphones.minX, earphones.minY, earphones.width, earphones.height, .memory(.ferris))
    ]
    static let boothSpots: [ExplorationSpot] = [
        .init("Ticket dispenser", dispenser.minX, dispenser.minY, dispenser.width, dispenser.height, .memory(.ferrisTicket)),
        .init("Carriage queue", boothQueue.minX, boothQueue.minY, boothQueue.width, boothQueue.height, .memory(.ferrisGate))
    ]
}

struct FerrisWorld: View {
    @Bindable var store: GameStore
    let scale: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            if store.sceneView == 1 && store.ferris.playlistSolved && !store.ferris.ticketTaken {
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
                InspectionBackdrop(surface: .defocusedScene("ferris-promenade"))
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
                    if !store.ferris.playlistSolved {
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
        SceneDetailStage(bounds: CGRect(x: 116, y: 103, width: 40, height: 31)) {
            GeometryReader { geometry in
                let scale = geometry.size.width / 320
                Image("ferris-ticket-booth").resizable().accessibilityHidden(true)
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
                Image(store.ferris.ticketUsed ? "ferris-boarding-open" : "ferris-boarding-closed")
                    .resizable().accessibilityHidden(true)
                if store.ferris.ticketUsed {
                    target(FerrisLayout.door, scale: scale, label: "Enter the carriage", action: store.enterFerrisCabin)
                } else {
                    target(FerrisLayout.door, scale: scale, label: "Closed carriage door") {
                        store.showSceneHint("The gate hasn't let us through yet.", presentation: .interaction)
                    }
                    target(FerrisLayout.gate, scale: scale, label: "Use your ticket in the gate", accepting: [.ferrisTicket]) {
                        if store.ferris.ticketTaken { store.useFerrisTicket() }
                        else { store.hintForTool(.ferrisTicket) }
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
                        .frame(width: FerrisLayout.photo.width * scale, height: FerrisLayout.photo.height * scale)
                        .rotationEffect(.degrees(-6))
                        .position(x: FerrisLayout.photo.midX * scale, y: FerrisLayout.photo.midY * scale)
                        .accessibilityHidden(true)
                    target(FerrisLayout.photo, scale: scale,
                           label: "Remember our selfie") { store.replayKeepsake(.ferris) }
                } else {
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
                Button { if store.ferris.photoTaken { store.replayKeepsake(.ferris) } } label: {
                    Image("ferris-selfie").resizable().interpolation(.high).scaledToFit()
                        .frame(width: available.width, height: geometry.size.height - 16)
                }
                    .buttonStyle(.plain)
                    .disabled(!store.ferris.photoTaken)
                    .position(x: available.midX, y: geometry.size.height / 2)
                    .accessibilityLabel(store.ferris.photoTaken ? "Remember our selfie" : "Both of us, with the harbour behind us")
            }
            PuzzleActionRail {
                if !store.ferris.photoTaken {
                    PuzzleButton("Photo", width: PuzzleActionLayout.width, action: store.takeFerrisSelfie)
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
