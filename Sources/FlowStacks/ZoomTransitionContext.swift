import Foundation
import CoreGraphics

/// Holds the source frame for zoom push/pop animations.
/// Set `sourceFrame` in global screen coordinates before calling `pushZoom`.
@MainActor
public class ZoomTransitionContext {
    public static let shared = ZoomTransitionContext()

    /// Set this to the tapped element's frame (in global screen coordinates) before calling pushZoom.
    public var sourceFrame: CGRect = .zero

    /// Captured during push, reused during the corresponding pop.
    var lastPushSourceFrame: CGRect = .zero

    /// Called on the main thread when a pop transition successfully completes.
    /// Set this before calling pushZoom to receive a callback when the user returns.
    public var onPopCompleted: (() -> Void)?

    private init() {}
}
