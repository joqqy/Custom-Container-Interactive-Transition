//
//  TransitionDriver.swift
//  custom_vc_transitions
//
//  Created by Mikael Hanna on 2022-11-06.
//

import UIKit

class TransitionDriver: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning {
    
    weak var timer: Timer?
//    let velocityThreshold: CGFloat = 600.0
//    let fractionCompleteLimit: CGFloat = 0.95
    var latestVelocity: CGPoint = .zero
    var goingRight: Bool = false
    let velocitySwipeThreshold: CGFloat = 2000.0
    
    var transitionContext: UIViewControllerContextTransitioning!
    private var propertyAnimator: UIViewPropertyAnimator?
    var panGestureRecongnizer: UIPanGestureRecognizer!
    var progressAtTouchBegin: CGFloat = 0.0
    
    private let originFrame: CGRect
    
    private let kCChildViewPadding: CGFloat = 16
    
    init(originFrame: CGRect, panGesture: UIPanGestureRecognizer) {

        self.originFrame = originFrame
        self.panGestureRecongnizer = panGesture
        
        super.init()
    }

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        
        //print(#function)

        self.transitionContext = transitionContext
        
        // Get the animator
        let animator = interruptibleAnimator(using: transitionContext)

        // Set state of the animator
        if transitionContext.isInteractive {
            animator.pauseAnimation()
        } else {
            animator.startAnimation()
            transitionContext.pauseInteractiveTransition()
        }
        
