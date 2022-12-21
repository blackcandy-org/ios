import UIKit
import SwiftUI

class SidebarNavigationController: UICollectionViewController {
  private var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>!

  let sidebarSections: [SidebarSection] = [
    .standard(.init(type: .home)),
    .standard(.init(type: .account)),
    .collection(.init(type: .library), [
      .init(type: .albums),
      .init(type: .artists),
      .init(type: .playlists),
      .init(type: .songs)
    ])
  ]

  init() {
    super.init(collectionViewLayout: .init())
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    configureDataSource()
    configureLayout()
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let sidebarItem = dataSource.itemIdentifier(for: indexPath),
      let sidebarItemViewController = sidebarItem.viewController else { return }

    splitViewController?.showDetailViewController(sidebarItemViewController, sender: self)
  }

  private func configureLayout() {
    let layout = UICollectionViewCompositionalLayout { section, layoutEnvironment in
      var config = UICollectionLayoutListConfiguration(appearance: .sidebar)

      if let sidebarSection = self.dataSource.sectionIdentifier(for: section) {
        config.headerMode = sidebarSection.isCollection ? .firstItemInSection : .none
      }

      return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
    }

    collectionView.collectionViewLayout = layout
  }

  private func configureDataSource() {
    let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> { (cell, _, item) in
      var content = cell.defaultContentConfiguration()

      content.text = item.title
      cell.contentConfiguration = content
      cell.accessories = [.outlineDisclosure()]
    }

    let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> { (cell, _, item) in
      var content = cell.defaultContentConfiguration()

      content.text = item.title
      content.image = item.icon
      cell.contentConfiguration = content
      cell.accessories = []
    }

    dataSource = UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, item: SidebarItem) -> UICollectionViewCell? in
      if item.isHeader {
        return collectionView.dequeueConfiguredReusableCell(using: headerRegistration, for: indexPath, item: item)
      } else {
        return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
      }
    }

    var snapshot = NSDiffableDataSourceSnapshot<SidebarSection, SidebarItem>()
    snapshot.appendSections(sidebarSections)
    dataSource.apply(snapshot, animatingDifferences: false)

    for section in sidebarSections {
      switch section {
      case let .standard(item):
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
        sectionSnapshot.append([item])
        dataSource.apply(sectionSnapshot, to: section)

      case let .collection(headerItem, items):
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
        sectionSnapshot.append([headerItem])
        sectionSnapshot.append(items, to: headerItem)
        sectionSnapshot.expand([headerItem])
        dataSource.apply(sectionSnapshot, to: section)
      }
    }
  }
}

extension SidebarNavigationController {
  enum SidebarSection: Hashable {
    case standard(SidebarItem)
    case collection(SidebarItem, [SidebarItem])

    var isCollection: Bool {
      switch self {
      case .collection:
        return true
      default:
        return false
      }
    }
  }

  enum SidebarItemType: String {
    case home
    case account
    case library
    case albums
    case artists
    case playlists
    case songs
  }

  struct SidebarItem: Hashable {
    let type: SidebarItemType
    let viewController: UIViewController?

    init(type: SidebarItemType) {
      self.type = type

      switch type {
      case .home:
        self.viewController = TurboNavigationController(path: "/")
      case .account:
        self.viewController = UINavigationController(rootViewController: UIHostingController(rootView: AccountView(store: AppStore.shared)))
      case .albums:
        self.viewController = TurboNavigationController(path: "/albums")
      case .artists:
        self.viewController = TurboNavigationController(path: "/artists")
      case .playlists:
        self.viewController = TurboNavigationController(path: "/playlists")
      case .songs:
        self.viewController = TurboNavigationController(path: "/songs")
      default:
        self.viewController = nil
      }
    }

    var isHeader: Bool {
      switch type {
      case .library:
        return true
      default:
        return false
      }
    }

    var title: String {
      type.rawValue.capitalized
    }

    var icon: UIImage? {
      switch type {
      case .home:
        return .init(systemName: "house")
      case .account:
        return .init(systemName: "person")
      case .albums:
        return .init(systemName: "rectangle.stack")
      case .artists:
        return .init(systemName: "music.mic")
      case .playlists:
        return .init(systemName: "music.note.list")
      case .songs:
        return .init(systemName: "music.note")
      default:
        return nil
      }
    }
  }
}
