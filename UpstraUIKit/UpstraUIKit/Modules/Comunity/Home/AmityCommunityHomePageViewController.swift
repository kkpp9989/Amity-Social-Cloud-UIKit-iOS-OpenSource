//
//  AmityCommunityHomePageViewController.swift
//  AmityUIKit
//
//  Created by Nontapat Siengsanor on 18/8/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit

public class AmityCommunityHomePageViewController: AmityPageViewController {
    
    // MARK: - Properties
    public let newsFeedVC = AmityNewsfeedViewController.make()
    public let exploreVC = AmityCommunityExplorerViewController.make()
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    public var rightBarButtons: UIBarButtonItem = UIBarButtonItem()
    public var leftBarButtons: UIBarButtonItem = UIBarButtonItem()
    
    private var totalUnreadCount: Int = 0
    
    private init() {
        super.init(nibName: AmityCommunityHomePageViewController.identifier, bundle: AmityUIKitManager.bundle)
        /* [Custom for ONE Krungthai] Set title of navigation bar to nil and add title to left navigation item at setupNavigationBar() instead */
//        title = AmityLocalizedStringSet.communityHomeTitle.localizedString
        title = nil
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        /* [Custom for ONE Krungthai] Set custom navigation bar theme */
        // Initial ONE Krungthai Custom theme
        theme = ONEKrungthaiCustomTheme(viewController: self)
        // Set background app for this navigation bar from ONE Krungthai custom theme
        theme?.setBackgroundApp(index: 0)
        // Set custom navigation bar
        setupNavigationBar()
        
        // [Custom for ONE Krungthai] [Temp] Set all notification on / off
//        Task {
//            await setAllNotificationOff()
//            await setAllNotificationOn()
//        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
        /* [Custom for ONE Krungthai] Clear setting navigation bar (normal) from ONE Krungthai custom theme */
        theme?.clearNavigationBarSetting()
        getUnreadCount()
        startObserveUpdate()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopObserveUpdate()
    }
    
    public static func make() -> AmityCommunityHomePageViewController {
        return AmityCommunityHomePageViewController()
    }
    
    override func viewControllers(for pagerTabStripController: AmityPagerTabViewController) -> [UIViewController] {
        newsFeedVC.pageTitle = AmityLocalizedStringSet.newsfeedTitle.localizedString
        exploreVC.pageTitle = AmityLocalizedStringSet.exploreTitle.localizedString
        return [newsFeedVC, exploreVC]
    }
    
    // MARK: - Setup views
    private func setupNavigationBar() {
        DispatchQueue.main.async { [self] in
            /* Right items */
            // [Improvement] Change set button solution to use custom stack view
            var rightButtonItems: [UIButton] = []
            
            // Create post button
            let notificationButton: UIButton = UIButton.init(type: .custom)
            notificationButton.setImage(AmityIconSet.iconNotificationNavigationBar?.withRenderingMode(.alwaysOriginal), for: .normal)
            notificationButton.addTarget(self, action: #selector(notificationTap), for: .touchUpInside)
            notificationButton.frame = CGRect(x: 0, y: 0, width: ONEKrungthaiCustomTheme.defaultIconBarItemWidth, height: ONEKrungthaiCustomTheme.defaultIconBarItemHeight)
            rightButtonItems.append(notificationButton)
            
            // Create a label for displaying the unread count
            let unreadCountLabel = UILabel()
            unreadCountLabel.text = totalUnreadCount > 99 ? "99+" : String(totalUnreadCount)
            unreadCountLabel.textColor = UIColor.white
            unreadCountLabel.font = AmityFontSet.caption
            unreadCountLabel.backgroundColor = UIColor.red
            unreadCountLabel.textAlignment = .center
            unreadCountLabel.layer.cornerRadius = 10
            unreadCountLabel.layer.masksToBounds = true
            
            // Calculate the width based on the text
            let textSize = unreadCountLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: unreadCountLabel.frame.size.height))
            unreadCountLabel.frame = CGRect(x: notificationButton.frame.size.width - textSize.width - 5, y: 0, width: textSize.width + 15, height: 20)
            
            // Add the red dot view to the notificationButton
            if totalUnreadCount > 0 {
                notificationButton.addSubview(unreadCountLabel)
            }
            
            // Create post button
            let createPostButton: UIButton = UIButton.init(type: .custom)
            createPostButton.setImage(AmityIconSet.iconAddNavigationBar?.withRenderingMode(.alwaysOriginal), for: .normal)
            createPostButton.addTarget(self, action: #selector(createPostTap), for: .touchUpInside)
            createPostButton.frame = CGRect(x: 0, y: 0, width: ONEKrungthaiCustomTheme.defaultIconBarItemWidth, height: ONEKrungthaiCustomTheme.defaultIconBarItemHeight)
            rightButtonItems.append(createPostButton)
            
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
    
    func startObserveUpdate() {
        NotificationCenter.default.addObserver(self, selector: #selector(getUnreadCount), name: Notification.Name.NotificationTray.didUpdate, object: nil)
    }
    
    func stopObserveUpdate() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.NotificationTray.didUpdate, object: nil)
    }
}

// MARK: - Action
private extension AmityCommunityHomePageViewController {
    @objc func searchTap() {
        let searchVC = AmitySearchViewController.make()
        let nav = UINavigationController(rootViewController: searchVC)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        present(nav, animated: true, completion: nil)
    }
    
    @objc func createPostTap() {
        AmityEventHandler.shared.createPostBeingPrepared(from: self, menustyle: .pullDownMenuFromNavigationButton, selectItem: rightBarButtons)
    }
    
    @objc func notificationTap() {
        let notificationVC = AmityNotificationTrayViewController.make()
        navigationController?.pushViewController(notificationVC, animated: true)
    }
    
    /* [Custom for ONE Krungthai] [Temp] Set all notification off (top-level) */
    func setAllNotificationOff() async {
        // Get notification manager
        let userNotificationManager = AmityUIKitManager.client.notificationManager
        
        // Set disable all notification (top-level)
        do {
            let result = try await userNotificationManager.disableAllNotifications()
        } catch {
        }
    }
    
    /* [Custom for ONE Krungthai] [Temp] Set all notification on (top-level) */
    func setAllNotificationOn() async {
        // Get notification manager
        let userNotificationManager = AmityUIKitManager.client.notificationManager
        
        // Set enable all notification (top-level)
        do {
            let result = try await userNotificationManager.enable(for: [])
        } catch {
        }
    }
    
    @objc func getUnreadCount() {
        let serviceRequest = RequestGetNotification()
        serviceRequest.requestNotificationTotalUnreadCount() { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let unreadCountData):
                strongSelf.totalUnreadCount = unreadCountData.data.totalUnreadCount
                strongSelf.setupNavigationBar()
            case .failure(let error):
                print(error)
            }
        }
    }
}

extension AmityCommunityHomePageViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none // Show the popover on iPhone devices as well
    }
}
