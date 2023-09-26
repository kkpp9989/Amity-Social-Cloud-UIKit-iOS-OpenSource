//
//  AmityChatHomeParentViewController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 26/9/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

public class AmityChatHomeParentViewController: AmityViewController {
    
    var currentChildViewController: UIViewController?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = AmityLocalizedStringSet.chatTitle.localizedString

        // Load the initial child view controller
        if AmityUIKitManagerInternal.shared.client != nil {
            let amityChatHomePageViewController = AmityChatHomePageViewController.make()
            switchToChildViewController(childViewController: amityChatHomePageViewController)
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Load the initial child view controller
        if AmityUIKitManagerInternal.shared.client != nil {
            let amityChatHomePageViewController = AmityChatHomePageViewController.make()
            switchToChildViewController(childViewController: amityChatHomePageViewController)
        }
    }
    
    func switchToChildViewController(childViewController: AmityViewController) {
        // Remove the current child view controller (if any)
        if let currentChildViewController = currentChildViewController {
            currentChildViewController.willMove(toParent: nil)
            currentChildViewController.view.removeFromSuperview()
            currentChildViewController.removeFromParent()
        }
        
        // Add the new child view controller
        addChild(childViewController)
        childViewController.view.frame = view.bounds
        view.addSubview(childViewController.view)
        childViewController.didMove(toParent: self)
        
        // Set the current child view controller
        currentChildViewController = childViewController
    }
    
    public static func make() -> AmityChatHomeParentViewController {
        return AmityChatHomeParentViewController()
    }
}
