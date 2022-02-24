import SwiftUI
import Turbo

struct ContentView: View {
  var body: some View {
    TurboView(url: "http://localhost:3000")
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
