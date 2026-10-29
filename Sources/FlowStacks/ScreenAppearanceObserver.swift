import Foundation
import SwiftUI

/// Reports which routed screen is on screen, e.g. for debug tooling.
/// Unset by default, which costs one nil check per appear and disappear.
@MainActor
public enum ScreenAppearanceObserver {
  /// Called with the route's screen value and a token unique to this presentation of it.
  public static var onAppear: ((_ screen: Any, _ token: UUID) -> Void)?
  /// Called with the token passed to `onAppear` when that screen leaves the screen.
  public static var onDisappear: ((_ token: UUID) -> Void)?
}

/// Lets wrapper screens (like the `showing` root) report the screen they stand for, or nothing.
protocol ScreenWrapping {
  var wrappedScreen: Any? { get }
}

struct ScreenAppearanceReporter: ViewModifier {
  let screen: Any?
  @State private var token = UUID()

  func body(content: Content) -> some View {
    content
      .onAppear {
        guard let screen = screen else { return }
        ScreenAppearanceObserver.onAppear?(screen, token)
      }
      .onDisappear {
        ScreenAppearanceObserver.onDisappear?(token)
      }
  }
}
