import SwiftUI

#if os(iOS)
import UIKit

struct NavigationControllerModifier: ViewModifier {
    let delegate: CustomNavigationControllerDelegate
    let useLeftToRightForPush: Bool
    let useLeftToRightForPop: Bool
    let useZoomForPush: Bool
    let useZoomForPop: Bool
    let useBottomToTopForPush: Bool
    let useBottomToTopForPop: Bool

    func body(content: Content) -> some View {
        content
            .background(NavigationControllerAccessor(
                delegate: delegate,
                useLeftToRightForPush: useLeftToRightForPush,
                useLeftToRightForPop: useLeftToRightForPop,
                useZoomForPush: useZoomForPush,
                useZoomForPop: useZoomForPop,
                useBottomToTopForPush: useBottomToTopForPush,
                useBottomToTopForPop: useBottomToTopForPop
            ))
    }
}

struct NavigationControllerAccessor: UIViewControllerRepresentable {
    let delegate: CustomNavigationControllerDelegate
    let useLeftToRightForPush: Bool
    let useLeftToRightForPop: Bool
    let useZoomForPush: Bool
    let useZoomForPop: Bool
    let useBottomToTopForPush: Bool
    let useBottomToTopForPop: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        delegate.useLeftToRightForPush = useLeftToRightForPush
        delegate.useLeftToRightForPop = useLeftToRightForPop
        delegate.useZoomForPush = useZoomForPush
        delegate.useZoomForPop = useZoomForPop
        delegate.useBottomToTopForPush = useBottomToTopForPush
        delegate.useBottomToTopForPop = useBottomToTopForPop
        if let navigationController = uiViewController.navigationController {
            navigationController.delegate = delegate
        } else {
            DispatchQueue.main.async {
                if let navigationController = uiViewController.navigationController {
                    navigationController.delegate = delegate
                }
            }
        }
    }
}
#endif

extension View {
    func customNavigationTransition(
        useLeftToRightForPush: Bool,
        useLeftToRightForPop: Bool,
        useZoomForPush: Bool,
        useZoomForPop: Bool,
        useBottomToTopForPush: Bool,
        useBottomToTopForPop: Bool
    ) -> some View {
        #if os(iOS)
        let delegate = CustomNavigationControllerDelegate()
        return self.modifier(NavigationControllerModifier(
            delegate: delegate,
            useLeftToRightForPush: useLeftToRightForPush,
            useLeftToRightForPop: useLeftToRightForPop,
            useZoomForPush: useZoomForPush,
            useZoomForPop: useZoomForPop,
            useBottomToTopForPush: useBottomToTopForPush,
            useBottomToTopForPop: useBottomToTopForPop
        ))
        #else
        return self
        #endif
    }
}
