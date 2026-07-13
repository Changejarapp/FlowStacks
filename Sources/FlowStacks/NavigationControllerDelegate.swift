import SwiftUI

#if os(iOS)
import UIKit

// How a view controller was pushed, remembered on the view controller itself.
// The delegate's push/pop flags are rewritten by every SwiftUI update of every
// router node sharing the navigation controller — including nested Routers
// (`.showing` coordinators) inside a pushed screen, which know nothing about how
// their container was pushed and overwrite the flags with `false`. A pop decided
// from those flags therefore loses its custom animation whenever the pushed
// screen hosts a nested router. The tag on the departing view controller can't
// be clobbered by anyone, so pops always mirror their push.
private enum PushTransitionStyle {
    case plain
    case leftToRight
    case zoom
    case bottomToTop
}

private var pushTransitionStyleKey: UInt8 = 0

private extension UIViewController {
    var pushTransitionStyle: PushTransitionStyle {
        get { objc_getAssociatedObject(self, &pushTransitionStyleKey) as? PushTransitionStyle ?? .plain }
        set { objc_setAssociatedObject(self, &pushTransitionStyleKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

class CustomNavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
    var useLeftToRightForPush: Bool = false
    var useLeftToRightForPop: Bool = false
    var useZoomForPush: Bool = false
    var useZoomForPop: Bool = false
    var useBottomToTopForPush: Bool = false
    var useBottomToTopForPop: Bool = false

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .push where useZoomForPush:
            toVC.pushTransitionStyle = .zoom
            return ZoomTransition(operation: operation, sourceFrame: ZoomTransitionContext.shared.sourceFrame)
        case .push where useLeftToRightForPush:
            toVC.pushTransitionStyle = .leftToRight
            return LeftToRightTransition(operation: operation)
        case .push where useBottomToTopForPush:
            toVC.pushTransitionStyle = .bottomToTop
            return BottomToTopTransition(operation: operation)
        case .push:
            toVC.pushTransitionStyle = .plain
            return nil
        case .pop:
            switch fromVC.pushTransitionStyle {
            case .zoom:
                return ZoomTransition(operation: operation, sourceFrame: ZoomTransitionContext.shared.lastPushSourceFrame)
            case .leftToRight:
                return LeftToRightTransition(operation: operation)
            case .bottomToTop:
                return BottomToTopTransition(operation: operation)
            case .plain:
                return nil
            }
        default:
            return nil
        }
    }
}

class LeftToRightTransition: NSObject, UIViewControllerAnimatedTransitioning {
    let operation: UINavigationController.Operation
    var duration: TimeInterval = 0.35

    init(operation: UINavigationController.Operation) {
        self.operation = operation
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from),
              let toView = transitionContext.view(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        let container = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)

        if operation == .push {
            // Push: new view comes from LEFT, old view goes to RIGHT
            container.addSubview(toView)
            toView.frame = container.bounds.offsetBy(dx: -container.bounds.width, dy: 0)

            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
                toView.frame = container.bounds
                fromView.frame = container.bounds.offsetBy(dx: container.bounds.width, dy: 0)
            } completion: { finished in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        } else if operation == .pop {
            // Pop: old view comes from RIGHT, current view goes to LEFT
            container.insertSubview(toView, belowSubview: fromView)
            toView.frame = container.bounds.offsetBy(dx: container.bounds.width, dy: 0)

            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
                toView.frame = container.bounds
                fromView.frame = container.bounds.offsetBy(dx: -container.bounds.width, dy: 0)
            } completion: { finished in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}

// Netflix notifications-style push: the new screen slides up from the bottom and
// covers the current screen, which stays fixed underneath rather than parallaxing
// away (unlike LeftToRightTransition, where both views move).
class BottomToTopTransition: NSObject, UIViewControllerAnimatedTransitioning {
    let operation: UINavigationController.Operation
    var duration: TimeInterval = 0.4

