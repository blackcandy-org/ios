import Foundation
import UIKit

class ServerAddressState: ObservableObject, Equatable {
  @Published var url = ""

  var hasEmptyField: Bool {
    url.isEmpty
  }

  func validateUrl() -> Bool {
    let schemeRegex = try! NSRegularExpression(pattern: "^https?://.*", options: .caseInsensitive)
    let hasScheme = schemeRegex.firstMatch(in: url, range: .init(location: 0, length: url.utf16.count)) != nil

    if !hasScheme {
      url = "http://" + url
    }

    guard let serverUrl = URL(string: url) else { return false }

    return UIApplication.shared.canOpenURL(serverUrl)
  }

  static func == (lhs: ServerAddressState, rhs: ServerAddressState) -> Bool {
    lhs.url == rhs.url
  }
}
