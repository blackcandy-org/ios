import SwiftUI
import ComposableArchitecture

struct LoginConnectionView: View {
  @Dependency(\.userDefaultsClient) var userDefaultsClient
  @StateObject var serverAddressState = ServerAddressState()

  let store: StoreOf<LoginReducer>

  var body: some View {
    Form {
      Section(content: {
        TextField("label.serverAddress", text: $serverAddressState.url)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled(true)
          .keyboardType(.URL)
      }, header: {
        Image("BlackCandyLogo")
          .frame(maxWidth: .infinity)
          .padding(.bottom)
      })

      Button(action: {
        store.send(.getSystemInfo(serverAddressState))
      }, label: {
        Text("label.connect")
      })
      .frame(maxWidth: .infinity)
      .disabled(serverAddressState.hasEmptyField)
    }
    .navigationTitle("text.connectToBC")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      serverAddressState.url = userDefaultsClient.serverAddress()?.absoluteString ?? ""
    }
  }
}

struct LoginConnectionView_Previews: PreviewProvider {
  static var previews: some View {
    LoginConnectionView(
      store: Store(initialState: LoginReducer.State()) {}
    )
  }
}
