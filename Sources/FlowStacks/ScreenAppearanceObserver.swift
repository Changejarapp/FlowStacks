import Foundation
import SwiftUI

/// Reports which routed screen is on screen, e.g. for debug tooling.
/// Set it once at launch, before any routed screen renders; while unset, routed screens carry no reporter at all.
@MainActor
public enum ScreenAppearanceObserver {
  /// Called with the view built for a route (or a `showing` root) and a token unique to this presentation of it.
  public static var onAppear: ((_ view: Any, _ token: UUID) -> Void)?
  /// Called with the token passed to `onAppear` when that view leaves the screen.
  public static var onDisappear: ((_ token: UUID) -> Void)?
}

struct ScreenAppearanceReporter: ViewModifier {
  let view: Any
  @State private var token = UUID()

  func body(content: Content) -> some View {
    content
      .onAppear {
        ScreenAppearanceObserver.onAppear?(view, token)
      }
      .onDisappear {
        ScreenAppearanceObserver.onDisappear?(token)
      }
  }
}
