import SwiftUI

#if os(iOS)
import UIKit

// MARK: - Zoom transition source

/// Reads the host probe view's frame lazily, at the moment of the touch, so scrolling
/// never invalidates it and no per-scroll-frame GeometryReader/preference churn is needed.
private final class ZoomSourceFrameBox {
    weak var view: UIView?

    /// Invoked when a touch lands on this source, before any tap action fires.
    var onTouched: (() -> Void)?

    var windowFrame: CGRect? {
        guard let view, let window = view.window,
              view.bounds.width > 0, view.bounds.height > 0 else { return nil }
        return view.convert(view.bounds, to: window)
    }
}

/// Matches every touch-down against the registered zoom sources and records the frame
/// of the card under the finger. Capture happens at the window level with a recognizer
/// that fails instantly, so it can never delay, cancel, or compete with any other
/// gesture — scroll views, buttons, and tap gestures are completely unaffected.
private enum ZoomSourceTouchObserver {
    private static let boxes = NSHashTable<ZoomSourceFrameBox>.weakObjects()
    private static let observedWindows = NSHashTable<UIWindow>.weakObjects()

    // A view's reported frame is its final, settled position — UIKit applies that the
    // instant an animation is set up, even while the view is still visually animating
    // toward it. A touch during that window can land up to roughly this many points
    // outside the frame we read. This only widens which sources are considered a match;
    // the exact (unpadded) frame is still what's used for the zoom animation itself.
    private static let matchTolerance: CGFloat = 20

    static func register(_ box: ZoomSourceFrameBox, in window: UIWindow) {
        boxes.add(box)
        guard !observedWindows.contains(window) else { return }
        observedWindows.add(window)
        let recognizer = TouchDownObserverRecognizer()
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesBegan = false
        recognizer.delaysTouchesEnded = false
        window.addGestureRecognizer(recognizer)
    }

    static func handleTouchDown(at point: CGPoint, in window: UIWindow) {
        // Among sources whose frame contains the touch, the correct one is whichever
        // is actually rendered in front — not whichever bounding box is smaller. Two
        // unrelated sources can be geometrically adjacent (e.g. a card sitting right
        // below a locker header, where both frames touch at the shared boundary);
        // comparing area can't tell them apart, real z-order can. With only one
        // candidate under the touch (the common case), no comparison happens at all,
        // so unambiguous taps are unaffected.
        // A touch actually inside a source always beats a tolerance-only match —
        // otherwise a tap near a card's edge can anchor the zoom to the neighbouring
        // card whose inflated frame merely grazes the point, while the tap gesture
        // (exact bounds) opens the touched card. Z-order only settles ties within
        // the same tier; among tolerance-only matches, the nearest frame wins.
        var best: (box: ZoomSourceFrameBox, frame: CGRect, view: UIView, exact: Bool)?
        for box in boxes.allObjects {
            guard let view = box.view, view.window === window,
                  let frame = box.windowFrame,
                  // Widened only for the hit-test — `frame` itself (used below as the
                  // animation's source rect) stays exact.
                  frame.insetBy(dx: -matchTolerance, dy: -matchTolerance).contains(point) else { continue }
            let exact = frame.contains(point)
            if let current = best {
                if exact != current.exact {
                    if exact { best = (box, frame, view, true) }
                } else if exact {
                    if isInFront(view, of: current.view) == true {
                        best = (box, frame, view, true)
                    }
                } else if distance(from: point, to: frame) < distance(from: point, to: current.frame) {
                    best = (box, frame, view, false)
                }
            } else {
                best = (box, frame, view, exact)
            }
        }
        if let best {
            ZoomTransitionContext.shared.sourceFrame = best.frame
            // Clear any previous registration, then let this card re-register its
            // bounce (onTouched is nil when highlightOnReturn is false).
            ZoomTransitionContext.shared.onPopCompleted = nil
            best.box.onTouched?()
        } else {
            // Touch outside any source: clear the frame so a later programmatic
            // pushZoom falls back to the centered-rect zoom instead of a stale card.
            // Deliberately leave onPopCompleted alone — this touch may be the back
            // button of the screen we zoom-pushed, and clearing here would kill the
            // return bounce registered when the card was tapped. (Pops read
            // lastPushSourceFrame, so zeroing sourceFrame never affects them.)
            ZoomTransitionContext.shared.sourceFrame = .zero
        }
    }

