import XCTest
import WebKit
@testable import BlackCandy

@MainActor
final class CookiesClientTests: XCTestCase {
  var cookieStore: WKHTTPCookieStore!
  var cookiesClient: CookiesClient!

  override func setUp() async throws {
    let dataStore = WKWebsiteDataStore.nonPersistent()
    cookiesClient = CookiesClient.live(dataStore: dataStore)
    cookieStore = dataStore.httpCookieStore

    await cookiesClient.cleanCookies()
  }

  func testUpdateCookie() async throws {
    let cookie = HTTPCookie(properties: [
      .name: "testName",
      .value: "testValue",
      .originURL: URL(string: "http://localhost:3000")!,
      .path: "/"
    ])!

    await cookiesClient.updateCookies([cookie])

    let allCookies = await cookieStore.allCookies()

    XCTAssertEqual(cookie.value, allCookies.first?.value)
  }

  func testCreateCookie() async throws {
    await cookiesClient.createCookie("newCookie", "newCookieValue")

    let allCookies = await cookieStore.allCookies()

    XCTAssertEqual(allCookies.first?.name, "newCookie")
    XCTAssertEqual(allCookies.first?.value, "newCookieValue")
  }

  func testCleanCookies() async throws {
    await cookiesClient.createCookie("newCookie", "newCookieValue")
    await cookiesClient.cleanCookies()

    let allCookies = await cookieStore.allCookies()

    XCTAssertTrue(allCookies.isEmpty)
  }
}
