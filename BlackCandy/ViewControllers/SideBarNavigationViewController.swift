import UIKit
import SwiftUI

struct SideBarNavigationView: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> SideBarNavigationViewController {
    return SideBarNavigationViewController()
  }

  func updateUIViewController(_ uiViewController: SideBarNavigationViewController, context: Context) {
  }
}

class SideBarNavigationViewController: UICollectionViewController {
  private var dataSource: UICollectionViewDiffableDataSource<SidebarSection, TabItem>!

  let sidebarSections: [SidebarSection] = [.tab(.home), .tab(.library)]

  init() {
    let layout = UICollectionViewCompositionalLayout { _, layoutEnvironment in
      let config = UICollectionLayoutListConfiguration(appearance: .sidebar)

      return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
    }

    super.init(collectionViewLayout: layout)

    clearsSelectionOnViewWillAppear = false
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(selectedTabDidChanged(_:)),
      name: .selectedTabDidChange,
      object: nil
    )

    configureDataSource()
    configInitSelection()
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let selectedSection = sidebarSections[indexPath.section]
    guard case let .tab(item) = selectedSection else { return }

    NotificationCenter.default.post(
      name: .selectedTabDidChange,
      object: self,
      userInfo: [NotificationKeys.selectedTab: item]
    )
  }

  func selectTabItem(_ tabItem: TabItem) {
    guard let selectedSectionIndex = sidebarSections.firstIndex(where: { section in
      guard case let .tab(item) = section else { return false }
      return item == tabItem
    }) else { return }

    collectionView.selectItem(
      at: IndexPath(row: 0, section: selectedSectionIndex),
      animated: false,
      scrollPosition: UICollectionView.ScrollPosition.centeredVertically
    )
  }

  private func configureDataSource() {
    let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, TabItem> { (cell, _, item) in
      var content = cell.defaultContentConfiguration()

      content.text = item.title
      content.image = item.icon
      cell.contentConfiguration = content
      cell.accessories = []
    }

    dataSource = UICollectionViewDiffableDataSource<SidebarSection, TabItem>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, item: TabItem) -> UICollectionViewCell? in
      return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
    }

    var snapshot = NSDiffableDataSourceSnapshot<SidebarSection, TabItem>()
    snapshot.appendSections(sidebarSections)
    dataSource.apply(snapshot, animatingDifferences: false)

    for section in sidebarSections {
      switch section {
      case let .tab(item):
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<TabItem>()
        sectionSnapshot.append([item])
        dataSource.apply(sectionSnapshot, to: section)
      }
    }
  }

  private func configInitSelection() {
    selectTabItem(.home)
  }

  @objc private func selectedTabDidChanged(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
      let selectedTab = userInfo[NotificationKeys.selectedTab] as? TabItem else { return }

    selectTabItem(selectedTab)
  }
}

extension SideBarNavigationViewController {
  enum SidebarSection: Hashable {
    case tab(TabItem)
  }
}
