import SwiftUI
import ComposableArchitecture
import Turbo

struct LoginView: View {
  @StateObject var loginState = LoginState()
  let store: StoreOf<AppReducer>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      NavigationView {
        Form {
          Section(content: {
            TextField("label.serverAddress", text: $loginState.serverAddress)
              .textInputAutocapitalization(.never)

            TextField("label.email", text: $loginState.email)
              .textInputAutocapitalization(.never)

            SecureField("label.password", text: $loginState.password)

          }, header: {
            Image("BlackCandyLogo")
              .frame(maxWidth: .infinity)
              .padding(.bottom)
          })

          Button(action: {
            viewStore.send(.login(loginState))
          }, label: {
            Text("label.login")
          })
          .frame(maxWidth: .infinity)
          .disabled(loginState.hasEmptyField)
        }
        .navigationTitle("text.loginToBC")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
          loginState.serverAddress = viewStore.serverAddress?.absoluteString ?? ""
        }
      }
      .navigationViewStyle(.stack)
    }
  }
}
