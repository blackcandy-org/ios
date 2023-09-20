import Foundation

extension NSNotification.Name {
  static let selectedTabDidChange = Notification.Name("org.BlackCandy.selectedTabDidChange")
  static let splitViewDidExpand = Notification.Name("org.BlackCandy.splitViewDidExpand")
  static let splitViewDidCollapse = Notification.Name("org.BlackCandy.splitViewDidCollapse")
}

enum NotificationKeys: String {
  case selectedTab
}
