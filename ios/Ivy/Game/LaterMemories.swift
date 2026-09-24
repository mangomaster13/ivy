import SwiftUI

struct LaterMemoryView: View {
    @Bindable var store: GameStore
    let panel: MemoryPanel
    @State private var firstScent: Int?
    @State private var receipt = false
    @State private var editingAnswer = false
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
        case .cinema: CinemaCloseupView(store: store, panel: .cinema)
        case .ferris: FerrisCloseupView(store: store, panel: .ferris)
        case .taxi:
            if solved { reward(.taxi, "take the printed receipt") }
            else {
                VStack(spacing: 12) {
                    if !editingAnswer {
                        VStack(spacing: 18) {
                            IvyType.inscription("don't go just yet").font(IvyType.script(30))
                            Text("One word.\nThe opposite of leave.").multilineTextAlignment(.center)
                        }.frame(maxWidth: 250)
                    }
                    WordAnswer(text: $store.memories.taxiDraft, limit: 4,
                               feedbackStore: store, submit: { store.solveLater(.taxi) },
                               onFocusChange: { editingAnswer = $0 })
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
