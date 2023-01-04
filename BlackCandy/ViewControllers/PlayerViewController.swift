import SwiftUI
import ComposableArchitecture
import LNPopupController
import Combine
import Alamofire

class PlayerViewController: UIHostingController<PlayerView> {
  let viewStore: ViewStoreOf<PlayerReducer>
  var cancellables: Set<AnyCancellable> = []

  init(store: StoreOf<PlayerReducer>) {
    self.viewStore = ViewStore(store)
    super.init(rootView: PlayerView(store: store))
  }

  override func viewDidLoad() {
    self.viewStore.publisher
      .map { $0.currentSong?.name ?? NSLocalizedString("label.notPlaying", comment: "") }
      .assign(to: \.title, on: popupItem)
      .store(in: &self.cancellables)

    self.viewStore.publisher
      .map { state in
        let pauseButton = UIBarButtonItem(image: .init(systemName: "pause.fill"), style: .plain, target: self, action: #selector(self.pause))
        let playButton = UIBarButtonItem(image: .init(systemName: "play.fill"), style: .plain, target: self, action: #selector(self.play))
        let nextButton = UIBarButtonItem(image: .init(systemName: "forward.fill"), style: .plain, target: self, action: #selector(self.nextSong))

        pauseButton.isEnabled = state.hasCurrentSong
        pauseButton.tintColor = UIColor(.primary)

        playButton.isEnabled = state.hasCurrentSong
        playButton.tintColor = UIColor(.primary)

        nextButton.isEnabled = state.hasCurrentSong
        nextButton.tintColor = UIColor(.primary)

        return state.isPlaying ? [pauseButton, nextButton] : [playButton, nextButton]
      }
      .assign(to: \.barButtonItems, on: popupItem)
      .store(in: &self.cancellables)

    self.viewStore.publisher.currentSong
      .sink { [weak self] currentSong in
        guard let imageUrl = currentSong?.albumImageUrl.small else { return }

        AF.download(imageUrl).response { response in
          guard
            response.error == nil,
            let imagePath = response.fileURL?.path,
            let image = UIImage(contentsOfFile: imagePath) else { return }

          self?.popupItem.image = image
        }
      }
      .store(in: &self.cancellables)
  }

  @MainActor required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func pause() {
    self.viewStore.send(.pause)
  }

  @objc private func play() {
    self.viewStore.send(.play)
  }

  @objc private func nextSong() {
    self.viewStore.send(.next)
  }
}
