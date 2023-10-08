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
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    public var rightBarButtons: UIBarButtonItem = UIBarButtonItem()
    public var leftBarButtons: UIBarButtonItem = UIBarButtonItem()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = AmityLocalizedStringSet.chatTitle.localizedString
        
        setupNavigationBar()
        
        /* [Custom for ONE Krungthai] Set custom navigation bar theme */
        // Initial ONE Krungthai Custom theme
        theme = ONEKrungthaiCustomTheme(viewController: self)
        // Set background app for this navigation bar from ONE Krungthai custom theme
        theme?.setBackgroundApp(index: 0)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        theme?.clearNavigationBarSetting()
        setupView()
        AmityUIKitManager.startHeartbeat()
    }
    
    private func setupView() {
        // Load the initial child view controller
        if AmityUIKitManagerInternal.shared.client != nil {
            let amityChatHomePageViewController = AmityChatHomePageViewController.make()
            switchToChildViewController(childViewController: amityChatHomePageViewController)
        }
    }
    
    // MARK: - Setup views
    private func setupNavigationBar() {
        DispatchQueue.main.async { [self] in
            /* Right items */
            // [Improvement] Change set button solution to use custom stack view
            var rightButtonItems: [UIButton] = []
            
            // Create chat button
            let createChatButton: UIButton = UIButton.init(type: .custom)
            createChatButton.setImage(AmityIconSet.iconCreateGroupChat?.withRenderingMode(.alwaysOriginal), for: .normal)
            createChatButton.addTarget(self, action: #selector(createPostTap), for: .touchUpInside)
            createChatButton.frame = CGRect(x: 0, y: 0, width: ONEKrungthaiCustomTheme.defaultIconBarItemWidth, height: ONEKrungthaiCustomTheme.defaultIconBarItemHeight)
            rightButtonItems.append(createChatButton)
            
            // Search Button
            let searchButton: UIButton = UIButton.init(type: .custom)
            searchButton.setImage(AmityIconSet.iconSearchNavigationBar?.withRenderingMode(.alwaysOriginal), for: .normal)
            searchButton.addTarget(self, action: #selector(searchTap), for: .touchUpInside)
            searchButton.frame = CGRect(x: 0, y: 0, width: ONEKrungthaiCustomTheme.defaultIconBarItemWidth, height: ONEKrungthaiCustomTheme.defaultIconBarItemHeight)
            rightButtonItems.append(searchButton)
            
            // Group all button to UIBarButtonItem
            rightBarButtons = ONEKrungthaiCustomTheme.groupButtonsToUIBarButtonItem(buttons: rightButtonItems)
            
            // Set custom stack view to UIBarButtonItem
            navigationItem.rightBarButtonItem = rightBarButtons
            
            /* Left items */
            // Title
            // [Custom for ONE Krungthai] Move title to left navigation bar item
            let title = UILabel()
            title.text = AmityLocalizedStringSet.communityHomeTitle.localizedString
            title.font = AmityFontSet.headerLine
            // Back button (Refer default leftBarButtonItem from AmityViewController)
            let backButton = UIBarButtonItem(image: AmityIconSet.iconBackNavigationBar?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(didTapLeftBarButton)) // [Custom for ONE Krungthai] Set custom icon theme
            backButton.tintColor = AmityColorSet.base
            leftBarButtons = backButton
            
            if self.navigationController?.viewControllers.first != self {
                // Add all component to left navigation items
                navigationItem.leftBarButtonItems = [backButton, UIBarButtonItem(customView: title)] // Back button, Title of naviagation bar
            } else {
                // This controller is the root view controller, so you don't need to set a back button
                navigationItem.leftBarButtonItem = UIBarButtonItem(customView: title) // Title of navigation bar
            }
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

// MARK: - Action

private extension AmityChatHomeParentViewController {
    @objc func searchTap() {
        let searchVC = AmitySearchViewController.make()
        let nav = UINavigationController(rootViewController: searchVC)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        present(nav, animated: true, completion: nil)
    }
    
    @objc func createPostTap() {
        AmityChannelEventHandler.shared.channelCreateNewGroupChat(from: self)
    }
}
