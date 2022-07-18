import SwiftUI

private struct ServerAddressKey: EnvironmentKey {
  static let defaultValue: String = "http://localhost:3000"
}

extension EnvironmentValues {
  var serverAddress: String {
    get { self[ServerAddressKey.self] }
    set { self[ServerAddressKey.self] = newValue }
  }
}
