import Foundation
import UIKit

class TurboNavigationController: UINavigationController {
  override func viewDidLoad() {
    setNavigationBarHidden(true, animated: false)
    super.viewDidLoad()
  }
}
