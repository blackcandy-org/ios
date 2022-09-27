import SwiftUI

struct PlayerSongInfoView: View {
  let currentSong: Song?

  var body: some View {
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
