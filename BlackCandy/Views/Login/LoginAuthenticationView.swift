import SwiftUI
import ComposableArchitecture

struct LoginAuthenticationView: View {
  @StateObject var loginState = LoginState()
  let store: StoreOf<LoginReducer>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      Form {
        Section {
          TextField("label.email", text: $loginState.email)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .keyboardType(.emailAddress)

          SecureField("label.password", text: $loginState.password)
        }

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
    }
  }
}
