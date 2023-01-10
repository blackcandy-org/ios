import Foundation

class LoginState: ObservableObject, Equatable {
  @Published var email = ""
  @Published var password = ""

  var hasEmptyField: Bool {
    email.isEmpty || password.isEmpty
  }

  static func == (lhs: LoginState, rhs: LoginState) -> Bool {
    lhs.email == rhs.email && lhs.password == rhs.password
  }
}