    init(operation: UINavigationController.Operation) {
        self.operation = operation
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from),
              let toView = transitionContext.view(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        let container = transitionContext.containerView

        if operation == .push {
            // fromView stays put — it's being covered, not displaced.
            container.addSubview(toView)
            toView.frame = container.bounds.offsetBy(dx: 0, dy: container.bounds.height)

            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
                toView.frame = container.bounds
            } completion: { finished in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        } else if operation == .pop {
            // toView is already in its resting position underneath; only fromView moves.
            container.insertSubview(toView, belowSubview: fromView)
            toView.frame = container.bounds

            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn) {
                fromView.frame = container.bounds.offsetBy(dx: 0, dy: container.bounds.height)
            } completion: { finished in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}

class ZoomTransition: NSObject, UIViewControllerAnimatedTransitioning {
    let operation: UINavigationController.Operation
    let sourceFrame: CGRect

    private let pushDuration: TimeInterval = 0.5
    private let popDuration: TimeInterval = 0.4
    private let cardCornerRadius: CGFloat = 16
    private let backgroundScale: CGFloat = 0.94
    private let dimAlpha: CGFloat = 0.25

    // Reads the physical screen corner radius via KVC — stable private API,
    // widely used and App Store accepted. Falls back to 0 on older devices.
    private var screenCornerRadius: CGFloat {
        (UIScreen.main.value(forKey: "displayCornerRadius") as? CGFloat) ?? 0
    }

    init(operation: UINavigationController.Operation, sourceFrame: CGRect) {
        self.operation = operation
        self.sourceFrame = sourceFrame
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return operation == .push ? pushDuration : popDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from),
              let toView = transitionContext.view(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        let container = transitionContext.containerView
        // Stops live content from bleeding past the nav controller's edge into the tab bar.
        container.clipsToBounds = true
        let bounds = container.bounds

        var cardFrame: CGRect
        if let window = container.window {
            cardFrame = window.convert(sourceFrame, to: container)
        } else {
            cardFrame = sourceFrame
        }
        // No source frame captured — zoom from a centered rect instead of collapsing to a point.
        if cardFrame.isEmpty {
            cardFrame = bounds.insetBy(dx: bounds.width * 0.25, dy: bounds.height * 0.35)
        }

        // Uniform aspect-fill scale for the full-screen view while it sits inside the
        // card-sized portal, so its content is cropped to the card shape — never squashed.
        let fillScale = max(cardFrame.width / bounds.width, cardFrame.height / bounds.height)

        if operation == .push {
            animatePush(transitionContext, container: container, bounds: bounds,
                        cardFrame: cardFrame, fillScale: fillScale,
                        fromView: fromView, toView: toView)
        } else {
            animatePop(transitionContext, container: container, bounds: bounds,
                       cardFrame: cardFrame, fillScale: fillScale,
                       fromView: fromView, toView: toView)
        }
    }

    // A clipping container that holds the full-screen view during the transition.
    // Its frame animates between the card rect and full screen; the screen content
    // inside stays uniformly scaled and centered.
    private func makePortal(frame: CGRect, cornerRadius: CGFloat) -> UIView {
        let portal = UIView(frame: frame)
        portal.clipsToBounds = true
        portal.layer.cornerRadius = cornerRadius
        portal.layer.cornerCurve = .continuous
        return portal
    }

    // Opaque rounded rect that sits exactly behind the portal to cast its shadow
    // (the portal itself clips, so it can't render one). No shadowPath, so the
    // shadow tracks the frame/cornerRadius animation automatically.
    private func makeShadow(frame: CGRect, cornerRadius: CGFloat) -> UIView {
        let shadow = UIView(frame: frame)
        shadow.backgroundColor = .black
        shadow.layer.cornerRadius = cornerRadius
        shadow.layer.cornerCurve = .continuous
        shadow.layer.shadowColor = UIColor.black.cgColor
        shadow.layer.shadowOpacity = 0.35
        shadow.layer.shadowRadius = 24
        shadow.layer.shadowOffset = CGSize(width: 0, height: 12)
        return shadow
    }

    private func makeDim(bounds: CGRect, alpha: CGFloat) -> UIView {
        let dim = UIView(frame: bounds)
        dim.backgroundColor = .black
        dim.alpha = alpha
        return dim
    }

    private func animatePush(
        _ transitionContext: UIViewControllerContextTransitioning,
        container: UIView, bounds: CGRect, cardFrame: CGRect, fillScale: CGFloat,
        fromView: UIView, toView: UIView
    ) {
        ZoomTransitionContext.shared.lastPushSourceFrame = sourceFrame

        // Static backdrop matching fromView's real rendered content (not just its backgroundColor,
        // which is often nil on a UIHostingController). Covers the gap revealed while fromView
        // scales down, instead of showing the container's raw background.
        let backdrop = fromView.snapshotView(afterScreenUpdates: false)
        if let backdrop {
            backdrop.frame = fromView.frame
            container.insertSubview(backdrop, at: 0)
        }

        let dim = makeDim(bounds: bounds, alpha: 0)
        container.addSubview(dim)

        let shadow = makeShadow(frame: cardFrame, cornerRadius: cardCornerRadius)
        shadow.alpha = 0
        container.addSubview(shadow)

        let portal = makePortal(frame: cardFrame, cornerRadius: cardCornerRadius)
        container.addSubview(portal)

        toView.frame = bounds
        portal.addSubview(toView)
        toView.transform = CGAffineTransform(scaleX: fillScale, y: fillScale)
        toView.center = CGPoint(x: cardFrame.width / 2, y: cardFrame.height / 2)

        // The card's own pixels, overlaid on the portal so the card visibly morphs
        // into the destination rather than the destination popping in. Kept at the
        // card's natural size — stretching it with the growing portal magnifies the
        // card's content, which reads as the card blowing up.
        let cardSnapshot = fromView.resizableSnapshotView(from: cardFrame, afterScreenUpdates: false, withCapInsets: .zero)
        if let cardSnapshot {
            cardSnapshot.frame = CGRect(origin: .zero, size: cardFrame.size)
            portal.addSubview(cardSnapshot)
        }

        UIView.animate(withDuration: pushDuration * 0.22, delay: 0, options: .curveEaseOut) {
            cardSnapshot?.alpha = 0
        }
        UIView.animate(withDuration: pushDuration * 0.35, delay: 0, options: .curveEaseOut) {
            shadow.alpha = 1
        }

        UIView.animate(
            withDuration: pushDuration,
            delay: 0,
            usingSpringWithDamping: 0.86,
            initialSpringVelocity: 0.5,
            options: []
        ) {
            portal.frame = bounds
            portal.layer.cornerRadius = self.screenCornerRadius
            shadow.frame = bounds
            shadow.layer.cornerRadius = self.screenCornerRadius
            toView.transform = .identity
            toView.center = CGPoint(x: bounds.midX, y: bounds.midY)
            fromView.transform = CGAffineTransform(scaleX: self.backgroundScale, y: self.backgroundScale)
            dim.alpha = self.dimAlpha
        } completion: { _ in
            let cancelled = transitionContext.transitionWasCancelled
            toView.transform = .identity
            toView.frame = bounds
            container.addSubview(toView)
            portal.removeFromSuperview()
            shadow.removeFromSuperview()
            dim.removeFromSuperview()
            backdrop?.removeFromSuperview()
            fromView.transform = .identity
            if cancelled {
                toView.removeFromSuperview()
            }
            transitionContext.completeTransition(!cancelled)
        }
    }

    private func animatePop(
        _ transitionContext: UIViewControllerContextTransitioning,
        container: UIView, bounds: CGRect, cardFrame: CGRect, fillScale: CGFloat,
        fromView: UIView, toView: UIView
    ) {
        container.insertSubview(toView, belowSubview: fromView)
        toView.frame = bounds

        // The card's pixels in the destination, faded in near the end so the shrinking
        // screen visibly becomes the card again. afterScreenUpdates forces toView to
        // render first (it hasn't been on screen yet).
        let cardSnapshot = toView.resizableSnapshotView(from: cardFrame, afterScreenUpdates: true, withCapInsets: .zero)

        // Backdrop copy of the destination, covering the gap revealed while toView
        // animates up from its pushed-back scale. Captured before the transform is
        // applied — snapshots render bounds content, so the transform never leaks in.
        let backdrop = toView.snapshotView(afterScreenUpdates: true)
        if let backdrop {
            backdrop.frame = bounds
            container.insertSubview(backdrop, at: 0)
        }

        toView.transform = CGAffineTransform(scaleX: backgroundScale, y: backgroundScale)

        let dim = makeDim(bounds: bounds, alpha: dimAlpha)
        container.insertSubview(dim, aboveSubview: toView)

        let shadow = makeShadow(frame: bounds, cornerRadius: screenCornerRadius)
        container.addSubview(shadow)

        let portal = makePortal(frame: bounds, cornerRadius: screenCornerRadius)
        container.addSubview(portal)

        fromView.frame = bounds
        portal.addSubview(fromView)

        // Natural size, centered in the portal, riding its shrink — keeps the card
        // pixels glued to the shrinking screen instead of stretching (magnifies) or
        // sitting parked at the destination (screen visibly collapses onto it).
        if let cardSnapshot {
            cardSnapshot.frame = CGRect(origin: .zero, size: cardFrame.size)
            cardSnapshot.center = CGPoint(x: bounds.midX, y: bounds.midY)
            cardSnapshot.alpha = 0
            portal.addSubview(cardSnapshot)
        }

        UIView.animate(withDuration: popDuration * 0.4, delay: popDuration * 0.45, options: .curveEaseIn) {
            cardSnapshot?.alpha = 1
        }

        UIView.animate(withDuration: popDuration * 0.4, delay: popDuration * 0.55, options: .curveEaseIn) {
            shadow.alpha = 0
        }

        UIView.animate(
            withDuration: popDuration,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.3,
            options: []
        ) {
            portal.frame = cardFrame
            portal.layer.cornerRadius = self.cardCornerRadius
            shadow.frame = cardFrame
            shadow.layer.cornerRadius = self.cardCornerRadius
            fromView.transform = CGAffineTransform(scaleX: fillScale, y: fillScale)
            fromView.center = CGPoint(x: cardFrame.width / 2, y: cardFrame.height / 2)
            cardSnapshot?.center = CGPoint(x: cardFrame.width / 2, y: cardFrame.height / 2)
            toView.transform = .identity
            dim.alpha = 0
        } completion: { _ in
            let cancelled = transitionContext.transitionWasCancelled
            fromView.transform = .identity
            fromView.frame = bounds
            container.addSubview(fromView)
            portal.removeFromSuperview()
            shadow.removeFromSuperview()
            dim.removeFromSuperview()
            backdrop?.removeFromSuperview()
            toView.transform = .identity
            if cancelled {
                toView.removeFromSuperview()
            }
            transitionContext.completeTransition(!cancelled)
            if !cancelled {
                DispatchQueue.main.async {
                    ZoomTransitionContext.shared.onPopCompleted?()
                    ZoomTransitionContext.shared.onPopCompleted = nil
                }
            }
        }
    }
}
#endif
