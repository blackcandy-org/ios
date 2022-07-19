import SwiftUI
import ComposableArchitecture

struct SessionNewView: View {
  @StateObject var sessionState = SessionState()
  let store: Store<AppState, AppAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      NavigationView {
        Form {
          TextField("label.serverAddress", text: $sessionState.serverAddress)
          TextField("label.email", text: $sessionState.email)
          SecureField("label.password", text: $sessionState.password)
        }
        .navigationTitle("text.loginToBC")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button(action: {
              viewStore.send(.login(sessionState))
            }, label: {
              Text("label.login")
            })
            .disabled(sessionState.hasEmptyField)
          }
        }
      }
      .navigationViewStyle(.stack)
    }
  }
}
