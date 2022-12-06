import ComposableArchitecture

struct AppEnvironment {
  var apiClient: APIClient
  var userDefaultsClient: UserDefaultsClient
  var cookiesClient: CookiesClient
  var keychainClient: KeychainClient
  var jsonDataClient: JSONDataClient
  var playerClient: PlayerClient
  var nowPlayingClient: NowPlayingClient

  struct PlayerEnvironment {
    var playerClient: PlayerClient
    var apiClient: APIClient
    var nowPlayingClient: NowPlayingClient
    var cookiesClient: CookiesClient
  }
}
