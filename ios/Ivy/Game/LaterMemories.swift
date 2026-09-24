import SwiftUI

struct LaterMemoryView: View {
    @Bindable var store: GameStore
    let panel: MemoryPanel
    @State private var firstScent: Int?
    @State private var ferryTicket: Int?
    @State private var receipt = false
    private var solved: Bool { store.memories.opened.contains(panel.rawValue) }
    var body: some View {
        VStack(spacing: 18) {
            content
        }.font(IvyType.hand(22)).frame(maxWidth: 760)
    }
    @ViewBuilder private var content: some View {
        switch panel {
        case .bigTop: BigTopCloseupView(store: store, panel: .bigTop)
        case .mexican:
            VStack(spacing: 18) {
                Text("OUR FIRST DINNER").font(IvyType.hand(30))
                Text("Mexican food").multilineTextAlignment(.center)
                Divider()
                Text("Bad dinner. Great company.").font(.system(size: 21)).multilineTextAlignment(.center)
            }.foregroundStyle(IvyType.ink).padding(30).background(IvyType.cream, in: RoundedRectangle(cornerRadius: 8))
        case .perfume: PerfumeCloseupView(store: store, panel: .perfume)
        case .cinema:
            if solved {
                HStack(spacing: 0) {
                    Image(systemName: "hand.point.right.fill").font(.system(size: 54))
                    Image(systemName: "hand.point.left.fill").font(.system(size: 54))
                }.foregroundStyle(IvyType.cream).transition(.scale.combined(with: .opacity))
                Text(EggId.cinema.memoryLine).font(.system(size: 21)).multilineTextAlignment(.center)
                reward(.cinema, "take our two tickets")
            } else {
                HStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Text("On the poster: H O P E\nOur tickets: C3 + C4").font(IvyType.hand(22)).multilineTextAlignment(.center)
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(52)), count: 3), spacing: 8) {
                            ForEach(0..<6) { i in
                                Button {
                                    if store.memories.cinemaSeats.contains(i) { store.memories.cinemaSeats.remove(i) }
                                    else if store.memories.cinemaSeats.count < 2 { store.memories.cinemaSeats.insert(i) }
                                    store.persistNow()
                                } label: {
                                    Text("C\(i+1)").font(IvyType.hand(21)).foregroundStyle(IvyType.ink)
                                        .frame(width: 52, height: 48)
                                        .background(HandcutKey().fill(store.memories.cinemaSeats.contains(i) ? Color.orange : IvyType.cream))
                                }
                            }
                        }
                    }.frame(maxWidth: 230)
                    WordAnswer(text: $store.memories.cinemaDraft, placeholder: "the film on our tickets", glyphs: "pheomslart", limit: 4, feedbackStore: store) { store.solveLater(.cinema) }
                        .onChange(of: store.memories.cinemaDraft) { _, _ in store.persistNow() }
                }

            }
        case .ferris:
            Text("☾ · leaf").multilineTextAlignment(.center)
            if solved {
                Image(systemName: "ferriswheel").font(.system(size: 80)).foregroundStyle(IvyType.cream)
                reward(.ferris, "take the ride keepsake")
            } else {
                HStack(spacing: 24) {
                    ForEach(0..<2) { i in
                        if !store.memories.ferrisMatches.contains(i) {
                            Button(i == 0 ? "☾ ticket" : "leaf ticket") { ferryTicket = i }
                                .padding(12).background(IvyType.cream.opacity(ferryTicket == i ? 0.3 : 0.1), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                HStack(spacing: 18) {
                    ForEach(0..<3) { carriage in
                        Button(["☾ + leaf", "star + drop", "leaf + star"][carriage]) {
                            guard let ticket = ferryTicket else { IvyHaptics.light(); return }
                            guard carriage == 0 else { store.showSceneHint("The marks don't match.", tone: .wrong); return }
                            store.memories.ferrisMatches.insert(ticket); ferryTicket = nil; store.persistNow()
                        }.frame(minHeight: 60).padding(.horizontal, 12).background(IvyType.cream.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                Button("open the carriage") { store.solveLater(.ferris) }.frame(minHeight: 44)
            }
        case .taxi:
            if solved { reward(.taxi, "take the printed receipt") }
            else {
                HStack(spacing: 24) {
                    VStack(spacing: 18) {
                        IvyType.inscription("don't go just yet").font(IvyType.script(30))
                        Text("One word.\nThe opposite of leave.").multilineTextAlignment(.center)
                    }.frame(maxWidth: 250)
                    WordAnswer(text: $store.memories.taxiDraft, placeholder: "tell the meter", glyphs: "tysavelorn", limit: 4, feedbackStore: store) { store.solveLater(.taxi) }
                        .onChange(of: store.memories.taxiDraft) { _, _ in store.persistNow() }
                }

            }
        default: EmptyView()
        }
    }
    private func reward(_ egg: EggId, _ label: String) -> some View {
        Button { store.collectPhysical(egg) } label: {
            VStack(spacing: 8) {
                Image(egg.collectionImageName).resizable().interpolation(.high).scaledToFit().frame(height: 125)
            }
        }.buttonStyle(.plain).disabled(store.collected.contains(egg)).accessibilityLabel(label)
    }
}
