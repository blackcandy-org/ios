import Foundation
import UIKit

class ServerAddressState: ObservableObject, Equatable {
  @Published var url = ""

  var hasEmptyField: Bool {
    url.isEmpty
  }

  var isUrlValid: Bool {
    if let serverUrl = URL(string: url) {
      // Add http scheme to serverAddress if it dosen't have
      if !["http", "https"].contains(serverUrl.scheme) {
        url = "http://" + url
      }

      return UIApplication.shared.canOpenURL(URL(string: url)!)
    }

    return false
  }

  static func == (lhs: ServerAddressState, rhs: ServerAddressState) -> Bool {
    lhs.url == rhs.url
  }
}
