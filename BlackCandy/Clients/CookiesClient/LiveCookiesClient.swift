import Foundation
import Dependencies
import WebKit

extension CookiesClient: DependencyKey {
  static func live(dataStore: WKWebsiteDataStore) -> Self {
    @Dependency(\.userDefaultsClient) var userDefaultClient

    func updateCookies(_ cookies: [HTTPCookie]) async {
      // WKWebsiteDataStore.httpCookieStore must be used from main thread only
      let cookieStore = await MainActor.run { dataStore.httpCookieStore }

      await withTaskGroup(of: Void.self) { taskGroup in
        for cookie in cookies {
          // SetCookie must be running in the main thread, otherwise it will throw an error.
          taskGroup.addTask { @MainActor in
            await cookieStore.setCookie(cookie)
          }
        }
      }
    }

    return Self(
      updateCookies: { cookies in
        await updateCookies(cookies)
      },

      cleanCookies: {
        // WKWebsiteDataStore.httpCookieStore must be used from main thread only
        let cookieStore = await MainActor.run { dataStore.httpCookieStore }
        let cookies = await cookieStore.allCookies()

        await withTaskGroup(of: Void.self) { taskGroup in
          for cookie in cookies {
            taskGroup.addTask { await cookieStore.deleteCookie(cookie) }
          }
        }
      },

      createCookie: { name, value in
        guard let serverAddress = userDefaultClient.serverAddress() else { return }

        guard let cookie = HTTPCookie(properties: [
          .name: name,
          .value: value,
          .originURL: serverAddress,
          .path: "/"
        ]) else {
          return
        }

        await updateCookies([cookie])
      }
    )
  }

  static let liveValue = live(dataStore: WKWebsiteDataStore.default())
}
