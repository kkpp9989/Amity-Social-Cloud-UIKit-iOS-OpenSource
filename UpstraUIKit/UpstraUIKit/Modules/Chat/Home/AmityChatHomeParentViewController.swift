//
//  AmityChatHomeParentViewController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 26/9/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

public class AmityChatHomeParentViewController: AmityViewController {
    
    // MARK: - Properties
    var currentChildViewController: UIViewController?
    var isHaveCreateBroadcastPermission: Bool = false
    
    // MARK: - Screen View Model
    private var screenViewModel: AmityChatHomeParentScreenViewModel?
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    public var rightBarButtons: UIBarButtonItem = UIBarButtonItem()
    public var leftBarButtons: UIBarButtonItem = UIBarButtonItem()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = AmityLocalizedStringSet.chatTitle.localizedString
        
        /* [Custom for ONE Krungthai] Set custom navigation bar theme */
        // Initial ONE Krungthai Custom theme
        theme = ONEKrungthaiCustomTheme(viewController: self)
        // Set background app for this navigation bar from ONE Krungthai custom theme
        theme?.setBackgroundApp(index: 0)
        
        screenViewModel = AmityChatHomeParentScreenViewModel()
        screenViewModel?.delegate = self
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        theme?.clearNavigationBarSetting()
        clearNavigationBar()
        
        setupView()
        setupNavigationBar()
        
        AmityUIKitManager.startHeartbeat()
    }
    
    // MARK: - Setup views
    private func setupView() {
        // Load the initial child view controller
        if AmityUIKitManagerInternal.shared.isInitialClient() {
            if !AmityUIKitManagerInternal.shared.currentUserId.isEmpty {
                let amityChatHomePageViewController = AmityChatHomePageViewController.make()
                switchToChildViewController(childViewController: amityChatHomePageViewController)
            }
        }
    }
    
    private func setupNavigationBar() {
        screenViewModel?.action.getCreateBroadcastMessagePermission() // Get permission then update navigation bar again
    }
    
    private func clearNavigationBar() {
        navigationItem.rightBarButtonItem = nil
    }
    
    private func updateNavigationBar() {
        DispatchQueue.main.async { [self] in
            /* Right items */
            // [Improvement] Change set button solution to use custom stack view
            var rightButtonItems: [UIButton] = []
            
            // Broadcast Button if have permission
            let broadcastButton: UIButton = UIButton.init(type: .custom)
            broadcastButton.setImage(AmityIconSet.iconBroadCastNavigationBar?.withRenderingMode(.alwaysOriginal), for: .normal)
            broadcastButton.addTarget(self, action: #selector(broadcastTap), for: .touchUpInside)
            broadcastButton.frame = CGRect(x: 0, y: 0, width: ONEKrungthaiCustomTheme.defaultIconBarItemWidth, height: ONEKrungthaiCustomTheme.defaultIconBarItemHeight)
            if isHaveCreateBroadcastPermission {
                rightButtonItems.append(broadcastButton)
            }
            
            // Create chat button
            let createChatButton: UIButton = UIButton.init(type: .custom)
            createChatButton.setImage(AmityIconSet.iconCreateGroupChat?.withRenderingMode(.alwaysOriginal), for: .normal)
            createChatButton.addTarget(self, action: #selector(createChannelTap), for: .touchUpInside)
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
            title.text = AmityLocalizedStringSet.chatTitle.localizedString
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
        childViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(childViewController.view)
        
        // Set constraints to the safe area
        NSLayoutConstraint.activate([
            childViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            childViewController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            childViewController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            childViewController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor)
        ])
        
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
    @objc func broadcastTap() {
        AmityChannelEventHandler.shared.createBroadCastBeingPrepared(from: self, menustyle: .pullDownMenuFromNavigationButton, selectItem: rightBarButtons)
    }
    
    @objc func searchTap() {
        let searchVC = AmityChatSearchParentViewController.make()
        let nav = UINavigationController(rootViewController: searchVC)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        present(nav, animated: true, completion: nil)
    }
    
    @objc func createChannelTap() {
        AmityChannelEventHandler.shared.channelCreateNewGroupChat(from: self, selectUsers: []) { [weak self] channelId, subChannelId in
            guard let weakSelf = self else { return }
            AmityChannelEventHandler.shared.channelDidTap(from: weakSelf, channelId: channelId, subChannelId: subChannelId)
        }
    }
}

// MARK: - Delegate
extension AmityChatHomeParentViewController: AmityChatHomeParentScreenViewModelDelegate {
    func screenViewModelDidGetCreateBroadcastMessagePermission(_ viewModel: AmityChatHomeParentScreenViewModelType, isHavePermission: Bool) {
        isHaveCreateBroadcastPermission = isHavePermission
        updateNavigationBar()
    }
    
}

// MARK: - For use open pull down menu
extension AmityChatHomeParentViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none // Show the popover on iPhone devices as well
    }
}
