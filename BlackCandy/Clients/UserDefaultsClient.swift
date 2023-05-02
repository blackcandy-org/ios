import Foundation

struct UserDefaultsClient {
  private static let serverAddressKey = "com.aidewooode.BlackCandy.serverAddressKey"

  var serverAddress: () -> URL?
  var updateServerAddress: (URL?) -> Void
}

extension UserDefaultsClient {
  static var live: Self {
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
