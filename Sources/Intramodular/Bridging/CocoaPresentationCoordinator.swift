//
// Copyright (c) Vatsal Manot
//

import Swift
import SwiftUI

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)

class CocoaPresentationCoordinator: NSObject {
    private var presentation: CocoaPresentation?
    private var transitioningDelegate: UIViewControllerTransitioningDelegate?
    
    private weak var presentingCoordinator: CocoaPresentationCoordinator?
    
    var onDidAttemptToDismiss: [CocoaPresentation.DidAttemptToDismissCallback] = []
    
    weak var viewController: UIViewController? {
        didSet {
            viewController?.presentationController?.delegate = self
        }
    }
    
    var presentedCoordinator: CocoaPresentationCoordinator?
    
    override init() {
        self.presentation = nil
        self.presentingCoordinator = nil
    }
    
    init(
        presentation: CocoaPresentation? = nil,
        presentingCoordinator: CocoaPresentationCoordinator? = nil
    ) {
        self.presentation = presentation
        self.presentingCoordinator = presentingCoordinator
    }
    
    func present(_ presentation: CocoaPresentation) {
        if let viewController = viewController?.presentedViewController as? CocoaHostingController<AnyView>, viewController.modalViewPresentationStyle == presentation.style {
            viewController.rootViewContent = presentation.content()
            
            return
        }
        
        presentedCoordinator?.dismissSelf()
        
        let presentationCoordinator = CocoaPresentationCoordinator(
            presentation: presentation,
            presentingCoordinator: self
        )
        
        let viewController = CocoaHostingController(
            presentation: presentation,
            presentationCoordinator: presentationCoordinator
        )
        
        presentedCoordinator = presentationCoordinator
        
        self.viewController?.present(viewController, animated: true)
    }
    
    func dismissSelf() {
        guard let presentation = presentation, presentation.shouldDismiss() else {
            return
        }
        
        guard let presentingCoordinator = presentingCoordinator, presentingCoordinator.presentedCoordinator === self else {
            return
        }
        
        presentingCoordinator.dismissPresentedView()
    }
    
    func dismissPresentedView() {
        guard let presentedCoordinator = presentedCoordinator, let presentation = presentedCoordinator.presentation else {
            return
        }
        
        presentedCoordinator.viewController?.dismiss(animated: true)
        presentedCoordinator.viewController = nil
        
        self.presentedCoordinator = nil
        
        if !presentation.shouldDismiss() {
            presentation.resetBinding()
        }
        
        presentation.onDismiss?()
    }
}

// MARK: - Protocol Implementations -

extension CocoaPresentationCoordinator: DynamicViewPresenter {
    public func present<V: View>(
        _ view: V,
        onDismiss: (() -> Void)?,
        style: ModalViewPresentationStyle
    ) {
        present(CocoaPresentation(
            content: { view.eraseToAnyView() },
            onDismiss: onDismiss,
            shouldDismiss: { true },
            resetBinding: { },
            style: style
        ))
    }
}

extension CocoaPresentationCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        for callback in onDidAttemptToDismiss {
            callback.action()
        }
    }
    
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        dismissSelf()
    }
}

#endif

