import SwiftUI

#if os(iOS)
/// Prepares a view as the source element for a `pushZoom` navigation.
///
/// Pass your `pushZoom` call as the trailing closure — the modifier sets the source frame
/// and registers the highlight callback before invoking it, guaranteeing correct ordering.
///
/// ```swift
/// ProductCard()
///     .zoomSource(highlightOnReturn: true) {
///         navigator.pushZoom(.detail)
///     }
/// ```
public struct ZoomSourceModifier: ViewModifier {
    let highlightOnReturn: Bool
    let push: () -> Void

    @State private var frame: CGRect = .zero
    @State private var isHighlighted = false

    public func body(content: Content) -> some View {
        content
            .scaleEffect(isHighlighted ? 1.05 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: isHighlighted)
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        frame = geo.frame(in: .global)
                    }
                }
            )
            .onTapGesture {
                ZoomTransitionContext.shared.sourceFrame = frame
                if highlightOnReturn {
                    ZoomTransitionContext.shared.onPopCompleted = {
                        isHighlighted = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                            isHighlighted = false
                        }
                    }
                }
                push()
            }
    }
}

public extension View {
    /// Marks this view as the zoom source and handles the tap.
    /// - Parameters:
    ///   - highlightOnReturn: Bounces the element when the user navigates back. Defaults to `true`.
    ///   - push: Call `navigator.pushZoom()` here. Invoked after the source frame is captured.
    func zoomSource(highlightOnReturn: Bool = true, push: @escaping () -> Void) -> some View {
        modifier(ZoomSourceModifier(highlightOnReturn: highlightOnReturn, push: push))
    }
}
#endif
