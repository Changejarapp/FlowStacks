import SwiftUI

@main
struct FlowStacksApp: App {
  enum Tab: Hashable {
    case parentCoordinator
    case numberCoordinator
    case vmCoordinator
    case bindingCoordinator
    case showingCoordinator
    case navPlaygroundCoordinator
  }
  
  @State var selectedTab: Tab = .numberCoordinator
  
  var body: some Scene {
    WindowGroup {
      TabView(selection: $selectedTab) {
        ParentCoordinator()
          .tabItem { Text("Parent") }
          .tag(Tab.parentCoordinator)
        NumberCoordinator()
          .tabItem { Text("Numbers") }
          .tag(Tab.numberCoordinator)
        VMCoordinator()
          .tabItem { Text("VMs") }
          .tag(Tab.vmCoordinator)
        BindingCoordinator()
          .tabItem { Text("Binding") }
          .tag(Tab.bindingCoordinator)
        ShowingCoordinator()
          .tabItem { Text("Showing") }
          .tag(Tab.showingCoordinator)
        NavPlaygroundCoordinator()
          .tabItem { Text("Playground") }
          .tag(Tab.navPlaygroundCoordinator)
      }.onOpenURL { url in
        guard let deeplink = Deeplink(url: url) else { return }
        follow(deeplink)
      }
    }
  }
  
  private func follow(_ deeplink: Deeplink) {
    // Test deeplinks from CLI with, e.g.:
    //`xcrun simctl openurl booted flowstacksapp://numbers/42/13`
    switch deeplink {
    case .numberCoordinator:
      selectedTab = .numberCoordinator
    }
  }
}
