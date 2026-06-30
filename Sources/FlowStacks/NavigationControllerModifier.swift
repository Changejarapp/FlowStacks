import SwiftUI

#if os(iOS)
import UIKit

struct NavigationControllerModifier: ViewModifier {
    let delegate: CustomNavigationControllerDelegate
    let useLeftToRightForPush: Bool
    let useLeftToRightForPop: Bool
    let useZoomForPush: Bool
    let useZoomForPop: Bool

    func body(content: Content) -> some View {
        content
            .background(NavigationControllerAccessor(
                delegate: delegate,
                useLeftToRightForPush: useLeftToRightForPush,
                useLeftToRightForPop: useLeftToRightForPop,
                useZoomForPush: useZoomForPush,
                useZoomForPop: useZoomForPop
            ))
    }
}

struct NavigationControllerAccessor: UIViewControllerRepresentable {
    let delegate: CustomNavigationControllerDelegate
    let useLeftToRightForPush: Bool
    let useLeftToRightForPop: Bool
    let useZoomForPush: Bool
    let useZoomForPop: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        delegate.useLeftToRightForPush = useLeftToRightForPush
        delegate.useLeftToRightForPop = useLeftToRightForPop
        delegate.useZoomForPush = useZoomForPush
        delegate.useZoomForPop = useZoomForPop
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
        useZoomForPop: Bool
    ) -> some View {
        #if os(iOS)
        let delegate = CustomNavigationControllerDelegate()
        return self.modifier(NavigationControllerModifier(
            delegate: delegate,
            useLeftToRightForPush: useLeftToRightForPush,
            useLeftToRightForPop: useLeftToRightForPop,
            useZoomForPush: useZoomForPush,
            useZoomForPop: useZoomForPop
        ))
        #else
        return self
        #endif
    }
}
