import ComposableArchitecture

struct AppEnvironment {
  var mainQueue: AnySchedulerOf<DispatchQueue>
  var apiClient: APIClient
  var userDefaultsClient: UserDefaultsClient
  var cookiesClient: CookiesClient
  var keychainClient: KeychainClient
  var jsonDataClient: JSONDataClient
}
