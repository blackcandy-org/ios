import Foundation
import WebKit

struct CookiesClient {
  var updateCookies: ([HTTPCookie], (() -> Void)?) -> Void
  var cleanCookies: () -> Void
  var createCookie: (String, String, (() -> Void)?) -> Void

  static func updateCookies(_ cookies: [HTTPCookie], _ completionHandler: (() -> Void)?) {
    let cookieStore = WKWebsiteDataStore.default().httpCookieStore

    cookies.forEach { cookie in
      cookieStore.setCookie(cookie, completionHandler: completionHandler)
    }
  }
}

extension CookiesClient {
  static let live = Self(
    updateCookies: { cookies, completionHandler in
      Self.updateCookies(cookies, completionHandler)
    },

    cleanCookies: {
      let cookieStore = WKWebsiteDataStore.default().httpCookieStore

      cookieStore.getAllCookies { cookies in
        cookies.forEach { cookie in
          cookieStore.delete(cookie)
        }
      }
    },

    createCookie: { name, value, completionHandler in
      guard let serverAddress = UserDefaultsClient.live.serverAddress() else { return }

      guard let cookie = HTTPCookie(properties: [
        .name: name,
        .value: value,
        .originURL: serverAddress,
        .path: "/"
      ]) else {
        return
      }

      Self.updateCookies([cookie], completionHandler)
    }
  )
}
