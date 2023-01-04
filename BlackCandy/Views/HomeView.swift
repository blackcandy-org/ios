import SwiftUI
import ComposableArchitecture

struct HomeView: View {
  let store: StoreOf<AppReducer>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      if !viewStore.isLoggedIn {
        LoginView(store: store)
      } else {
        SplitView(store: store.scope(
          state: \.player,
          action: AppReducer.Action.player
        ))
        .ignoresSafeArea(edges: .vertical)
        .sheet(isPresented: viewStore.binding(
          get: { $0.isAccountSheetVisible },
          send: { .updateAccountSheetVisible($0) }
        ), content: {
          AccountView(store: store)
        })
        .onAppear {
          viewStore.send(.player(.getCurrentPlaylist))
        }
        .preferredColorScheme(viewStore.currentTheme.colorScheme)
      }
    }
  }
}
