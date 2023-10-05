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
//    private let chatLeaveController: AmityChatLeaveControllerProtocol
//    private let chatDeleteController: AmityChatDeleteControllerProtocol
//    private let userRolesController: AmityChatUserRolesControllerProtocol
    private let userController: AmityChatUserControllerProtocol
    
    // MARK: - SubViewModel
    private var menuViewModel: AmityChatSettingsCreateMenuViewModelProtocol?
    
    // MARK: - Properties
    private(set) var channel: AmityChannelModel?
    var title: String?
    let channelId: String
    private var isNotificationEnabled: Bool = false
    
    // For 1:1 Chat only
    private var otherUser: AmityUserModel?
    private var isReportedOtherUser: Bool = false
    
    init(channelId: String,
         chatNotificationController: AmityChatNotificationSettingsControllerProtocol,
         channelController: AmityChannelControllerProtocol,
         userController: AmityChatUserControllerProtocol) {
        self.chatNotificationController = chatNotificationController
        self.channelController = channelController
        self.userController = userController
        self.channelId = channelId
    }
}

// MARK: - DataSource
extension AmityChatSettingsScreenViewModel {
    
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
                    strongSelf.userController.getOtherUserInConversationChatByMemberShip { user in
                        if let otheruser = user {
                            strongSelf.otherUser = otheruser
                            strongSelf.title = otheruser.displayName
                            strongSelf.delegate?.screenViewModel(strongSelf, didGetChannelSuccess: channel)
                            Task {
                                await strongSelf.userController.getStatusReportUser(with: otheruser.userId) { result, error in
                                    if let statusReportUser = result {
                                        strongSelf.isReportedOtherUser = statusReportUser
                                        strongSelf.retrieveSettingsMenu()
                                    }
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
        menuViewModel?.createSettingsItems(isNotificationEnabled: isNotificationEnabled, isReportedUserByMe: isReportedOtherUser) { [weak self] (items) in
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
        if !isReportedOtherUser { // Case : Will report user
            Task {
                await userController.reportUser(with: otherUserId) { [weak self] result, error in
                    guard let strongSelf = self else { return }
                    DispatchQueue.main.async {
                        if let isSuccess = result {
                            strongSelf.isReportedOtherUser = true
                            strongSelf.delegate?.screenViewModelDidUpdateReportUser(strongSelf, isReported: true)
                            strongSelf.retrieveSettingsMenu()
                        } else if let error = error {
                            strongSelf.delegate?.screenViewModelDidUpdateReportUserFail(strongSelf, error: error)
                        }
                    }
                }
            }
        } else { // Case : Will unreport user
            Task {
                await userController.unreportUser(with: otherUserId) { [weak self] result, error in
                    guard let strongSelf = self else { return }
                    DispatchQueue.main.async {
                        if let isSuccess = result {
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
    }
    
    // MARK: Update Action - Delete chat (1:1 Chat and Group Chat with moderator roles)
    func deleteChat() {
        let serviceRequest = RequestChat()
        serviceRequest.requestDeleteChat(channelId: channelId) { [weak self] result in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    strongSelf.delegate?.screenViewModelDidDeleteChannel(strongSelf)
                case .failure(let failure):
                    failure.localizedDescription
                    strongSelf.delegate?.screenViewModelDidDeleteChannelFail(strongSelf, error: failure)
                }
            }
        }
    }

    // MARK: Update Action - Leave chat (Group Chat)
    func leaveChat() {
        Task {
            await channelController.leaveChannel { [weak self] result, error in
                guard let strongSelf = self else { return }
                DispatchQueue.main.async {
                    if let isSuccess = result, isSuccess {
                        strongSelf.delegate?.screenViewModelDidLeaveChannel(strongSelf)
                    } else if let error = error {
                        strongSelf.delegate?.screenViewModelDidLeaveChannelFail(strongSelf, error: error)
                    }
                }
            }
        }
    }
}
