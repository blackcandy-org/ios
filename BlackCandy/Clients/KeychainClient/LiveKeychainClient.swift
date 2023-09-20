import Foundation
import Dependencies

extension KeychainClient: DependencyKey {
  static func live(apiTokenKey: String) -> Self {
    return Self(
      apiToken: {
        let query: [String: Any] = [
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrAccount as String: apiTokenKey,
          kSecReturnData as String: true,
          kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
          if let tokenData = dataTypeRef as? Data {
            return String(data: tokenData, encoding: .utf8)
          } else {
            return nil
          }
        } else {
          return nil
        }
      },

      updateAPIToken: { token in
        let query: [String: Any] = [
          kSecClass as String: kSecClassGenericPassword as String,
          kSecAttrAccount as String: apiTokenKey,
          kSecValueData as String: token.data(using: .utf8)!
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
      },

      deleteAPIToken: {
        let query: [String: Any] = [
          kSecClass as String: kSecClassGenericPassword as String,
          kSecAttrAccount as String: apiTokenKey
        ]

        SecItemDelete(query as CFDictionary)
      }
    )
  }

  static let liveValue  = live(apiTokenKey: "org.BlackCandy.apiTokenKey")
}
