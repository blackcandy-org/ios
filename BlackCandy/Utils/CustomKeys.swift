import SwiftUI

private struct ServerAddressKey: EnvironmentKey {
  static let defaultValue: URL? = nil
}

extension EnvironmentValues {
  var serverAddress: URL? {
    get { self[ServerAddressKey.self] }
    set { self[ServerAddressKey.self] = newValue }
  }
}
