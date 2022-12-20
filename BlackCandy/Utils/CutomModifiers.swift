import SwiftUI
import ComposableArchitecture
import LNPopupUI

struct PlayerModifier: ViewModifier {
  let store: StoreOf<AppReducer>
  @State var isPlayerPresented = true

  func body(content: Content) -> some View {
    content
      .popup(isBarPresented: $isPlayerPresented, popupContent: {
        PlayerView(store: self.store.scope(
          state: \.player,
          action: AppReducer.Action.player
        ))
      })
      .popupBarCustomView(popupBarContent: {
        MiniPlayerView(store: self.store.scope(
          state: \.player,
          action: AppReducer.Action.player
        ))
      })
  }
}

extension View {
  func player(with store: StoreOf<AppReducer>) -> some View {
    modifier(PlayerModifier(store: store))
  }
}
