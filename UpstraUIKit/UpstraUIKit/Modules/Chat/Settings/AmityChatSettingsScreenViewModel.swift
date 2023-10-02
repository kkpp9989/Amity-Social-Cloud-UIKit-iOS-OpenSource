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
//    private let chatNotificationController: AmityChatNotificationSettingsControllerProtocol
//    private let chatLeaveController: AmityChatLeaveControllerProtocol
//    private let chatDeleteController: AmityChatDeleteControllerProtocol
//    private let userRolesController: AmityChatserRolesControllerProtocol
    private let channelRepository: AmityChannelRepository?
    
    // MARK: - SubViewModel
    private var menuViewModel: AmityChatSettingsCreateMenuViewModelProtocol?
    
    // MARK: - Properties
    private(set) var channel: AmityChannel?
    var title: String?
    let channelId: String
    
    init(channelId: String) {
        channelRepository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
        self.channelId = channelId
    }
}

// MARK: - DataSource
extension AmityChatSettingsScreenViewModel {
    
}

// MARK: - Action
extension AmityChatSettingsScreenViewModel {
    func retrieveChannel() {
        if let channelObject = channelRepository?.getChannel(channelId), let channel = channelObject.snapshot {
            self.channel = channel
            if channel.channelType == .conversation {
                AmityMemberChatUtilities.Conversation.getOtherUserByMemberShip(channelId: channel.channelId) { user in
                    if let otherMember = user {
                        title = otherMember.displayName
                        delegate?.screenViewModel(self, didGetChannelSuccess: channel)
                    }
                }
            } else {
                title = channel.displayName
                delegate?.screenViewModel(self, didGetChannelSuccess: channel)
            }
            
            retrieveSettingsMenu()
        }
    }
    
    func retrieveNotificationSettings() {
        
    }
    
    func retrieveSettingsMenu() {
        guard let channel = channel else { return }
        menuViewModel = AmityChatSettingsCreateMenuViewModel(channel: channel)
        menuViewModel?.createSettingsItems{ [weak self] (items) in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.screenViewModel(strongSelf, didGetSettingMenu: items)
        }
    }

}
