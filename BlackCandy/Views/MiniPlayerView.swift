import SwiftUI

struct MiniPlayerView: View {
  let currentSong: Song?

  var body: some View {
    HStack(spacing: 0) {
      HStack(spacing: CustomStyle.spacing(.medium)) {
        AsyncImage(url: currentSong?.albumImageUrl.small) { image in
          image.resizable()
        } placeholder: {
          Color.secondary
        }
        .cornerRadius(CustomStyle.cornerRadius(.small))
        .frame(width: CustomStyle.miniPlayerImageSize, height: CustomStyle.miniPlayerImageSize)

        Text(currentSong?.name ?? "")
      }

      Spacer()

      HStack(spacing: CustomStyle.spacing(.medium)) {
        Button(
          action: {},
          label: {
            Image(systemName: "play.fill")
              .foregroundColor(.primary)
          }
        )

        Button(
          action: {},
          label: {
            Image(systemName: "forward.fill")
              .foregroundColor(.primary)
          }
        )
      }
    }
    .padding(.horizontal)
    .padding(.vertical, CustomStyle.spacing(.narrow))
  }
}
