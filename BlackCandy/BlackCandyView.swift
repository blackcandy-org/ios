import SwiftUI
import ComposableArchitecture

struct BlackCandyView: View {
  @Environment(\.scenePhase) private var scenePhase
  let store: Store<AppState, AppAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      HomeView(store: store)
        .onChange(of: scenePhase) { phase in
          switch phase {
          case .active:
            viewStore.send(.restoreUserDefaults)
          case .background, .inactive:
            return
          @unknown default:
            return
          }
        }
        .alert(self.store.scope(state: \.alert), dismiss: .dismissAlert)
    }
  }
}
