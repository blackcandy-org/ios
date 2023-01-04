import SwiftUI
import ComposableArchitecture

struct PlayerPlaylistView: View {
  let store: StoreOf<PlayerReducer>
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
        }
        .listStyle(.plain)
        .frame(minHeight: CustomStyle.playlistMinHeight)
      }
    }
  }
}
