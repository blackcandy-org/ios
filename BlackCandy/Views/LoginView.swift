import SwiftUI
import ComposableArchitecture
import Turbo

struct LoginView: View {
  @StateObject var loginState = LoginState()
  let store: Store<AppState, AppAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      NavigationView {
        Form {
          TextField("label.serverAddress", text: $loginState.serverAddress)
            .textInputAutocapitalization(.never)

          TextField("label.email", text: $loginState.email)
            .textInputAutocapitalization(.never)

          SecureField("label.password", text: $loginState.password)
        }
        .navigationTitle("text.loginToBC")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button(action: {
              viewStore.send(.login(loginState))
            }, label: {
              Text("label.login")
            })
            .disabled(loginState.hasEmptyField)
          }
        }
        .onAppear {
          loginState.serverAddress = viewStore.serverAddress?.absoluteString ?? ""
        }
      }
      .navigationViewStyle(.stack)
    }
  }
}
