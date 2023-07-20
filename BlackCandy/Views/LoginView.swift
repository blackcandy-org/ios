import SwiftUI
import ComposableArchitecture

struct LoginView: View {
  let store: StoreOf<LoginReducer>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      NavigationView {
        VStack {
          LoginConnectionView(store: store)

          NavigationLink(
            destination: LoginAuthenticationView(store: store),
            isActive: viewStore.$isAuthenticationViewVisible,
            label: { EmptyView() }
          )
          .hidden()
        }
      }
      .navigationViewStyle(.stack)
    }
  }
}
