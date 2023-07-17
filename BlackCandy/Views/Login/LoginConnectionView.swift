import SwiftUI
import ComposableArchitecture

struct LoginConnectionView: View {
  @StateObject var serverAddressState = ServerAddressState()
  let store: StoreOf<AppReducer>

  var body: some View {
    WithViewStore(self.store) { viewStore in
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
          viewStore.send(.getSystemInfo(serverAddressState))
        }, label: {
          Text("label.connect")
        })
        .frame(maxWidth: .infinity)
        .disabled(serverAddressState.hasEmptyField)
      }
      .navigationTitle("text.connectToBC")
      .navigationBarTitleDisplayMode(.inline)
      .onAppear {
        serverAddressState.url = viewStore.serverAddress?.absoluteString ?? ""
      }
    }
  }
}
