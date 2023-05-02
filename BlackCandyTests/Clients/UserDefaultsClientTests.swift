import XCTest
@testable import BlackCandy

final class UserDefaultsClientTests: XCTestCase {
  override func tearDownWithError() throws {
    UserDefaultsClient.live.updateServerAddress(nil)
  }

  func testUpdateServerAdddress() throws {
    let userDefaultsClient = UserDefaultsClient.live
    let serverAddress = URL(string: "http://localhost:3000")!

    XCTAssertNil(userDefaultsClient.serverAddress())

    userDefaultsClient.updateServerAddress(serverAddress)
    XCTAssertEqual(userDefaultsClient.serverAddress()!, serverAddress)
  }
}
