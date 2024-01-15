//
//  AmityChatHomePageViewController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 6/11/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit

/// Amity Chat home
public class AmityChatHomePageViewController: AmityPageViewController {
    
    // MARK: - Properties
    var recentsChatViewController = AmityRecentChatViewController.make()
    var followingChatViewController = AmityChatFriendPageViewController.make(type: .following)
    var followersChatViewController = AmityChatFriendPageViewController.make(type: .followers)

    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    
    // MARK: - View lifecycle
    private init() {
        super.init(nibName: AmityChatHomePageViewController.identifier, bundle: AmityUIKitManager.bundle)
        title = AmityLocalizedStringSet.chatTitle.localizedString
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public static func make() -> AmityChatHomePageViewController {
        return AmityChatHomePageViewController()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        AmityEventHandler.shared.hideKTBLoading() // Hide KTB Loading from main app if back from open chat detail by notification
        
        theme = ONEKrungthaiCustomTheme(viewController: self)
        theme?.setBackgroundApp(index: 0)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        theme?.clearNavigationBarSetting()
    }
    
    override func viewControllers(for pagerTabStripController: AmityPagerTabViewController) -> [UIViewController] {
        recentsChatViewController.pageTitle = AmityLocalizedStringSet.recentTitle.localizedString
        followingChatViewController.pageTitle = AmityLocalizedStringSet.followingTitle.localizedString
        followersChatViewController.pageTitle = AmityLocalizedStringSet.followersTitle.localizedString
        return [recentsChatViewController, followingChatViewController, followersChatViewController]
    }
    
}
