import Foundation
import Dependencies
import WebKit

extension CookiesClient: DependencyKey {
  private static var serverAddress: URL?

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

  static let liveValue = Self(
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
