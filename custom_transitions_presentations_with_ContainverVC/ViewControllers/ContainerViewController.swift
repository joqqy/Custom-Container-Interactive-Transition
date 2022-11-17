//
//  ViewController.swift
//  custom_transitions_presentations_with_ContainverVC
//
//  Created by Mikael Hanna on 2022-11-08.
//

import UIKit

// References:

// This is the objc tutorial for how to do custom container transitions
// https://www.objc.io/issues/12-animations/custom-container-view-controller-transitions/
// iOS 10 gave us UIViewPropertyAnimator, and so we can use that in place of
// UIPercentDrivenInteractiveTransition(which would not work here, the app would crash).

// However, we can instead conform to UIViewControllerInteractiveTransitioning and drive the interactive
// transition by using an interruptible UIViewPropertyAnimator.

// This means we have to create our own transition context, but be WARNED:
// WARNING, Apple says we should not adopt this protocol for our own classes or directly creating objects that adopt this protocol. So we are treading on
// thin ice here. Though it works, things can and may break in the future.

// Here is some other useful info:

// Customizing the Transition Animations: https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/CustomizingtheTransitionAnimations.html#//apple_ref/doc/uid/TP40007457-CH16-SW1

// Creating Custom Presentations: https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/DefiningCustomPresentations.html#//apple_ref/doc/uid/TP40007457-CH25-SW1

import UIKit

class ContainerViewController: UIViewController {
    
    private var transitionDriver: TransitionDriver?
    private var fireTransitionGesture: UIPanGestureRecognizer?
    
    var viewControllers: Array<UIViewController> = []
    var selectedViewController: UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // Let's init all our children vcs upfront
        self.viewControllers = [VC1(title: "Child VC 1", color: .green),
                                VC1(title: "Child VC 2", color: .cyan),
                                VC1(title: "Child VC 3", color: .magenta),
                                VC1(title: "Child VC 4", color: .orange),]
        // Set the initial the starting child
        let startingIndex = 1
        self.selectedViewController = self.viewControllers[startingIndex < self.viewControllers.count ? startingIndex : 0]
        // Add the initial child to the container hierarchy of children
        self.add(self.selectedViewController!)

        self.fireTransitionGesture = UIPanGestureRecognizer(target: self, action: #selector(gestureInitTransition(_:)))
        self.view.addGestureRecognizer(self.fireTransitionGesture!)
    }
    
    override func viewDidLayoutSubviews() {
        
        self.view.topAnchor.constraint(equalTo: self.view.superview!.topAnchor).isActive = true
        self.view.bottomAnchor.constraint(equalTo: self.view.superview!.bottomAnchor).isActive = true
        self.view.leadingAnchor.constraint(equalTo: self.view.superview!.leadingAnchor).isActive = true
        self.view.trailingAnchor.constraint(equalTo: self.view.superview!.trailingAnchor).isActive = true
    }
    
    func selectVCandTransition(_ selectedVC: UIViewController) -> Void {
        self.selectedViewController = selectedVC
        self.transitionToChildVC(toViewController: selectedVC)
    }

    @objc func gestureInitTransition(_ gesture: UIPanGestureRecognizer) {
        
        // If there is more than 1 child, then a transition is currently in progress.
        // So we have to wait until the transition is finished.
        // At the end of the transition there should be only 1 child in the children remaining.
        guard children.count == 1 else { return }

        let isInteractive: Bool
        if let tdriver = transitionDriver {
            isInteractive = tdriver.transitionContext.isInteractive
        } else {
            isInteractive = false
        }

        if !isInteractive {
            
            // Get the currently selected view controller (the on that is currently on display)
            let currentVCIndex = self.viewControllers.firstIndex(of: self.selectedViewController!)!
            
            // Which direction is the user swiping?
            let leftToRight: Bool = gesture.velocity(in: gesture.view).x > 0

            var nextIDX: Int?
            // We go forward, meaning finger was swiped right to left
            if !leftToRight && currentVCIndex != self.viewControllers.count-1 {
                nextIDX = currentVCIndex + 1

            // We go backward, meaning finger was swiped left to right
            } else if leftToRight && currentVCIndex > 0 {
                nextIDX = currentVCIndex - 1
            }

            //print("currIDX:                     \(currIDX)")
            //print("nextIDX:                     \(nextIDX)")
            //print("children.count BEFORE:       \(self.children.count)")
            
            // Make the newly selected view controller the one we want to transition to, then do the transitoin
            if let nextIDX = nextIDX {
                self.selectVCandTransition(self.viewControllers[nextIDX])
            }
            //print("children.count AFTER:        \(self.children.count)\n")
        }
    }

    private func transitionToChildVC(toViewController: UIViewController) -> Void {
  
        // For this particular implementation, at this stage, when we will do the transition,
        // there should only be one child present, the fromViewController. So we try to fetch it.
        // This vc will transition away to make place for the toViewController.
        guard self.children.count > 0 else { return }
        let fromViewController = self.children[0]
        // Make sure that fromVC is not the same as the toVC
        if toViewController === fromViewController { return }
        
        // Get the vc's resp. indices (we need this info to decide in which x direction the transition will occur)
        guard
            let fromIndex = self.viewControllers.firstIndex(of: fromViewController),
            let toIndex = self.viewControllers.firstIndex(of: toViewController) else {
            return
        }

        // MARK: - Get a fresh Animator object driver
        guard let transitionDriver = self.animationControllerForTransition(from: fromViewController,
                                                                           to: toViewController) else {
            return
        }
        // MARK: - Create the transition context object
        // Because of the nature of our view controller, with horizontally arranged buttons, we instantiate our private transition context with information about whether this is a left-to-right or right-to-left transition. The animator can use this information if it wants.
        let transitionContext: PrivateTransitionContext = PrivateTransitionContext(fromVC: fromViewController,
                                                                                   toVC: toViewController,
                                                                                   goingRight: toIndex < fromIndex)

        // Prepare to remove the fromVC
        fromViewController.willMove(toParent: nil)
        // Add the toVC
        self.add(toViewController)
        
        // At this point, children will contain 2 view controllers.
        // 1. The one we will remove
        // 2. The one we will transition to
        
        // After the transition is complete, children will once more only contain 1 view controller, namely the one we transitioned to and is now displayed.
        
        // If the transition is not completed, then we will remove the toVC and keep the fromVC as the only child.
        
        transitionContext.completionBlock = { [weak self] (didComplete: Bool) -> Void in
            guard let self = self else { return }
            
            // Cleanup
            if didComplete {
                // Animator completed, so it is now safe to remove the vc from the hierarchy
                fromViewController.remove()
            } else {
                // Animator did not complete, so remove the vc we just added.
                toViewController.remove()
                // Revert back to the old selected vc
                self.selectedViewController = fromViewController
            }
            
            transitionDriver.animationEnded?(didComplete)
            //print("Count after completion: \(self.children.count)") // Always 1 for now
        }

        transitionContext.isAnimated = true
        transitionContext.isInteractive = true
        // Call Animator method explicitly. This will in turn call startInteractiveTransition(_:)
        transitionDriver.animateTransition(using: transitionContext)
    }
}

// ContainerViewControllerDelegate is our own protocol, similar to UIKit's UIViewControllerTransitioningDelegate, or rather UINavigationControllerDelegate
extension ContainerViewController: ContainerVCTransitionDelegate, UIViewControllerTransitioningDelegate {
    
    func animationControllerForTransition(from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning? {
 
        self.transitionDriver = TransitionDriver(originFrame: self.view.frame, panGesture: self.fireTransitionGesture!)
        return transitionDriver
    }
}
