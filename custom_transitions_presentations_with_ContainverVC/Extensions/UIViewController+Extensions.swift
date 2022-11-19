//
//  UIViewController+Extensions.swift
//  child_viewcontrollers
//
//  Created by Mikael Hanna on 2022-11-04.
//

import UIKit

extension UIViewController {
    
    /// Call this on parent to add a child view controller
    func add(_ child: UIViewController) -> Void {
        
        self.addChild(child)
        self.view.addSubview(child.view)
        
        // Add constraints here
        // ...
        child.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        child.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        child.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        child.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        
        child.didMove(toParent: self)
    }
    
    /// Call this on child view controller to remove itself from its parent
    func remove() {
        guard parent != nil else { return }
        
        self.willMove(toParent: nil)
        
        // Deactivate any constraints
        // ...
        
        self.view.removeFromSuperview()
        self.removeFromParent()
    }
}
