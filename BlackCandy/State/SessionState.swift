import Foundation

class SessionState: ObservableObject, Equatable {
  static let serverAddressRegex = "((?:http|https)://)?(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?"

  @Published var serverAddress = ""
  @Published var email = ""
  @Published var password = ""

  var hasEmptyField: Bool {
    serverAddress.isEmpty ||
    email.isEmpty ||
    password.isEmpty
  }

  var hasValidServerAddress: Bool {
    let predicate = NSPredicate(format: "SELF MATCHES %@", argumentArray: [Self.serverAddressRegex])
    return predicate.evaluate(with: serverAddress)
  }

  static func == (lhs: SessionState, rhs: SessionState) -> Bool {
    lhs.serverAddress == rhs.serverAddress &&
    lhs.email == rhs.email &&
    lhs.password == rhs.password
  }
}
