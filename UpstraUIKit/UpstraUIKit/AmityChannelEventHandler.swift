//
//  AmityChannelEventHandler.swift
//  AmityUIKit
//
//  Created by min khant on 09/07/2021.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit

/// Share event handler for channel
///
/// Events which are interacted on AmityUIKIt will trigger following functions
/// These all functions having its default behavior
///
open class AmityChannelEventHandler {
    static var shared = AmityChannelEventHandler()
    
    public init() { }
    
    /// Event for channel
    /// It will be triggered when channel list or chat button is tapped
    ///
    /// A default behavior is navigating to `AmityMessageListViewController`
    open func channelDidTap(from source: AmityViewController,
                            channelId: String, subChannelId: String) {
        let settings = AmityMessageListViewController.Settings()
        let viewController = AmityMessageListViewController.make(channelId: channelId, subChannelId: subChannelId, settings: settings)
        viewController.hidesBottomBarWhenPushed = true
        source.navigationController?.pushViewController(viewController, animated: true)
    }
    
    open func channelDidTap(from source: UIViewController,
                            channelId: String, subChannelId: String) {
        let settings = AmityMessageListViewController.Settings()
        let viewController = AmityMessageListViewController.make(channelId: channelId, subChannelId: subChannelId, settings: settings)
        viewController.hidesBottomBarWhenPushed = true
        source.navigationController?.isNavigationBarHidden = false
        source.navigationController?.pushViewController(viewController, animated: true)
    }
    
    open func channelWithJumpMessageDidTap(from source: UIViewController,
                            channelId: String, subChannelId: String, messageId: String) {
        let settings = AmityMessageListViewController.Settings()
        let viewController = AmityMessageListViewController.make(channelId: channelId, subChannelId: subChannelId, settings: settings, messageId: messageId)
        viewController.hidesBottomBarWhenPushed = true
        source.navigationController?.pushViewController(viewController, animated: true)
    }
    
    /// Event for Leave Chat
    /// It will be triggered when leave chat is success
    ///
    /// A default behavior is pop back to rootViewcontroller
    open func channelDidLeaveSuccess(from source: AmityViewController) {
        source.navigationController?.popToRootViewController(animated: true)
    }
    
    /// Event for Update Group Chat Detail
    /// It will be triggered when group chate update is complete
    ///
    /// A default behavior is pop back to prev view controller
    open func channelGroupChatUpdateDidComplete(from source: AmityViewController) {
        source.navigationController?.popViewController(animated: true)
    }
    
    /// Event for creating chat with users
    /// It will be triggered when user click add button to create chat with users or to add many users
    ///
    /// A default behavior is navigating to `AmityMemberPickerViewController`
    open func channelAddMemberDidTap(from source: AmityViewController,
                              channelId: String,
                              selectedUsers: [AmitySelectMemberModel],
                              completionHandler: @escaping ([AmitySelectMemberModel]) -> ()) {
        // [Back up]
//        let vc = AmityMemberPickerViewController.make(withCurrentUsers: selectedUsers)
//        vc.selectUsersHandler = { storeUsers in
//            completionHandler(storeUsers)
//        }
//        let navVc = UINavigationController(rootViewController: vc)
//        navVc.modalPresentationStyle = .fullScreen
//        source.present(navVc, animated: true, completion: nil)
        let vc = AmityAllTypeMemberPickerChatViewController.make(withCurrentUsers: selectedUsers)
        vc.selectUsersHandler = { storeUsers in
            completionHandler(storeUsers)
        }
        let navVc = UINavigationController(rootViewController: vc)
        navVc.modalPresentationStyle = .fullScreen
        source.present(navVc, animated: true, completion: nil)
    }
    
    /// Event for creating new chat with users
    /// It will be triggered when user click add button to create chat with users
    ///
    /// A default behavior is navigating to `AmityMemberPickerViewController`
    open func channelCreateNewChat(from source: AmityViewController,
                              completionHandler: @escaping ([AmitySelectMemberModel]) -> ()) {
        let vc = AmityMemberPickerViewController.make()
        vc.selectUsersHandler = { storeUsers in
            completionHandler(storeUsers)
        }
        let navVc = UINavigationController(rootViewController: vc)
        navVc.modalPresentationStyle = .fullScreen
        source.present(navVc, animated: true, completion: nil)
    }
    
    /// Event for creating new group chat with users
    /// It will be triggered when user click add button to create chat with users
    ///
    /// A default behavior is navigating to `AmityMemberPickerChatViewController`
    open func channelCreateNewGroupChat(from source: AmityViewController,
                                        selectUsers: [AmitySelectMemberModel],
                                        completionHandler: @escaping ((String, String)) -> ()) {
		let vc = GroupChatCreatorFirstViewController.make(selectUsers)
        vc.tapNextButton = { channelId, subChannelId in
            completionHandler((channelId, subChannelId))
        }
        let navVc = UINavigationController(rootViewController: vc)
        navVc.modalPresentationStyle = .fullScreen
        source.present(navVc, animated: true, completion: nil)
    }
    
    open func channelCreateEditGroupChat(from source: AmityViewController,
                                        selectUsers: [AmitySelectMemberModel]) {
        let vc = AmityAllTypeMemberPickerFirstViewController.make(currentUsers: selectUsers)
        let navVc = UINavigationController(rootViewController: vc)
        navVc.modalPresentationStyle = .fullScreen
        source.present(navVc, animated: true, completion: nil)
    }
    
    /// Event for open group profile editor
    /// It will be triggered when user click group profile in chat settings (Moderator only)
    ///
    /// A default behavior is navigating to `AmityGroupChatEditViewController`
    open func channelEditGroupChatProfile(from source: AmityViewController, channelId: String) {
        let vc = AmityGroupChatEditViewController.make(channelId: channelId)
        vc.hidesBottomBarWhenPushed = true
        source.navigationController?.pushViewController(vc, animated: true)
    }
    
    /// Event for open group chat member list
    /// It will be triggered when user click members in chat settings
    ///
    /// A default behavior is navigating to `AmityChannelMemberViewController`
    open func channelOpenGroupChatMemberList(from source: AmityViewController, channel: AmityChannelModel) {
        let vc = AmityChannelMemberSettingsViewController.make(channel: channel)
        vc.hidesBottomBarWhenPushed = true
        source.navigationController?.pushViewController(vc, animated: true)
    }
    
    /// Event for forward chat
    /// It will be triggered when user click share in chat detail with selected forward message
    ///
    /// A default behavior is navigating to `AmityChannelMemberViewController`
    open func channelOpenChannelListForForwardMessage(from source: AmityViewController, completionHandler: @escaping ([AmitySelectMemberModel]) -> ()) {
        let vc = AmityChannelPickerTabPageViewController.make()
        vc.selectUsersHandler = { storeUsers in
            completionHandler(storeUsers)
        }
        let navVc = UINavigationController(rootViewController: vc)
        navVc.modalPresentationStyle = .overFullScreen
        source.present(navVc, animated: true, completion: nil)
    }
}
