import SwiftUI

#if os(iOS)
import UIKit

class CustomNavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
    var useLeftToRightForPush: Bool = false
    var useLeftToRightForPop: Bool = false
    var useZoomForPush: Bool = false
    var useZoomForPop: Bool = false

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .push where useZoomForPush:
            let frame = ZoomTransitionContext.shared.sourceFrame
            return ZoomTransition(operation: operation, sourceFrame: frame)
        case .pop where useZoomForPop:
            return ZoomTransition(operation: operation, sourceFrame: ZoomTransitionContext.shared.lastPushSourceFrame)
        case .push where useLeftToRightForPush:
            return LeftToRightTransition(operation: operation)
        case .pop where useLeftToRightForPop:
            return LeftToRightTransition(operation: operation)
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

class ZoomTransition: NSObject, UIViewControllerAnimatedTransitioning {
    let operation: UINavigationController.Operation
    let sourceFrame: CGRect

    private let pushDuration: TimeInterval = 0.42
    private let popDuration: TimeInterval = 0.32
    private let cardCornerRadius: CGFloat = 16

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
        let bounds = container.bounds

        let convertedFrame: CGRect
        if let window = container.window {
            convertedFrame = window.convert(sourceFrame, to: container)
        } else {
            convertedFrame = sourceFrame
        }

        // Transform that maps a full-screen view down to the source card's frame.
        // Uses scale + translate so Auto Layout is never touched (no frame animation).
        let sx = convertedFrame.width / bounds.width
        let sy = convertedFrame.height / bounds.height
        let tx = convertedFrame.midX - bounds.midX
        let ty = convertedFrame.midY - bounds.midY
        let zoomedOut = CGAffineTransform(translationX: tx, y: ty).scaledBy(x: sx, y: sy)

        if operation == .push {
            ZoomTransitionContext.shared.lastPushSourceFrame = sourceFrame

            container.addSubview(toView)
            toView.frame = bounds
            toView.transform = zoomedOut
            toView.alpha = 0.4
            toView.clipsToBounds = true
            toView.layer.cornerRadius = cardCornerRadius

            UIView.animate(
                withDuration: pushDuration,
                delay: 0,
                usingSpringWithDamping: 0.88,
                initialSpringVelocity: 0.2,
                options: []
            ) {
                toView.transform = .identity
                toView.alpha = 1
                toView.layer.cornerRadius = self.screenCornerRadius
                fromView.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
                fromView.alpha = 0.9
            } completion: { _ in
                fromView.transform = .identity
                fromView.alpha = 1
                toView.clipsToBounds = false
                toView.layer.cornerRadius = 0
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }

        } else if operation == .pop {
            container.insertSubview(toView, belowSubview: fromView)
            toView.frame = bounds
            // toView is already at .identity — push completion resets it before removal.
            // Don't touch toView so card positions stay stable and fromView lands exactly.
            fromView.clipsToBounds = true
            // Start at the device screen radius so it matches the normal full-screen appearance.
            fromView.layer.cornerRadius = screenCornerRadius

            UIView.animate(
                withDuration: popDuration,
                delay: 0,
                options: .curveEaseIn
            ) {
                fromView.transform = zoomedOut
                fromView.layer.cornerRadius = self.cardCornerRadius
            } completion: { _ in
                let cancelled = transitionContext.transitionWasCancelled
                if cancelled {
                    // Only reset state if the transition was cancelled — otherwise
                    // resetting before completeTransition causes a one-frame snap to full-screen.
                    fromView.transform = .identity
                    fromView.layer.cornerRadius = 0
                    fromView.clipsToBounds = false
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
}
#endif
