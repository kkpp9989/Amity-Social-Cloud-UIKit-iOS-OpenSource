//
//  AmityChannelPickerTabPageViewController.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 15/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

public final class AmityChannelPickerTabPageViewController: AmityPageViewController {
    
//    private var screenViewModel: AmityCommunityMemberSettingsScreenViewModelType!
    
    // MARK: - Child ViewController
    private var conversationVC: AmityChannelPickerViewController?
    private var groupChatVC: AmityChannelPickerViewController?
    private var screenViewModel: AmityChannelPickerScreenViewModelType?
    
    // MARK: - View lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Forward to"
//        screenViewModel.delegate = self
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    public static func make() -> AmityChannelPickerTabPageViewController {
        let vc = AmityChannelPickerTabPageViewController(nibName: AmityChannelPickerTabPageViewController.identifier,
                                                          bundle: AmityUIKitManager.bundle)
        let screenViewModel = AmityChannelPickerScreenViewModel()
        vc.screenViewModel = screenViewModel
        return vc
    }
    
    override func viewControllers(for pagerTabStripController: AmityPagerTabViewController) -> [UIViewController] {
        if let currentScreenViewModel = screenViewModel {
            conversationVC = AmityChannelPickerViewController.make(pageTitle: "Accounts", viewType: .conversation, screenViewModel: currentScreenViewModel)
            groupChatVC = AmityChannelPickerViewController.make(pageTitle: "Groups", viewType: .groupchat, screenViewModel: currentScreenViewModel)
            return [conversationVC!, groupChatVC!]
        } else {
            return []
        }
    }
}
//
//extension AmityMemberPickerForwardMessageChatTabPageViewController: AmityCommunityMemberSettingsScreenViewModelDelegate {
//    func screenViewModelShouldShowAddButtonBarItem(status: Bool) {
//    }
//
//}
