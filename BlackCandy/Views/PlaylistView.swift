import SwiftUI

struct PlaylistView: View {
  let songs: [Song]

  var body: some View {
    List(songs) {
      Text($0.name)
    }
  }
}
