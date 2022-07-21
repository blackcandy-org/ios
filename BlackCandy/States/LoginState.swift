import Foundation
import UIKit

class LoginState: ObservableObject, Equatable {
  @Published var serverAddress = ""
  @Published var email = ""
  @Published var password = ""

  var hasEmptyField: Bool {
    serverAddress.isEmpty ||
    email.isEmpty ||
    password.isEmpty
  }

  var hasValidServerAddress: Bool {
    if let url = URL(string: serverAddress) {
      // Add http scheme to serverAddress if it dosen't have
      if !["http", "https"].contains(url.scheme) {
        serverAddress = "http://" + serverAddress
      }

      return UIApplication.shared.canOpenURL(URL(string: serverAddress)!)
    }

    return false
  }

  static func == (lhs: LoginState, rhs: LoginState) -> Bool {
    lhs.serverAddress == rhs.serverAddress &&
    lhs.email == rhs.email &&
    lhs.password == rhs.password
  }
}
