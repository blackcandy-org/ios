import Foundation
import Dependencies

extension UserDefaultsClient: DependencyKey {
  private static let serverAddressKey = "com.aidewooode.BlackCandy.serverAddressKey"

  static var liveValue: Self {
    return Self(
      serverAddress: {
        UserDefaults.standard.url(forKey: serverAddressKey)
      },

      updateServerAddress: { url in
        UserDefaults.standard.set(url, forKey: serverAddressKey)
      }
    )
  }
}
