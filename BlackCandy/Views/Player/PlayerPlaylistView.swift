import SwiftUI
import ComposableArchitecture

struct PlayerPlaylistView: View {
  let store: Store<AppState.PlayerState, AppAction.PlayerAction>
  let durationFormatter = DurationFormatter()

  var body: some View {
    WithViewStore(self.store) { viewStore in
      VStack {
        HStack {
          Text("label.tracks(\(viewStore.playlist.songs.count))")

          Spacer()

          EditButton()
        }
        .padding(CustomStyle.spacing(.small))
        .background(.ultraThinMaterial)
        .cornerRadius(CustomStyle.cornerRadius(.large))

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
          }
          .onDelete { indexSet in
            viewStore.send(.deleteSongs(indexSet))
          }
          .onMove { fromOffsets, toOffset in
            viewStore.send(.moveSongs(fromOffsets, toOffset))
          }
        }
        .listStyle(.plain)
      }
      .padding(.top, CustomStyle.spacing(.ultraWide))
    }
  }
}
