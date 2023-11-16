//
//  AmityChatSettingsScreenViewModel.swift
//  AmityUIKit
//
//  Created by min khant on 06/05/2021.
//  Copyright © 2021 Amity. All rights reserved.
//
/* [Custom for ONE Krungthai][Improvement] Change processing same as AmityCommunitySettingsScreenViewModel */

import UIKit
import AmitySDK

final class AmityChatSettingsScreenViewModel: AmityChatSettingsScreenViewModelType {
    
    weak var delegate: AmityChatSettingsScreenViewModelDelegate?
    
    // MARK: - Controller
    private let chatNotificationController: AmityChatNotificationSettingsControllerProtocol
    private let channelController: AmityChannelControllerProtocol
    private let channelMemberController: AmityChannelFetchMemberControllerProtocol
    private let userController: AmityChatUserControllerProtocol
    private var customMessageController: AmityCustomMessageController
    
    // MARK: - SubViewModel
    private var menuViewModel: AmityChatSettingsCreateMenuViewModelProtocol?
    
    // MARK: - Properties
    private(set) var channel: AmityChannelModel?
    var title: String?
    let channelId: String
    private var isNotificationEnabled: Bool = false
    private let dispatchGroup = DispatchGroup()
    
    // For 1:1 chat only
    var otherUser: AmityUserModel?
    private var isReportedOtherUser: Bool?
    
    // For Group chat only
    private(set) var isCanEditGroupChannel: Bool?
    
    init(channelId: String,
         chatNotificationController: AmityChatNotificationSettingsControllerProtocol,
         channelController: AmityChannelControllerProtocol,
         userController: AmityChatUserControllerProtocol) {
        self.chatNotificationController = chatNotificationController
        self.channelController = channelController
        self.userController = userController
        self.channelId = channelId
        customMessageController = AmityCustomMessageController(channelId: channelId)
        channelMemberController = AmityChannelFetchMemberController(channelId: channelId)
    }
}

// MARK: - DataSource
extension AmityChatSettingsScreenViewModel {
    // Not used
}

