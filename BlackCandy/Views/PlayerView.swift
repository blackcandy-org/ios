import SwiftUI
import ComposableArchitecture

struct PlayerView: View {
  let store: StoreOf<PlayerReducer>
  var padding: EdgeInsets = .init()

  struct ViewState: Equatable {
    let isPlaylistVisible: Bool
    let currentSong: Song?
    let hasCurrentSong: Bool

    init(state: PlayerReducer.State) {
      self.currentSong = state.currentSong
      self.isPlaylistVisible = state.isPlaylistVisible
      self.hasCurrentSong = state.hasCurrentSong
    }
  }

  var body: some View {
    WithViewStore(self.store, observe: ViewState.init) { viewStore in
      VStack {
        Spacer()

        if viewStore.isPlaylistVisible {
          PlayerPlaylistView(store: store)
            .padding(.horizontal, CustomStyle.spacing(.tiny))

        } else {
          PlayerSongInfoView(currentSong: viewStore.currentSong)
          PlayerControlView(store: store)
            .disabled(!viewStore.hasCurrentSong)
            .padding(.horizontal, CustomStyle.spacing(.small))
        }

        Spacer()

        PlayerActionsView(store: store)
          .padding(.vertical, CustomStyle.spacing(.medium))
          .padding(.horizontal, CustomStyle.spacing(.large))
      }
      .padding(padding)
      .frame(maxWidth: CustomStyle.playerMaxWidth)
      .task {
        await viewStore.send(.getLivingStates).finish()
      }
    }
  }
}

struct PlayerView_Previews: PreviewProvider {
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

    return PlayerView(store: Store(initialState: PlayerReducer.State(
      playlist: playlist,
      currentSong: song1
    )) {
      PlayerReducer()
    })
  }
}
