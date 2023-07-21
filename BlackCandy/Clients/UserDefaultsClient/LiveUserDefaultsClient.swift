import Foundation
import Dependencies

extension UserDefaultsClient: DependencyKey {
  static func live(serverAddressKey: String) -> Self {
    return Self(
      serverAddress: {
        UserDefaults.standard.url(forKey: serverAddressKey)
      },

      updateServerAddress: { url in
        UserDefaults.standard.set(url, forKey: serverAddressKey)
      }
    )
  }

  static var liveValue = live(serverAddressKey: "com.aidewooode.BlackCandy.serverAddressKey")
}
