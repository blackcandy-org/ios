import Foundation

struct JSONDataClient {
  private static let userSavedFile = "current_user.json"

  var currentUser: () -> User?
  var updateCurrentUser: (User) -> Void
  var deleteCurrentUser: () -> Void

  static func fileUrl(_ file: String) throws -> URL {
    guard let documentsFolder = try? FileManager.default.url(
      for: .documentDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: false) else {
      fatalError("Resource not found: \(file)")
    }

    return documentsFolder.appendingPathComponent(file)
  }

  static func load<T: Decodable>(file: String) throws -> T {
    let data = try Data(contentsOf: fileUrl(file))

    return try JSONDecoder().decode(T.self, from: data)
  }

  static func save<T: Encodable>(file: String, data: T) {
    DispatchQueue.global(qos: .background).async {
      guard let data = try? JSONEncoder().encode(data) else {
        fatalError("Error encoding data")
      }

      do {
        try data.write(to: fileUrl(file))
      } catch {
        fatalError("Can't write to \(file)")
      }
    }
  }
}

extension JSONDataClient {
  static let live = Self(
    currentUser: {
      try? load(file: userSavedFile)
    },

    updateCurrentUser: { user in
      save(file: userSavedFile, data: user)
    },

    deleteCurrentUser: {
      try! FileManager.default.removeItem(at: fileUrl(userSavedFile))
    }
  )
}