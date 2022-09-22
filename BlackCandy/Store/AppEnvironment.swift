import ComposableArchitecture

struct AppEnvironment {
  var mainQueue: AnySchedulerOf<DispatchQueue>
  var apiClient: APIClient
  var userDefaultsClient: UserDefaultsClient
  var cookiesClient: CookiesClient
  var keychainClient: KeychainClient
  var jsonDataClient: JSONDataClient
  var playerClient: PlayerClient

  struct PlayerEnvironment {
    var mainQueue: AnySchedulerOf<DispatchQueue>
    var playerClient: PlayerClient
    var apiClient: APIClient
  }
}
