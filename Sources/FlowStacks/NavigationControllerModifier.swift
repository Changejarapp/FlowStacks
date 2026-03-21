import SwiftUI

#if os(iOS)
import UIKit

struct NavigationControllerModifier: ViewModifier {
    let delegate: CustomNavigationControllerDelegate
    let useCustomTransition: Bool

    func body(content: Content) -> some View {
        content
            .background(NavigationControllerAccessor(delegate: delegate, useCustomTransition: useCustomTransition))
    }
}

struct NavigationControllerAccessor: UIViewControllerRepresentable {
    let delegate: CustomNavigationControllerDelegate
    let useCustomTransition: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        delegate.shouldUseCustomTransition = useCustomTransition
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
    func customNavigationTransition(enabled: Bool = true) -> some View {
        #if os(iOS)
        let delegate = CustomNavigationControllerDelegate()
        return self.modifier(NavigationControllerModifier(delegate: delegate, useCustomTransition: enabled))
        #else
        return self
        #endif
    }
}
