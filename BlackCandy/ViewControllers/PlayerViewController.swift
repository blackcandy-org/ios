import SwiftUI
import ComposableArchitecture
import LNPopupController
import Combine
import Alamofire

class PlayerViewController: UIHostingController<PlayerView> {
  @objc var _ln_interactionLimitRect: CGRect = .zero

  let store: StoreOf<PlayerReducer>
  var cancellables: Set<AnyCancellable> = []

  init(store: StoreOf<PlayerReducer>) {
    self.store = store
    super.init(rootView: PlayerView(store: store))
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.store.publisher.currentSong
      .map { $0?.name ?? NSLocalizedString("label.notPlaying", comment: "") }
      .assign(to: \.title, on: popupItem)
      .store(in: &self.cancellables)

    self.store.publisher
      .map { state in
        let pauseButton = UIBarButtonItem(image: .init(systemName: "pause.fill"), style: .plain, target: self, action: #selector(self.pause))
        let playButton = UIBarButtonItem(image: .init(systemName: "play.fill"), style: .plain, target: self, action: #selector(self.play))
        let nextButton = UIBarButtonItem(image: .init(systemName: "forward.fill"), style: .plain, target: self, action: #selector(self.nextSong))

        pauseButton.isEnabled = state.hasCurrentSong
        pauseButton.tintColor = .label

        playButton.isEnabled = state.hasCurrentSong
        playButton.tintColor = .label

        nextButton.isEnabled = state.hasCurrentSong
        nextButton.tintColor = .label

        return state.isPlaying ? [pauseButton, nextButton] : [playButton, nextButton]
      }
      .assign(to: \.barButtonItems, on: popupItem)
      .store(in: &self.cancellables)

    self.store.publisher.currentSong
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

  // This function basically copy from LNPopupUI,
  // https://github.com/LeoNatan/LNPopupUI/blob/master/Sources/LNPopupUI/Private/LNPopupUIContentController.swift
  // Use this function we can control which view we want it to interact with gesture in LNPopup.
  // So this can avoid some view like List that can not respond to scroll gesture because of the gesture in LNPopup.
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    let viewToLimitInteractionTo = firstInteractionSubview(of: view) ?? super.viewForPopupInteractionGestureRecognizer
    _ln_interactionLimitRect = view.convert(viewToLimitInteractionTo.bounds, from: viewToLimitInteractionTo)
  }

  private func firstInteractionSubview(of view: UIView) -> PopupUIInteractionView? {
    if let view = view as? PopupUIInteractionView {
      return view
    }

    var interactionView: PopupUIInteractionView?

    for subview in view.subviews {
      if let view = firstInteractionSubview(of: subview) {
        interactionView = view
        break
      }
    }

    return interactionView
  }

  @MainActor required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func pause() {
    self.store.send(.pause)
  }

  @objc private func play() {
    self.store.send(.play)
  }

  @objc private func nextSong() {
    self.store.send(.next)
  }
}

internal class PopupUIInteractionView: UIView {}

internal struct PopupUIInteractionBackgroundView: UIViewRepresentable {
  func makeUIView(context: Context) -> PopupUIInteractionView {
    return PopupUIInteractionView()
  }

  func updateUIView(_ uiView: PopupUIInteractionView, context: Context) { }
}

extension View {
  func popupInteractionContainer() -> some View {
    return background(PopupUIInteractionBackgroundView())
  }
}
