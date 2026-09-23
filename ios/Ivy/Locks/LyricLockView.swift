import SwiftUI

struct LyricLockView: View {
    @Bindable var store: GameStore
    var body: some View {
        AssembleLockScreen(store: store) {
            IvyType.inscription(GameCopy.doorInscription)
                .font(IvyType.script(23))
                .foregroundStyle(IvyType.cream)
                .multilineTextAlignment(.center)
                .padding(.vertical, 4)
        }
    }
}
