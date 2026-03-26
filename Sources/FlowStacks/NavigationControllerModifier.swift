import SwiftUI

#if os(iOS)
import UIKit

struct NavigationControllerModifier: ViewModifier {
    let delegate: CustomNavigationControllerDelegate
    let useLeftToRightForPush: Bool
    let useLeftToRightForPop: Bool

    func body(content: Content) -> some View {
        content
            .background(NavigationControllerAccessor(delegate: delegate, useLeftToRightForPush: useLeftToRightForPush, useLeftToRightForPop: useLeftToRightForPop))
    }
}

struct NavigationControllerAccessor: UIViewControllerRepresentable {
    let delegate: CustomNavigationControllerDelegate
    let useLeftToRightForPush: Bool
    let useLeftToRightForPop: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        delegate.useLeftToRightForPush = useLeftToRightForPush
        delegate.useLeftToRightForPop = useLeftToRightForPop
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
    func customNavigationTransition(useLeftToRightForPush: Bool, useLeftToRightForPop: Bool) -> some View {
        #if os(iOS)
        let delegate = CustomNavigationControllerDelegate()
        return self.modifier(NavigationControllerModifier(delegate: delegate, useLeftToRightForPush: useLeftToRightForPush, useLeftToRightForPop: useLeftToRightForPop))
        #else
        return self
        #endif
    }
}
