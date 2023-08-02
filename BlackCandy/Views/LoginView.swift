import SwiftUI
import ComposableArchitecture

struct LoginView: View {
  let store: StoreOf<LoginReducer>

  struct ViewState: Equatable {
    @BindingViewState var isAuthenticationViewVisible: Bool

    init(store: BindingViewStore<LoginReducer.State>) {
      self._isAuthenticationViewVisible = store.$isAuthenticationViewVisible
    }
  }

  var body: some View {
    WithViewStore(self.store, observe: ViewState.init) { viewStore in
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

struct LoginView_Previews: PreviewProvider {
  static var previews: some View {
    let systemInfoResponse = SystemInfo(
      version: .init(major: 3, minor: 0, patch: 0, pre: ""),
      serverAddress: URL(string: "http://localhost:3000")
    )

    let store = withDependencies {
      $0.apiClient.getSystemInfo = { _ in
        systemInfoResponse
      }
    } operation: {
      Store(initialState: LoginReducer.State()) {
        LoginReducer()
      }
    }

    LoginView(store: store)
  }
}
