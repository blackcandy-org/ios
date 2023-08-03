import SwiftUI
import ComposableArchitecture

struct PlayerPlaylistView: View {
  let store: StoreOf<PlayerReducer>
  let durationFormatter = DurationFormatter()

  struct ViewState: Equatable {
    let playlist: Playlist
    let currentSong: Song?

    init(state: PlayerReducer.State) {
      self.currentSong = state.currentSong
      self.playlist = state.playlist
    }
  }

  var body: some View {
    WithViewStore(self.store, observe: ViewState.init) { viewStore in
      VStack {
        HStack {
          Text("label.tracks(\(viewStore.playlist.songs.count))")

          Spacer()

          EditButton()
        }
        .padding(CustomStyle.spacing(.small))
        .background(Color.init(.systemGray5))
        .cornerRadius(CustomStyle.cornerRadius(.large))
        .popupInteractionContainer()

        List {
          ForEach(viewStore.playlist.orderedSongs) { song in
            HStack {
              VStack(alignment: .leading, spacing: CustomStyle.spacing(.small)) {
                Text(song.name)
                  .customStyle(.mediumFont)

                Text(song.artistName)
                  .customStyle(.smallFont)
              }

              Spacer()

              Text(durationFormatter.string(from: song.duration)!)
                .customStyle(.smallFont)
            }
            .foregroundColor(song == viewStore.currentSong ? .accentColor : .primary)
            .onTapGesture {
              guard let songIndex = viewStore.playlist.index(of: song) else { return }
              viewStore.send(.playOn(songIndex))
            }
          }
          .onDelete { indexSet in
            viewStore.send(.deleteSongs(indexSet))
          }
          .onMove { fromOffsets, toOffset in
            viewStore.send(.moveSongs(fromOffsets, toOffset))
          }
          .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
      }
    }
  }
}

struct PlayerPlaylistView_Previews: PreviewProvider {
  static var previews: some View {
    let song1 = Song(
      id: 0,
      name: "Hi Hi",
      duration: 120,
      url: URL(string: "http:localhost")!,
      albumName: "Test",
      artistName: "Test artist",
      format: "mp3",
      albumImageUrl: .init(
        small: URL(string: "http:localhost")!,
        medium: URL(string: "http:localhost")!,
        large: URL(string: "http:localhost")!),
      isFavorited: true
    )

    let song2 = Song(
      id: 1,
      name: "Hi Hi 2",
      duration: 300,
      url: URL(string: "http:localhost")!,
      albumName: "Test",
      artistName: "Test artist",
      format: "mp3",
      albumImageUrl: .init(
        small: URL(string: "http:localhost")!,
        medium: URL(string: "http:localhost")!,
        large: URL(string: "http:localhost")!),
      isFavorited: false
    )

    var playlist = Playlist()
    playlist.update(songs: [song1, song2])

    return PlayerPlaylistView(
      store: Store(initialState: PlayerReducer.State(
        playlist: playlist
      )) {}
    )
  }
}