// MARK: - Action
extension AmityChatSettingsScreenViewModel {
    // MARK: - Get Action - Channel, other user info and status report user of him (For 1:1 Chat only)
    func retrieveChannel() {
        // Get channel
        channelController.getChannel { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let channel):
                strongSelf.channel = channel
                // Get title
                if channel.channelType == .conversation { // Case: Conversation type (1:1 Chat) -> Get other member displayname for set title
                    let otherUserId = channel.getOtherUserId()
                    strongSelf.userController.getOtherUserInConversationChatByOtherUserId(otherUserId: otherUserId) { user in
                        if let otheruser = user {
                            strongSelf.otherUser = otheruser
                            strongSelf.title = otheruser.displayName
                            strongSelf.delegate?.screenViewModel(strongSelf, didGetChannelSuccess: channel)
                            strongSelf.userController.getStatusReportUser(with: otheruser.userId) { result, error in
                                if let statusReportUser = result {
                                    strongSelf.isReportedOtherUser = statusReportUser
                                    strongSelf.retrieveSettingsMenu()
                                }
                            }
                        } else {
                            strongSelf.title = channel.displayName
                            strongSelf.delegate?.screenViewModel(strongSelf, didGetChannelSuccess: channel)
                        }
                    }
                } else { // Case: Other type (Group Chat) -> Get displayname from channel object for set title
                    strongSelf.title = channel.displayName
                    strongSelf.delegate?.screenViewModel(strongSelf, didGetChannelSuccess: channel)
                    
                    DispatchQueue.main.async {
                        strongSelf.userController.getEditGroupChannelPermission { result in
                            strongSelf.isCanEditGroupChannel = result
                            strongSelf.retrieveSettingsMenu()
                        }
                    }
                }
                
                strongSelf.retrieveSettingsMenu()
            case .failure(_):
                break
            }
        }
    }
    
    // MARK: - Get Action - Notification
    func retrieveNotificationSettings() {
        // Get channel notification settings
        chatNotificationController.retrieveNotificationSettings { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let notification):
                strongSelf.isNotificationEnabled = notification.isEnabled
                strongSelf.retrieveSettingsMenu()
            case .failure(_):
                break
            }
        }
    }
    
    // MARK: - Get Action - Setting menu
    func retrieveSettingsMenu() {
        // Get channel
        guard let channel = channel else { return }
        // Init creator
        menuViewModel = AmityChatSettingsCreateMenuViewModel(channel: channel)
        // Start create setting menu
        menuViewModel?.createSettingsItems(isNotificationEnabled: isNotificationEnabled,
                                           isReportedUserByMe: isReportedOtherUser,
                                           isCanEditGroupChannel: isCanEditGroupChannel) { [weak self] (items) in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                strongSelf.delegate?.screenViewModel(strongSelf, didGetSettingMenu: items)
            }
        }
    }
    
    // MARK: Update Action - Notification
    func changeNotificationSettings() {
        if !isNotificationEnabled { // Case : Will enable notification
            chatNotificationController.enableNotificationSettings { [weak self] success, error in
                guard let strongSelf = self else { return }
                if success {
                    strongSelf.isNotificationEnabled = true
                    strongSelf.retrieveSettingsMenu()
                    strongSelf.delegate?.screenViewModelDidUpdateNotificationSettings(strongSelf, isNotificationEnabled: true)
                } else if let error = error {
                       strongSelf.delegate?.screenViewModelDidUpdateNotificationSettingsFail(strongSelf, error: error)
                }
            }
        } else { // Case : Will disable notification
            chatNotificationController.disableNotificationSettings { [weak self] success, error in
                guard let strongSelf = self else { return }
                if success {
                    strongSelf.isNotificationEnabled = false
                    strongSelf.retrieveSettingsMenu()
                    strongSelf.delegate?.screenViewModelDidUpdateNotificationSettings(strongSelf, isNotificationEnabled: false)
                } else if let error = error {
                    strongSelf.delegate?.screenViewModelDidUpdateNotificationSettingsFail(strongSelf, error: error)
                }
            }
        }
    }
    
    // MARK: Update Action - Report user status
    func changeReportUserStatus() {
        guard let otherUserId = otherUser?.userId else { return }
        if let isReportedOtherUser = isReportedOtherUser, !isReportedOtherUser { // Case : Will report user
            userController.reportUser(with: otherUserId) { [weak self] result, error in
                guard let strongSelf = self else { return }
                DispatchQueue.main.async {
                    if let _ = result {
                        strongSelf.isReportedOtherUser = true
                        strongSelf.delegate?.screenViewModelDidUpdateReportUser(strongSelf, isReported: true)
                        strongSelf.retrieveSettingsMenu()
                    } else if let error = error {
                        strongSelf.delegate?.screenViewModelDidUpdateReportUserFail(strongSelf, error: error)
                    }
                }
            }
        } else { // Case : Will unreport user
            userController.unreportUser(with: otherUserId) { [weak self] result, error in
                guard let strongSelf = self else { return }
                DispatchQueue.main.async {
                    if let _ = result {
                        strongSelf.isReportedOtherUser = false
                        strongSelf.delegate?.screenViewModelDidUpdateReportUser(strongSelf, isReported: false)
                        strongSelf.retrieveSettingsMenu()
                    } else if let error = error {
                        strongSelf.delegate?.screenViewModelDidUpdateReportUserFail(strongSelf, error: error)
                    }
                }
            }
        }
    }
    
    // MARK: Update Action - Delete chat (1:1 Chat and Group Chat with moderator roles)
    func deleteChat() {
        channelController.deleteChannel { [weak self] result, error in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                if let isSuccess = result, isSuccess {
                    strongSelf.delegate?.screenViewModelDidDeleteChannel(strongSelf)
                } else if let error = error {
                    strongSelf.delegate?.screenViewModelDidDeleteChannelFail(strongSelf, error: error)
                }
            }
        }
    }

    // MARK: Update Action - Leave chat (Group Chat)
    func leaveChat() {
        // Start concurrency processing
        var isDispatchGroupLeave = false
        dispatchGroup.enter()
        
        // Check is can leave chat : Current user is moderator and have moderator more than one in group chat
        if let checkIsCanEditGroupChannel = isCanEditGroupChannel, checkIsCanEditGroupChannel { // Case : Is moderator -> Check amount of moderator before
            channelMemberController.fetchOnce(roles: [AmityChannelRole.moderator.rawValue, AmityChannelRole.channelModerator.rawValue]) { [weak self] (result) in
                switch result {
                case .success(let members):
                    if members.count > 1 { // Case : Is moderator and have moderator more than one -> Send custom message and leave channel
                        // Send custom message with leave chat scenario (!!! Must to send before leave channel !!!)
                        let subjectDisplayName = AmityUIKitManagerInternal.shared.client.user?.snapshot?.displayName ?? AmityUIKitManager.displayName
                        self?.customMessageController.send(event: .leavedChat, subjectUserName: subjectDisplayName, objectUserName: "") { result in
                            switch result {
                            case .success(_):
//                                print(#"[Custom message] send message success : "\#(subjectDisplayName) left this chat"#)
                                break
                            case .failure(_):
//                                print(#"[Custom message] send message fail : "\#(subjectDisplayName) left this chat"#)
                                break
                            }
                            if !isDispatchGroupLeave {
                                isDispatchGroupLeave = true
                                self?.dispatchGroup.leave() // Go to leave channel processing
                            }
                        }
                    } else { // Case : Is moderator and have one moderator only -> Force leave channel with receive error
                        if !isDispatchGroupLeave {
                            isDispatchGroupLeave = true
                            self?.dispatchGroup.leave() // Go to leave channel processing
                        }
                    }
                case .failure: // Case : Is moderator but can't get moderator member -> Try leave channel
                    if !isDispatchGroupLeave {
                        isDispatchGroupLeave = true
                        self?.dispatchGroup.leave() // Go to leave channel processing
                    }
                }
            }
        } else { // Case : Isn't moderator -> Send custom message and leave channel
            // Send custom message with leave chat scenario (!!! Must to send before leave channel !!!)
            let subjectDisplayName = AmityUIKitManagerInternal.shared.client.user?.snapshot?.displayName ?? AmityUIKitManager.displayName
            customMessageController.send(event: .leavedChat, subjectUserName: subjectDisplayName, objectUserName: "") { result in
                switch result {
                case .success(_):
//                    print(#"[Custom message] send message success : "\#(subjectDisplayName) left this chat"#)
                    break
                case .failure(_):
//                    print(#"[Custom message] send message fail : "\#(subjectDisplayName) left this chat"#)
                    break
                }
                if !isDispatchGroupLeave {
                    isDispatchGroupLeave = true
                    self.dispatchGroup.leave() // Go to leave channel processing
                }
            }
        }
        
        // Leave chat when check condition and send custom message complete
        dispatchGroup.notify(queue: .main) {
            self.channelController.leaveChannel { [weak self] result, error in
                guard let strongSelf = self else { return }
                DispatchQueue.main.async {
                    if let error = error {
                        strongSelf.delegate?.screenViewModelDidLeaveChannelFail(strongSelf, error: error)
                    } else {
                        strongSelf.delegate?.screenViewModelDidLeaveChannel(strongSelf)
                    }
                }
            }
        }
    }
}
