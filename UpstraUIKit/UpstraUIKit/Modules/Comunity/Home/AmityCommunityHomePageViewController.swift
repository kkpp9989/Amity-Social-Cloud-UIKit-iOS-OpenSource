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
    public var createPostItem: UIBarButtonItem = UIBarButtonItem()
    
    private init() {
        super.init(nibName: AmityCommunityHomePageViewController.identifier, bundle: AmityUIKitManager.bundle)
        /* [Original] */
//        title = AmityLocalizedStringSet.communityHomeTitle.localizedString
        /* [Custom for ONE Krungthai] Set title of navigation bar to nil and add title to left navigation item at setupNavigationBar() instead */
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
        
        /* [Custom for ONE Krungthai] [Temp] Set all notification on / off */
        Task {
//            await setAllNotificationOff()
            await setAllNotificationOn()
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /* [Custom for ONE Krungthai] Clear setting navigation bar (normal) from ONE Krungthai custom theme */
        theme?.clearNavigationBarSetting()
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
        /* Right items */
        // Search Button
        let searchItem = UIBarButtonItem(image: AmityIconSet.iconSearch, style: .plain, target: self, action: #selector(searchTap))
        searchItem.tintColor = AmityColorSet.base
        // Create post Button
        // [Custom for ONE Krungthai] Move create post button to navigation bar
        createPostItem = UIBarButtonItem(image: AmityIconSet.iconAdd, style: .plain, target: self, action: #selector(createPostTap))
        createPostItem.tintColor = AmityColorSet.base
        // Add all component to right navigation item
        navigationItem.rightBarButtonItems = [searchItem, createPostItem]
        
        /* Left items */
        // Title
        // [Custom for ONE Krungthai] Move title to left navigation bar item
        let title = UILabel()
        title.text = AmityLocalizedStringSet.communityHomeTitle.localizedString
        title.font = AmityFontSet.headerLine
        // Back button (Refer default leftBarButtonItem from AmityViewController)
        let backButton = UIBarButtonItem(image: AmityIconSet.iconBack, style: .plain, target: self, action: #selector(didTapLeftBarButton))
        backButton.tintColor = AmityColorSet.base
        // Add all component to left navigation item
        navigationItem.leftBarButtonItems = [backButton, UIBarButtonItem(customView: title)] // Back button, Title of naviagation bar
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
        AmityEventHandler.shared.createPostBeingPrepared(from: self)
    }
    
    /* [Custom for ONE Krungthai] [Temp] Set all notification off (top-level) */
    func setAllNotificationOff() async {
        // Get notification manager
        let userNotificationManager = AmityUIKitManager.client.notificationManager
        
        // Set disable all notification (top-level)
        do {
            let result = try await userNotificationManager.disableAllNotifications()
            print("[Amity-Notification] Set all notification off (top-level) success with result : \(result)")
        } catch {
            print("[Amity-Notification] Set all notification off (top-level) fail with error: \(error)")
        }
    }
    
    /* [Custom for ONE Krungthai] [Temp] Set all notification on (top-level) */
    func setAllNotificationOn() async {
        // Get notification manager
        let userNotificationManager = AmityUIKitManager.client.notificationManager
        
        // Set enable all notification (top-level)
        do {
            let result = try await userNotificationManager.enable(for: [])
            print("[Amity-Notification] Set all notification on (top-level) success with result : \(result)")
        } catch {
            print("[Amity-Notification] Set all notification on (top-level) fail with error: \(error)")
        }
    }
}
