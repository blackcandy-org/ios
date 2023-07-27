import SwiftUI

struct PlayerSongInfoView: View {
  let currentSong: Song?

  var body: some View {
    VStack {
      AsyncImage(url: currentSong?.albumImageUrl.large) { image in
        image.resizable()
      } placeholder: {
        Color.secondary
      }
      .cornerRadius(CustomStyle.cornerRadius(.medium))
      .frame(width: CustomStyle.playerImageSize, height: CustomStyle.playerImageSize)
      .padding(.bottom, CustomStyle.spacing(.extraWide))

      VStack(spacing: CustomStyle.spacing(.tiny)) {
        Text(currentSong?.name ?? NSLocalizedString("label.notPlaying", comment: ""))
          .font(.headline)
        Text(currentSong?.artistName ?? "")
          .font(.caption)
      }
      .padding(.bottom, CustomStyle.spacing(.wide))
    }
  }
}

struct PlayerSongInfoView_Previews: PreviewProvider {
  static var previews: some View {
    let song = Song(
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

    PlayerSongInfoView(currentSong: song)
  }
}
