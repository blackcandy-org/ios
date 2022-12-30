import UIKit

class SideBarViewController: UICollectionViewController {
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

    configureDataSource()
    configInitSelection()
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let selectedSection = sidebarSections[indexPath.section]
    guard let secondaryViewController = splitViewController?.viewController(for: .secondary) as? UITabBarController,
      case let .tab(item) = selectedSection else { return }

    secondaryViewController.selectedIndex = item.tagIndex
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
}

extension SideBarViewController {
  enum SidebarSection: Hashable {
    case tab(TabItem)
  }
}
