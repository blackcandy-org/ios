import UIKit
import SwiftUI

struct SidebarNavigationView: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> SidebarNavigationController {
    return SidebarNavigationController()
  }

  func updateUIViewController(_ uiViewController: SidebarNavigationController, context: Context) {
  }
}

class SidebarNavigationController: UICollectionViewController {
  private var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>!

  let sidebarSections: [SidebarSection] = [.home, .library]
  let sidebarSectionDetails: [SidebarSectionDetail]

  init() {
    self.sidebarSectionDetails = sidebarSections.map { SidebarSectionDetail(section: $0) }
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

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let sidebarDetail = sidebarSectionDetails[indexPath.section]
    splitViewController?.showDetailViewController(sidebarDetail.viewController, sender: self)
  }

  private func configureLayout() {
    let layout = UICollectionViewCompositionalLayout { _, layoutEnvironment in
      let config = UICollectionLayoutListConfiguration(appearance: .sidebar)

      return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
    }

    collectionView.collectionViewLayout = layout
  }

  private func configureDataSource() {
    let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> { (cell, _, item) in
      var content = cell.defaultContentConfiguration()

      content.text = item.title
      content.image = item.icon
      cell.contentConfiguration = content
      cell.accessories = []
    }

    dataSource = UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, item: SidebarItem) -> UICollectionViewCell? in
      return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
    }

    var snapshot = NSDiffableDataSourceSnapshot<SidebarSection, SidebarItem>()
    snapshot.appendSections(sidebarSections)
    dataSource.apply(snapshot, animatingDifferences: false)

    for section in sidebarSections {
      var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
      sectionSnapshot.append([section.item])
      dataSource.apply(sectionSnapshot, to: section)
    }
  }
}

extension SidebarNavigationController {
  enum SidebarSection: String {
    case home
    case library

    var item: SidebarItem {
      SidebarItem(section: self)
    }
  }

  struct SidebarItem: Hashable {
    let section: SidebarSection

    var title: String {
      section.rawValue.capitalized
    }

    var icon: UIImage? {
      switch section {
      case .home:
        return .init(systemName: "house")
      case .library:
        return .init(systemName: "square.stack")
      }
    }
  }

  class SidebarSectionDetail {
    let section: SidebarSection

    init(section: SidebarSection) {
      self.section = section
    }

    lazy var viewController: UIViewController = {
      switch section {
      case .home:
        return TurboNavigationController(path: "/")
      case .library:
        return TurboNavigationController(path: "/library")
      }
    }()
  }
}
