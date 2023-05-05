import Foundation
import WebKit

struct CookiesClient {
  private static var serverAddress: URL?

  var updateServerAddress: (URL?) -> Void
  var updateCookies: ([HTTPCookie], (() -> Void)?) -> Void
  var cleanCookies: ((() -> Void)?) -> Void
  var createCookie: (String, String, (() -> Void)?) -> Void

  static func updateCookies(_ cookies: [HTTPCookie], _ completionHandler: (() -> Void)?) {
    let cookieStore = WKWebsiteDataStore.default().httpCookieStore
    let group = DispatchGroup()

    cookies.forEach { cookie in
      group.enter()
      cookieStore.setCookie(cookie) {
        group.leave()
      }
    }

    group.notify(queue: .main) {
      completionHandler?()
    }
  }
}

extension CookiesClient {
  static let live = Self(
    updateServerAddress: { serverAddress in
      Self.serverAddress = serverAddress
    },

    updateCookies: { cookies, completionHandler in
      Self.updateCookies(cookies, completionHandler)
    },

    cleanCookies: { completionHandler in
      let cookieStore = WKWebsiteDataStore.default().httpCookieStore
      let group = DispatchGroup()

      group.enter()

      cookieStore.getAllCookies { cookies in
        cookies.forEach { cookie in
          group.enter()
          cookieStore.delete(cookie) {
            group.leave()
          }
        }
        group.leave()
      }

      group.notify(queue: .main) {
        completionHandler?()
      }
    },

    createCookie: { name, value, completionHandler in
      guard let serverAddress = Self.serverAddress else { return }

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
