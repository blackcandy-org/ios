import Foundation
import Dependencies

extension JSONDataClient: DependencyKey {
  static func live(userSavedFile: String) -> Self {
    func fileUrl(_ file: String) throws -> URL {
      guard let documentsFolder = try? FileManager.default.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: false) else {
        fatalError("Resource not found: \(file)")
      }

      return documentsFolder.appendingPathComponent(file)
    }

    func load<T: Decodable>(file: String) throws -> T {
      let data = try Data(contentsOf: fileUrl(file))

      return try JSONDecoder().decode(T.self, from: data)
    }

    func save<T: Encodable>(file: String, data: T, completionHandler: (() -> Void)? = nil) {
      DispatchQueue.global(qos: .background).async {
        guard let data = try? JSONEncoder().encode(data) else {
          fatalError("Error encoding data")
        }

        do {
          try data.write(to: fileUrl(file))
          completionHandler?()
        } catch {
          fatalError("Can't write to \(file)")
        }
      }
    }

    return Self(
      currentUser: {
        try? load(file: userSavedFile)
      },

      updateCurrentUser: { user, completionHandler in
        save(file: userSavedFile, data: user, completionHandler: completionHandler)
      },

      deleteCurrentUser: {
        try! FileManager.default.removeItem(at: fileUrl(userSavedFile))
      }
    )
  }

  static let liveValue = live(userSavedFile: "current_user.json")
}
