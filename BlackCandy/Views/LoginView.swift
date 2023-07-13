import SwiftUI
import ComposableArchitecture

struct LoginView: View {
  let store: StoreOf<AppReducer>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      NavigationView {
        VStack {
          LoginConnectionView(store: store)

          NavigationLink(
            destination: LoginAuthenticationView(store: store),
            isActive: viewStore.binding(
              get: { $0.isLoginViewVisible },
              send: { .updateLoginViewVisible($0) }
            ),
            label: { EmptyView() }
          )
          .hidden()
        }
      }
      .navigationViewStyle(.stack)
    }
  }
}
