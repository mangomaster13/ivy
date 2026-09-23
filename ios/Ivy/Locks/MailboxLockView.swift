import SwiftUI

struct MailboxLockView: View {
    @Bindable var store: GameStore
    var body: some View {
        AssembleLockScreen(store: store) {
            Button(action: store.tapPlateIvy) {
                ZStack {
                    IvyType.inscription("the date we\nbecame a story")
                        .font(IvyType.script(23))
                        .foregroundStyle(IvyType.cream)
                        .multilineTextAlignment(.center)
                        .opacity(1 - store.plateIvyOpacity)
                    Image("story-hint-leaves").resizable().scaledToFit()
                        .frame(maxHeight: 74).opacity(store.plateIvyOpacity)
                }.frame(height: 76)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(store.plaqueHintRevealed ? GameCopy.plaqueEngraving : GameCopy.plateIvy)
        }
    }
}
