import SwiftUI

struct LaterMemoryView: View {
    @Bindable var store: GameStore
    let panel: MemoryPanel
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
        default: EmptyView()
        }
    }
}
