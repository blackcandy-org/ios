import Foundation
import Dependencies

extension UserDefaultsClient: DependencyKey {
  private static let serverAddressKey = "com.aidewooode.BlackCandy.serverAddressKey"

  static var liveValue: Self {
    var serverAddress = UserDefaults.standard.url(forKey: serverAddressKey) {
      didSet {
        UserDefaults.standard.set(serverAddress, forKey: serverAddressKey)
      }
    }

    return Self(
      serverAddress: {
        serverAddress
      },

      updateServerAddress: { url in
        serverAddress = url
      }
    )
  }
}
