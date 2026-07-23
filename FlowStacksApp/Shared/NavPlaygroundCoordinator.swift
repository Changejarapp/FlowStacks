import FlowStacks
import SwiftUI

// MARK: - Screen

enum NavPlaygroundScreen {
    case home
    case detail(String, PushStyle, Color)
}

enum PushStyle: String, CaseIterable {
    case plain = "push(_:)"
    case leftToRight = "pushLeftToRight(_:)"
    case bottomToTop = "pushBottomToTop(_:)"
    case zoom = "pushZoom(_:)"
}

// MARK: - Coordinator

struct NavPlaygroundCoordinator: View {
    @State var routes: Routes<NavPlaygroundScreen> = [.root(.home, embedInNavigationView: true)]

    var body: some View {
        Router($routes) { screen, _ in
            switch screen {
            case .home:
                NavPlaygroundHomeView()
            case .detail(let title, let style, let color):
                PushStyleDetailView(title: title, style: style, color: color)
            }
        }
    }
}
