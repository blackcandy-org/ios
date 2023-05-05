import XCTest
import WebKit
@testable import BlackCandy

final class CookiesClientTests: XCTestCase {
  var cookiesClient: CookiesClient!

  override func setUpWithError() throws {
    cookiesClient = CookiesClient.live
    cookiesClient.updateServerAddress(URL(string: "http://localhost:3000")!)
  }

  override func tearDownWithError() throws {
    let expectation = XCTestExpectation(description: "Clean Cookies")

    cookiesClient.cleanCookies {
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 10.0)
  }

  func testUpdateCookie() throws {
    let cookie = HTTPCookie(properties: [
      .name: "testName",
      .value: "testValue",
      .originURL: URL(string: "http://localhost:3000")!,
      .path: "/"
    ])!

    let cookieStore = WKWebsiteDataStore.default().httpCookieStore
    let expectation = XCTestExpectation(description: "Update Cookies")

    cookiesClient.updateCookies([cookie]) {
      cookieStore.getAllCookies { allCookies in
        XCTAssertEqual(cookie.value, allCookies.first?.value)
        expectation.fulfill()
      }
    }

    wait(for: [expectation], timeout: 10.0)
  }

  func testCreateCookie() throws {
    let cookieStore = WKWebsiteDataStore.default().httpCookieStore
    let expectation = XCTestExpectation(description: "Create Cookies")

    cookiesClient.createCookie("newCookie", "newCookieValue") {
      cookieStore.getAllCookies { allCookies in
        XCTAssertEqual(allCookies.first?.name, "newCookie")
        XCTAssertEqual(allCookies.first?.value, "newCookieValue")

        expectation.fulfill()
      }
    }

    wait(for: [expectation], timeout: 10.0)
  }

  func testCleanCookies() throws {
    let cookieStore = WKWebsiteDataStore.default().httpCookieStore
    let expectation = XCTestExpectation(description: "Clean Cookies")

    cookiesClient.createCookie("newCookie", "newCookieValue") {
      self.cookiesClient.cleanCookies {
        cookieStore.getAllCookies { allCookies in
          XCTAssertTrue(allCookies.isEmpty)

          expectation.fulfill()
        }
      }
    }

    wait(for: [expectation], timeout: 10.0)
  }
}
