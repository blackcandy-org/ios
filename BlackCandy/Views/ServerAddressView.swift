import SwiftUI
import ComposableArchitecture

struct ServerAddressView: View {
  @StateObject var serverAddressState = ServerAddressState()
  let store: StoreOf<AppReducer>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      NavigationView {
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
        .toolbar(content: {
          // Beacuse hidden NavigationLink always have empty space in Form,
          // So add hidden NavigationLink in toolbar to avoid it.
          NavigationLink(
            destination: LoginView(store: store),
            isActive: viewStore.binding(
              get: { $0.isLoginViewVisible },
              send: { .updateLoginViewVisible($0) }
            ),
            label: { EmptyView() }
          )
          .hidden()
        })
        .onAppear {
          serverAddressState.url = viewStore.serverAddress?.absoluteString ?? ""
        }
      }
      .navigationViewStyle(.stack)
    }
  }
}
