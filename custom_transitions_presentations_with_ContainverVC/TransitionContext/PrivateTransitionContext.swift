//
//  PrivateTransitionContext.swift
//  custom_transitions_presentations_with_ContainverVC
//
//  Created by Mikael Hanna on 2022-11-09.
//

import UIKit

/*
 WARNING, Apple says we should not adopt this protocol for our own classes or directly creating objects that adopt this protocol. So we are treading on
 thin ice here. Though it works, things can and may break in the future.
 
 https://developer.apple.com/documentation/uikit/uiviewcontrollercontexttransitioning
 
 Apple says:
 
 Don’t adopt this protocol in your own classes, nor should you directly create objects that adopt this protocol. During a transition, the animator objects involved in that transition receive a fully configured context object from UIKit. Custom animator objects — objects that adopt the UIViewControllerAnimatedTransitioning or UIViewControllerInteractiveTransitioning protocol — should simply retrieve the information they need from the provided object.

 A context object encapsulates information about the views and view controllers involved in the transition. It also contains details about the how to execute the transition. For interactive transitions, the interactive animator object uses the methods of this protocol to report the animation’s progress. When the animation starts, the interactive animator object must save a pointer to the context object. Based on user interactions, the animator object then calls the updateInteractiveTransition(_:), finishInteractiveTransition(), or cancelInteractiveTransition() methods to report the progress toward completing the animation. Those methods send that information to UIKit so that it can drive the timing of the animations.
 */

class PrivateTransitionContext: NSObject, UIViewControllerContextTransitioning {
    
    var containerView: UIView
    
    var isAnimated: Bool
    
    var isInteractive: Bool
    
    var transitionWasCancelled: Bool
    
    var presentationStyle: UIModalPresentationStyle
    
    var viewControllers: [UITransitionContextViewControllerKey : UIViewController]
    var views: [UITransitionContextViewKey : UIView]
    var travelDistance: CGFloat
    var disappearingFromRect: CGRect
    var disappearingToRect: CGRect
    var appearingToRect: CGRect
    var appearingFromRect: CGRect
    
    init(fromVC: UIViewController, toVC: UIViewController, goingRight: Bool) {
        
        self.presentationStyle = .custom
        self.containerView = fromVC.view.superview!
        self.viewControllers = [.from : fromVC, .to : toVC]
        self.views = [.from : fromVC.view, .to : toVC.view]
        self.travelDistance = (goingRight) ? -self.containerView.bounds.size.width : self.containerView.bounds.size.width
        
        self.disappearingFromRect = self.containerView.bounds
        self.appearingToRect = self.containerView.bounds
        self.disappearingToRect = self.containerView.bounds.offsetBy(dx: travelDistance, dy: 0)
        self.appearingFromRect = self.containerView.bounds.offsetBy(dx: -travelDistance, dy: 0)
        
        isAnimated = true
        isInteractive = true
        transitionWasCancelled = false
        targetTransform = .identity
        
        super.init()
    }
    
    func updateInteractiveTransition(_ percentComplete: CGFloat) {
        isInteractive = true
        isAnimated = false
    }
    
    func finishInteractiveTransition() {
        isInteractive = false
    }
    
    func cancelInteractiveTransition() {
        isInteractive = false
        transitionWasCancelled = true
    }
    
    func pauseInteractiveTransition() {
        isInteractive = false
    }
    
    var completionBlock: ((Bool) -> Void)?
    func completeTransition(_ didComplete: Bool) {
        completionBlock?(didComplete)
    }
    
    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        return viewControllers[key]
    }
    
    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        return views[key]
    }
    
    var targetTransform: CGAffineTransform
    
    func initialFrame(for vc: UIViewController) -> CGRect {
 
        if vc == viewController(forKey: .from) {
            return self.disappearingToRect
        } else {
            return self.appearingToRect
        }
    }
    
    func finalFrame(for vc: UIViewController) -> CGRect {
        
        if vc == viewController(forKey: .from) {
            return self.disappearingFromRect
        } else {
            return self.appearingFromRect
        }
    }
}
