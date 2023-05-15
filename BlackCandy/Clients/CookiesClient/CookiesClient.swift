import Foundation
import Dependencies
import WebKit

struct CookiesClient {
  var updateServerAddress: (URL?) -> Void
  var updateCookies: ([HTTPCookie], (() -> Void)?) -> Void
  var cleanCookies: ((() -> Void)?) -> Void
  var createCookie: (String, String, (() -> Void)?) -> Void
}

extension CookiesClient: TestDependencyKey {
}

extension DependencyValues {
  var cookiesClient: CookiesClient {
    get { self[CookiesClient.self] }
    set { self[CookiesClient.self] = newValue }
  }
}
