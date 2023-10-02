//
//  AmityChatSettingsScreenViewModel.swift
//  AmityUIKit
//
//  Created by min khant on 06/05/2021.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

final class AmityChatSettingsScreenViewModel: AmityChatSettingsScreenViewModelType {

    weak var delegate: AmityChatSettingsScreenViewModelDelegate?
    
    // MARK: - Controller
    private let chatNotificationController: AmityChatNotificationSettingsControllerProtocol
    private let chatInfoController: AmityChatInfoControllerProtocol
//    private let chatLeaveController: AmityChatLeaveControllerProtocol
//    private let chatDeleteController: AmityChatDeleteControllerProtocol
//    private let userRolesController: AmityChatUserRolesControllerProtocol
//    private let userController: AmityChatUserControllerProtocol
    private let channelRepository: AmityChannelRepository?
    
    // MARK: - SubViewModel
    private var menuViewModel: AmityChatSettingsCreateMenuViewModelProtocol?
    
    // MARK: - Properties
    private(set) var channel: AmityChannelModel?
    var title: String?
    let channelId: String
    private var isNotificationEnabled: Bool = false
    
    init(channelId: String,
         chatNotificationController: AmityChatNotificationSettingsControllerProtocol,
         chatInfoController: AmityChatInfoControllerProtocol) {
        self.chatNotificationController = chatNotificationController
        self.chatInfoController = chatInfoController
        self.channelId = channelId
        
        channelRepository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
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
        chatInfoController.getChannel { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let channel):
                strongSelf.channel = channel
                // Get title
                if channel.channelType == .conversation { // Case: Conversation type (1:1 Chat) -> Get other member displayname for set title
                    AmityMemberChatUtilities.Conversation.getOtherUserByMemberShip(channelId: channel.channelId) { user in
                        if let otherMember = user {
                            strongSelf.title = otherMember.displayName
                        } else {
                            strongSelf.title = channel.displayName
                        }
                        strongSelf.delegate?.screenViewModel(strongSelf, didGetChannelSuccess: channel)
                    }
                } else { // Case: Other type (Group Chat) -> Get displayname from channel object for set title
                    strongSelf.title = channel.displayName
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
        menuViewModel?.createSettingsItems(isNotificationEnabled: isNotificationEnabled) { [weak self] (items) in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.screenViewModel(strongSelf, didGetSettingMenu: items)
        }
    }
    
    // MARK: - Update Action
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
    
    func changeReportUserStatus() {
        
    }

}