    private static func distance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let dx = max(rect.minX - point.x, 0, point.x - rect.maxX)
        let dy = max(rect.minY - point.y, 0, point.y - rect.maxY)
        return hypot(dx, dy)
    }

    /// True if `a` is rendered in front of `b`. A view nested inside another always
    /// wins (more specific). Otherwise, walks up to their nearest common ancestor and
    /// compares position in its `subviews` — later index draws on top and is what
    /// UIKit's own hit-testing checks first, so this mirrors real hit-test order
    /// instead of guessing from frame geometry. Returns nil only if no relationship
    /// can be established (shouldn't happen for two views in the same window).
    private static func isInFront(_ a: UIView, of b: UIView) -> Bool? {
        if a === b { return nil }
        if a.isDescendant(of: b) { return true }
        if b.isDescendant(of: a) { return false }

        var aAncestors: [UIView] = []
        var v: UIView? = a
        while let cur = v { aAncestors.append(cur); v = cur.superview }

        var bBranch: UIView = b
        var current: UIView? = b
        while let candidate = current {
            if let idx = aAncestors.firstIndex(of: candidate) {
                let aBranch = idx == 0 ? a : aAncestors[idx - 1]
                let siblings = candidate.subviews
                guard let aIndex = siblings.firstIndex(of: aBranch),
                      let bIndex = siblings.firstIndex(of: bBranch) else { return nil }
                return aIndex > bIndex
            }
            bBranch = candidate
            current = candidate.superview
        }
        return nil
    }
}

private final class TouchDownObserverRecognizer: UIGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if let window = view as? UIWindow ?? view?.window, let touch = touches.first {
            ZoomSourceTouchObserver.handleTouchDown(at: touch.location(in: window), in: window)
        }
        state = .failed
    }
}

private final class ZoomSourceProbeView: UIView {
    var box: ZoomSourceFrameBox?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window, let box else { return }
        ZoomSourceTouchObserver.register(box, in: window)
    }
}

private struct ZoomSourceProbe: UIViewRepresentable {
    let box: ZoomSourceFrameBox

    func makeUIView(context: Context) -> ZoomSourceProbeView {
        let view = ZoomSourceProbeView()
        view.isUserInteractionEnabled = false
        view.box = box
        box.view = view
        return view
    }

    func updateUIView(_ uiView: ZoomSourceProbeView, context: Context) {}
}

/// Marks a view as the source element for a `pushZoom` navigation, without taking
/// over its tap handling — existing Buttons / gesture modifiers keep working, and no
/// gesture is added to the view. The frame is recorded at touch-down by a passive
/// window-level observer, before any tap action fires, so a `navigator.pushZoom`
/// triggered by that tap expands from the touched view even when the push happens
/// synchronously.
///
/// ```swift
/// ProductCard()
///     .zoomTapSource(highlightOnReturn: true)
///     .onTapGesture { navigator.pushZoom(.detail) }
/// ```
public struct ZoomTapSourceModifier: ViewModifier {
    let highlightOnReturn: Bool

    @State private var box = ZoomSourceFrameBox()
    @State private var isHighlighted = false

    public func body(content: Content) -> some View {
        box.onTouched = highlightOnReturn ? {
            // Bounces the card when the user zoom-pops back to it. Registered at
            // touch-down and cleared by the observer when a touch lands elsewhere,
            // so only the view that actually triggered the zoom bounces.
            ZoomTransitionContext.shared.onPopCompleted = {
                isHighlighted = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                    isHighlighted = false
                }
            }
        } : nil

        return content
            .scaleEffect(isHighlighted ? 1.05 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: isHighlighted)
            .background(ZoomSourceProbe(box: box))
    }
}

public extension View {
    /// Marks this view as the zoom source without taking over its tap handling.
    /// - Parameter highlightOnReturn: Bounces the view when the user navigates back
    ///   to it via the zoom pop. Defaults to `true`.
    func zoomTapSource(highlightOnReturn: Bool = true) -> some View {
        modifier(ZoomTapSourceModifier(highlightOnReturn: highlightOnReturn))
    }
}
#endif
