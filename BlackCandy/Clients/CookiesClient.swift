import Foundation
import WebKit

struct CookiesClient {
  private static var serverAddress: URL?

  var updateServerAddress: (URL?) -> Void
  var updateCookies: ([HTTPCookie]) -> Void
  var cleanCookies: () -> Void
  var createCookie: (String, String) -> Void

  static func updateCookies(_ cookies: [HTTPCookie]) {
    let cookieStore = WKWebsiteDataStore.default().httpCookieStore

    cookies.forEach { cookie in
      cookieStore.setCookie(cookie, completionHandler: nil)
    }
  }
}

extension CookiesClient {
  static let live = Self(
    updateServerAddress: { serverAddress in
      Self.serverAddress = serverAddress
    },

    updateCookies: { cookies in
      Self.updateCookies(cookies)
    },

    cleanCookies: {
      let cookieStore = WKWebsiteDataStore.default().httpCookieStore

      cookieStore.getAllCookies { cookies in
        cookies.forEach { cookie in
          cookieStore.delete(cookie)
        }
      }
    },

    createCookie: { name, value in
      guard let serverAddress = Self.serverAddress else { return }

      guard let cookie = HTTPCookie(properties: [
        .name: name,
        .value: value,
        .originURL: serverAddress,
        .path: "/"
      ]) else {
        return
      }

      Self.updateCookies([cookie])
    }
  )
}
