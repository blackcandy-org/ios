import Foundation
import Dependencies

extension UserDefaultsClient: DependencyKey {
  static func live() -> Self {
    let serverAddressKey = "com.aidewooode.BlackCandy.serverAddressKey"

    return Self(
      serverAddress: {
        UserDefaults.standard.url(forKey: serverAddressKey)
      },

      updateServerAddress: { url in
        UserDefaults.standard.set(url, forKey: serverAddressKey)
      }
    )
  }

  static var liveValue = live()
}
