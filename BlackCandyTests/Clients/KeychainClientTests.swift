import XCTest
@testable import BlackCandy

final class KeychainClientTests: XCTestCase {
  var keychainClient: KeychainClient!

  override func setUpWithError() throws {
    keychainClient = KeychainClient.live
  }

  override func tearDownWithError() throws {
    keychainClient.deleteAPIToken()
  }

  func testUpdateAPIToken() throws {
    keychainClient.updateAPIToken("test_token")
    XCTAssertEqual(keychainClient.apiToken(), "test_token")
  }

  func testDeleteAPIToken() throws {
    keychainClient.updateAPIToken("test_token")
    keychainClient.deleteAPIToken()

    XCTAssertNil(keychainClient.apiToken())
  }
}