        // Add action to gesture recognizer to the container view
        transitionContext.containerView.addGestureRecognizer(self.panGestureRecongnizer)
        self.panGestureRecongnizer.addTarget(self, action: #selector(handleGesture(_:)))
    }
    
    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {

        // About the guard statement below:
        // as per documentation, we need to return existing animator
        // for ongoing transition
        
        // Note however, when we use modal presentation, for some reason, UIKit calls this twice, so we
        // need this guard. However, we noticed, for our own custom container transition, this will
        // only be called once(since we are managing everything, so then this guard is not needed).
        
        // I am not sure why UIKit calls this twice during presentations or dismissals, seems like a bug to me.
        
        /*
        if let propertyAnimator = propertyAnimator {
            return propertyAnimator
        }
         */
        
        guard let toViewController = transitionContext.viewController(forKey: .to),
              let fromViewController = transitionContext.viewController(forKey: .from),
              let toView = transitionContext.view(forKey: .to),
              let fromView = transitionContext.view(forKey: .from) else {
            fatalError()
        }
        
        transitionContext.containerView.addSubview(toView)
        
        // When sliding the views horizontally, in and out, figure out whether we are going left or right.
        let goingRight: Bool = transitionContext.initialFrame(for: toViewController).origin.x < transitionContext.finalFrame(for: toViewController).origin.x
        self.goingRight = goingRight
        
        let travelDistance = transitionContext.containerView.bounds.size.width + self.kCChildViewPadding
        let travel: CGAffineTransform = CGAffineTransform.init(translationX: goingRight ? travelDistance : -travelDistance, y: 0)
        
        // Add view to container
        transitionContext.containerView.addSubview(toViewController.view)
        // Some other settings
        //toViewController.view.alpha = 0
        toViewController.view.transform = travel.inverted()
        
        // Note that when using spring dynamics, duration will be ignored.
        let duration = transitionDuration(using: transitionContext)
        //let timingParameters = UICubicTimingParameters(animationCurve: .easeOut)
        // see: https://devstreaming-cdn.apple.com/videos/wwdc/2016/216v55u6zpxizxkml6k/216/216_hd_advances_in_uikit_animations_and_transitions.mp4  at 20:30
        //let timingCubic = UICubicTimingParameters(controlPoint1: CGPoint(x: 0, y: 1), controlPoint2: CGPoint(x: 0.1, y: 1.0))
        let mass: CGFloat = 0.05
        let stiffness: CGFloat = 12.0
        let damping: CGFloat = 1.0
        let initialVelocity = CGVector(dx: 1, dy: 0)
        let timingSpring = UISpringTimingParameters(mass: mass, stiffness: stiffness, damping: damping, initialVelocity: initialVelocity)
        let animator = UIViewPropertyAnimator(duration: duration, timingParameters: timingSpring)
        animator.isUserInteractionEnabled = true // UIKit default: true
        animator.isInterruptible = true
        
        animator.addAnimations {

            fromViewController.view.transform = travel
            //fromViewController.view.alpha = 0
            
            toViewController.view.transform = .identity
            //toViewController.view.alpha = 1
        }
        
        animator.addCompletion { (position) in
            
            let didComplete = (position == .end)
            transitionContext.completeTransition(didComplete)
            if didComplete {
                fromView.removeFromSuperview()
            }
        }
        
        self.propertyAnimator = animator
        return animator
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        if transitionCompleted {
            self.panGestureRecongnizer.removeTarget(self, action: #selector(handleGesture(_:)))
        }
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        // Will be ignored if we use spring dynamics
        return 1.0
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.startInteractiveTransition(transitionContext)
    }

    @objc func handleGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        guard
            let animator = self.propertyAnimator,
            let fromVCView = transitionContext.view(forKey: .from) else { return }
        
        switch gestureRecognizer.state
        {
        case .began:
            animator.pauseAnimation()
            animator.isReversed = false
            self.progressAtTouchBegin = animator.fractionComplete

        case .changed:
            // Get and store velocity
            let velocity = gestureRecognizer.velocity(in: fromVCView)
            latestVelocity = velocity
            
            // Calculate the progress to update
            let translation = gestureRecognizer.translation(in: fromVCView)
            let dx: CGFloat = translation.x/transitionContext.containerView.bounds.width
            let progressUpdate: CGFloat = progressAtTouchBegin + (goingRight ? dx : -dx)

            animator.fractionComplete = progressUpdate
            self.transitionContext.updateInteractiveTransition(progressUpdate)
            
            //print("fractionComplete: \(animator.fractionComplete)")
            
        case .ended, .cancelled:
            
            // ///////////////////////////
            transitionContext.pauseInteractiveTransition()
            if animator.fractionComplete > 0.5 || abs(latestVelocity.x) > velocitySwipeThreshold {
                
                if goingRight {
                    
                    if latestVelocity.x < 0 {
                        animator.isReversed = true
                        animator.startAnimation()
                        //print("V LeftToRightSwipe.1")
                        
                    } else {
                        animator.startAnimation()
                        //print("V LeftToRightSwipe.2")
                    }
                    
                } else if !goingRight {
                    
                    if latestVelocity.x > 0 {
                        animator.isReversed = true
                        animator.startAnimation()
                        //print("V RightToLeftSwipe.1")
                        
                    } else {
                        animator.startAnimation()
                        //print("V RightToLeftSwipe.2")
                    }
                }
                
            } else {
                animator.isReversed = true
                animator.startAnimation()
            }
            transitionContext.finishInteractiveTransition()
            break
            // ///////////////////////////

            /*
            if latestVelocity.x > velocityThreshold /*&& fractionComplete <= fractionCompleteLimit*/ {
                
                if latestVelocity.x > 2300 {
                    startTimer(false)
                    propertyAnimator?.stopAnimation(false)
                    propertyAnimator?.finishAnimation(at: .end)
                    transitionContext.finishInteractiveTransition()
                } else {
                    startTimer(true)
                    // Note, in the .begin the animation is set to isReversed = false, so no need to do it here
                    propertyAnimator?.startAnimation()
                }

            } else if latestVelocity.x < -velocityThreshold {
                
                if latestVelocity.x < -2300 {
                    startTimer(false)
                    propertyAnimator?.stopAnimation(false)
                    propertyAnimator?.finishAnimation(at: .end)
                    transitionContext.finishInteractiveTransition()
                } else {
                    propertyAnimator?.isReversed = true
                    propertyAnimator?.startAnimation()
                }
            }
            gestureRecognizer.setTranslation(.zero, in: nil)
             */
        default:
            break
        }
    }
    
    // There is no way to dynamically observe UIViewPropertyAnimator.fractionComplete
    // For now, the only solution is to use CADisplayLink or a Timer
    // See here: https://stackoverflow.com/questions/41052439/is-there-a-way-to-observe-changes-to-fractioncomplete-in-uiviewpropertyanimator
    func startTimer(_ start: Bool) {
      if start {
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            let value = Float(self.propertyAnimator?.fractionComplete ?? 0.0)
//            if value >= Float(self.fractionCompleteLimit) {
//                self.propertyAnimator?.pauseAnimation()
//                self.transitionContext.pauseInteractiveTransition()
//                self.timer?.invalidate()
//            }
        }
      }
      else {
        self.timer?.invalidate()
      }
    }
}
