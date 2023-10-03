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
    private let channelInfoController: AmityChannelInfoControllerProtocol
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
         channelInfoController: AmityChannelInfoControllerProtocol,
         userController: AmityChatUserControllerProtocol) {
        self.chatNotificationController = chatNotificationController
        self.channelInfoController = channelInfoController
        self.userController = userController
        self.channelId = channelId
    }
}

// MARK: - DataSource
extension AmityChatSettingsScreenViewModel {
    
}

// MARK: - Action
extension AmityChatSettingsScreenViewModel {
    // MARK: - Get Action
    func retrieveChannel() {
        // Get channel
        channelInfoController.getChannel { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let channel):
                strongSelf.channel = channel
                // Get title
                if channel.channelType == .conversation { // Case: Conversation type (1:1 Chat) -> Get other member displayname for set title
                    strongSelf.userController.getOtherUserInConversationChatByMemberShip { user in
                        if let otheruser = user {
                            // Get other user
                            strongSelf.otherUser = otheruser
                            // Set other user displayname to chat displayname
                            strongSelf.title = otheruser.displayName
                            // Go to delegate process
                            strongSelf.delegate?.screenViewModel(strongSelf, didGetChannelSuccess: channel)
                            // Get status report user and maybe update setting menu
                            Task {
                                await strongSelf.userController.getStatusReportUser(with: otheruser.userId) { result, error in
                                    if let statusReportUser = result {
                                        print("[Report user] currentstatusReportUser: \(statusReportUser)")
                                        // Update status report user of other user
                                        strongSelf.isReportedOtherUser = statusReportUser
                                        // Create / update setting menu again after get status report user success
                                        strongSelf.retrieveSettingsMenu()
                                        print("[Report user] retrieveSettingsMenu")
                                    }
                                }
                            }
                        } else {
                            // Set chat displayname from channel data
                            strongSelf.title = channel.displayName
                            // Go to delegate process
                            strongSelf.delegate?.screenViewModel(strongSelf, didGetChannelSuccess: channel)
                        }
                    }
                } else { // Case: Other type (Group Chat) -> Get displayname from channel object for set title
                    // Set chat displayname from channel data
                    strongSelf.title = channel.displayName
                    // Go to delegate process
                    strongSelf.delegate?.screenViewModel(strongSelf, didGetChannelSuccess: channel)
                }
                // Create / update setting menu after get channel success
                strongSelf.retrieveSettingsMenu()
            case .failure(_):
                break
            }
        }
    }
    
    func retrieveNotificationSettings() {
        // Get channel notification settings
        chatNotificationController.retrieveNotificationSettings { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let notification):
                strongSelf.isNotificationEnabled = notification.isEnabled
                
                // Create / update setting menu after get channel notification settings success
                strongSelf.retrieveSettingsMenu()
            case .failure(_):
                break
            }
        }
    }
    
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
    
    // MARK: - Notification - Update Action
    
    func changeNotificationSettings() {
        if !isNotificationEnabled {
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
        } else {
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
    
    // MARK: - Report user - Update Action
    func changeReportUserStatus() {
        guard let otherUserId = otherUser?.userId else { return }
        if !isReportedOtherUser { // Case : Will report user
            Task {
                await userController.reportUser(with: otherUserId) { [weak self] result, error in
                    guard let strongSelf = self else { return }
                    DispatchQueue.main.async {
                        if let isSuccess = result {
                            print("[Report user] ischangestatus to report user to report: \(isSuccess)")
                            strongSelf.isReportedOtherUser = true
                            strongSelf.delegate?.screenViewModelDidUpdateReportUser(strongSelf, isReported: true)
                            // Create / update setting menu again after get status report user success
                            strongSelf.retrieveSettingsMenu()
                            print("[Report user] retrieveSettingsMenu")
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
                            print("[Report user] ischangestatus to report user to unreport: \(isSuccess)")
                            strongSelf.isReportedOtherUser = false 
                            strongSelf.delegate?.screenViewModelDidUpdateReportUser(strongSelf, isReported: false)
                            // Create / update setting menu again after get status report user success
                            strongSelf.retrieveSettingsMenu()
                            print("[Report user] retrieveSettingsMenu")
                        } else if let error = error {
                            strongSelf.delegate?.screenViewModelDidUpdateReportUserFail(strongSelf, error: error)
                        }
                    }
                }
            }
        }
    }

}
