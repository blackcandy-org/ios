import Foundation
import Dependencies

private enum APIClientKey: DependencyKey {
  static let liveValue = APIClient.live
}

private enum UserDefaultsClientKey: DependencyKey {
  static let liveValue = UserDefaultsClient.live
}

private enum CookiesClientKey: DependencyKey {
  static let liveValue = CookiesClient.live
}

private enum KeychainClientKey: DependencyKey {
  static let liveValue = KeychainClient.live
}

private enum JSONDataClientKey: DependencyKey {
  static let liveValue = JSONDataClient.live
}

private enum PlayerClientKey: DependencyKey {
  static let liveValue = PlayerClient.live
}

private enum NowPlayingClientKey: DependencyKey {
  static let liveValue = NowPlayingClient.live
}

extension DependencyValues {
  var apiClient: APIClient {
    get { self[APIClientKey.self] }
    set { self[APIClientKey.self] = newValue }
  }

  var userDefaultsClient: UserDefaultsClient {
    get { self[UserDefaultsClientKey.self] }
    set { self[UserDefaultsClientKey.self] = newValue }
  }

  var cookiesClient: CookiesClient {
    get { self[CookiesClientKey.self] }
    set { self[CookiesClientKey.self] = newValue }
  }

  var keychainClient: KeychainClient {
    get { self[KeychainClientKey.self] }
    set { self[KeychainClientKey.self] = newValue }
  }

  var jsonDataClient: JSONDataClient {
    get { self[JSONDataClientKey.self] }
    set { self[JSONDataClientKey.self] = newValue }
  }

  var playerClient: PlayerClient {
    get { self[PlayerClientKey.self] }
    set { self[PlayerClientKey.self] = newValue }
  }

  var nowPlayingClient: NowPlayingClient {
    get { self[NowPlayingClientKey.self] }
    set { self[NowPlayingClientKey.self] = newValue }
  }
}
