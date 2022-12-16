import UIKit
import SwiftUI

class SplitNavigationViewController: UICollectionViewController {
  private var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>!

  let sidebarSections: [SidebarSection] = [
    .standard(.home),
    .standard(.account),
    .collection(.library, [
      .albums,
      .artists,
      .playlists,
      .songs
    ])
  ]

  var standardSectionIndexes: [Int] {
    sidebarSections.indices.filter {
      switch sidebarSections[$0] {
      case .standard:
        return true
      case .collection:
        return false
      }
    }
  }

  init() {
    super.init(collectionViewLayout: .init())
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    configureLayout()
    configureDataSource()
  }

  private func configureLayout() {
    let layout = UICollectionViewCompositionalLayout { section, layoutEnvironment in
      var config = UICollectionLayoutListConfiguration(appearance: .sidebar)
      config.headerMode = self.standardSectionIndexes.contains(section) ? .none : .firstItemInSection

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
      if indexPath.item == 0 && !self.standardSectionIndexes.contains(indexPath.section) {
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

extension SplitNavigationViewController {
  enum SidebarSection: Hashable {
    case standard(SidebarItem)
    case collection(SidebarItem, [SidebarItem])
  }

  enum SidebarItem: String {
    case home
    case account
    case library
    case albums
    case artists
    case playlists
    case songs

    var title: String {
      rawValue.capitalized
    }

    var icon: UIImage? {
      switch self {
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
      case .library:
        return nil
      }
    }

    var destination: (any View)? {
      switch self {
      case .home:
        return TurboView(path: "/")
      case .account:
        return EmptyView()
      case .albums:
        return TurboView(path: "/albums")
      case .artists:
        return TurboView(path: "/artists")
      case .playlists:
        return TurboView(path: "/playlists")
      case .songs:
        return TurboView(path: "/songs")
      case .library:
        return nil
      }
    }
  }
}
