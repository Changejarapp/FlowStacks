import SwiftUI

#if os(iOS)
import UIKit

class CustomNavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
    var useLeftToRightForPush: Bool = false
    var useLeftToRightForPop: Bool = false

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
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
#endif
