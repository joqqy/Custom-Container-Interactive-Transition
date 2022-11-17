//
//  Pr_TransitionDelegate.swift
//  custom_transitions_presentations_with_ContainverVC
//
//  Created by Mikael Hanna on 2022-11-09.
//

import UIKit

protocol ContainerVCTransitionDelegate: AnyObject {
    
    func animationControllerForTransition(from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning?
    
    func selectVCandTransition(_ selectedVC: UIViewController) -> Void
}
