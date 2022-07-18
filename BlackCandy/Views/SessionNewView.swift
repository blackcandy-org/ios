import SwiftUI

struct SessionNewView: View {
  @State var serverAddress = ""
  @State var email = ""
  @State var password = ""

  var body: some View {
    NavigationView {
      Form {
        TextField("Server Address", text: $serverAddress)
        TextField("User Email", text: $email)
        SecureField("Password", text: $password)
      }
      .navigationTitle("Login to Black Candy")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(action: {
          }, label: {
            Text("Login")
          })
        }
      }
    }
    .navigationViewStyle(.stack)
  }
}
