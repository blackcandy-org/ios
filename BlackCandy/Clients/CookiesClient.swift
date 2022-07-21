import Foundation
import WebKit

struct CookiesClient {
  var updateCookies: ([HTTPCookie]) -> Void
}

extension CookiesClient {
  static let live = Self(
    updateCookies: { cookies in
      let cookieStore = WKWebsiteDataStore.default().httpCookieStore

      cookies.forEach { cookie in
        cookieStore.setCookie(cookie, completionHandler: nil)
      }
    }
  )
}
