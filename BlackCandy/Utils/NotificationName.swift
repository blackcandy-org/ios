import Foundation

extension NSNotification.Name {
  static let selectedTabDidChange = Notification.Name("com.aidewooode.BlackCandy.selectedTabDidChange")
  static let splitViewDidExpand = Notification.Name("com.aidewooode.BlackCandy.splitViewDidExpand")
  static let splitViewDidCollapse = Notification.Name("com.aidewooode.BlackCandy.splitViewDidCollapse")
}

enum NotificationKeys: String {
  case selectedTab
}
