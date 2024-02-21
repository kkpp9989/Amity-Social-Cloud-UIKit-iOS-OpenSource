//
//  AmityChatSettingsCreateMenuViewModel.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 2/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityChatSettingsCreateMenuViewModelProtocol {
    func createSettingsItems(isNotificationEnabled: Bool?, isReportedUserByMe: Bool?, isCanEditGroupChannel: Bool?, _ completion: (([AmitySettingsItem]) -> Void)?)
}

final class AmityChatSettingsCreateMenuViewModel: AmityChatSettingsCreateMenuViewModelProtocol {

    // MARK: - Properties
    private let channel: AmityChannelModel
    private var isNotificationEnabled: Bool?
    
    // For 1:1 chat only
    private var isReportedUserByMe: Bool?

    // For group chat only
    private var isCanEditGroupChannel: Bool?

    // MARK: - Controller
    private let dispatchCounter = DispatchGroup()
    private var userController: AmityChatUserController
    
    init(channel: AmityChannelModel) {
        self.channel = channel
        userController = AmityChatUserController(channelId: channel.channelId)
    }
    
    func createSettingsItems(isNotificationEnabled: Bool?, isReportedUserByMe: Bool?, isCanEditGroupChannel: Bool?, _ completion: (([AmitySettingsItem]) -> Void)?) {
        self.isNotificationEnabled = isNotificationEnabled
        self.isReportedUserByMe = isReportedUserByMe
        self.isCanEditGroupChannel = isCanEditGroupChannel
        
        prepareDataSource(completion)
    }
    
    private func prepareDataSource(_ completion: (([AmitySettingsItem]) -> Void)?) {
        var settingsItems = [AmitySettingsItem]()
        
        switch channel.channelType {
        case .conversation: // 1:1 Chat
            // MARK: Muted or unmuted notification
            if let isNotificationEnabled = self.isNotificationEnabled {
                let itemNotificationContent = AmitySettingsItem.TextContent(identifier: AmityChatSettingsItem.notification(isNotificationEnabled).identifier,
                                                                            icon: AmityChatSettingsItem.notification(isNotificationEnabled).icon,
                                                                            title: AmityChatSettingsItem.notification(isNotificationEnabled).title,
                                                                            description: nil)
                settingsItems.append(.textContent(content: itemNotificationContent))
            }
            
            // MARK: Invite user (1:1 Chat)
            let itemInviteUserContent = AmitySettingsItem.TextContent(identifier: AmityChatSettingsItem.inviteUser.identifier,
                                                                  icon: AmityChatSettingsItem.inviteUser.icon,
                                                                  title: AmityChatSettingsItem.inviteUser.title,
                                                                  description: nil)
            settingsItems.append(.textContent(content: itemInviteUserContent))
            
            // MARK: Report / unreport User (1:1 Chat)
            let itemReportUserContent = AmitySettingsItem.TextContent(identifier: AmityChatSettingsItem.report(isReportedUserByMe ?? false).identifier,
                                                               icon: AmityChatSettingsItem.report(isReportedUserByMe ?? false).icon,
                                                               title: AmityChatSettingsItem.report(isReportedUserByMe ?? false).title,
                                                               description: nil)
            settingsItems.append(.textContent(content: itemReportUserContent))
            
            
            // MARK: Invite via QR / Link (Group chat [Member roles]) [No action]
            let itemInviteViaQRAndLink1_1 = AmitySettingsItem.TextContent(identifier: AmityChatSettingsItem.inviteViaQRAndLink1_1.identifier,
                                                                        icon: AmityChatSettingsItem.inviteViaQRAndLink1_1.icon,
                                                                        title: AmityChatSettingsItem.inviteViaQRAndLink1_1.title,
                                                                        description: nil)
                settingsItems.append(.textContent(content: itemInviteViaQRAndLink1_1))
            
            // MARK: Separator
            //settingsItems.append(.separator)
            
            // MARK: Delete chat (1:1 Chat & Group chat [Moderator roles])
            let itemDeleteChatContent = AmitySettingsItem.TextContent(identifier: AmityChatSettingsItem.delete(false).identifier,
                                                                      icon: AmityChatSettingsItem.leave.icon,
                                                                      title: AmityChatSettingsItem.leave.title,
                                                                     description: nil,
                                                                      titleTextColor: AmityColorSet.alert)
            settingsItems.append(.textContent(content: itemDeleteChatContent))
            
            // MARK: Separator
            settingsItems.append(.separator)

        default: // Group chat
            if let isCanEditGroupChannel = isCanEditGroupChannel, isCanEditGroupChannel { // Case : Moderator roles (delete channel, edit channel)
                // MARK: Group profile (Group chat [Moderator roles])
                let itemEditGroupProfileContent = AmitySettingsItem.NavigationContent(identifier: AmityChatSettingsItem.groupProfile.identifier,
                                                                         icon: AmityChatSettingsItem.groupProfile.icon,
                                                                         title: AmityChatSettingsItem.groupProfile.title,
                                                                        description: nil)
                settingsItems.append(.navigationContent(content: itemEditGroupProfileContent))
                
                // MARK: Member list (Group Chat)
                let itemMembersContent = AmitySettingsItem.NavigationContent(identifier: AmityChatSettingsItem.members.identifier,
                                                                      icon: AmityChatSettingsItem.members.icon,
                                                                      title: AmityChatSettingsItem.members.title,
                                                                      description: nil)
                settingsItems.append(.navigationContent(content: itemMembersContent))
                
                // MARK: Muted or unmuted notification
                if let isNotificationEnabled = self.isNotificationEnabled {
                    let itemNotificationContent = AmitySettingsItem.TextContent(identifier: AmityChatSettingsItem.notification(isNotificationEnabled).identifier,
                                                                                icon: AmityChatSettingsItem.notification(isNotificationEnabled).icon,
                                                                                title: AmityChatSettingsItem.notification(isNotificationEnabled).title,
                                                                                description: nil)
                    settingsItems.append(.textContent(content: itemNotificationContent))
                }
                
                // ktb kk custom add menu Invite Via QR And Link
                // MARK: Invite Via QR And Link
                let iteminviteViaQRAndLink = AmitySettingsItem.NavigationContent(identifier: AmityChatSettingsItem.inviteViaQRAndLink.identifier,
                                                                           icon: AmityChatSettingsItem.inviteViaQRAndLink.icon,
                                                                      title: AmityChatSettingsItem.inviteViaQRAndLink.title,
                                                                      description: nil)
                settingsItems.append(.navigationContent(content: iteminviteViaQRAndLink))
                
                // MARK: Delete chat (1:1 Chat & Group chat [Moderator roles]) // [Mock]
                let itemDeleteChatContent = AmitySettingsItem.TextContent(identifier: AmityChatSettingsItem.delete(isCanEditGroupChannel).identifier,
                                                                          icon: AmityChatSettingsItem.delete(isCanEditGroupChannel).icon,
                                                                          title: AmityChatSettingsItem.delete(isCanEditGroupChannel).title,
                                                                          description: AmityChatSettingsItem.delete(isCanEditGroupChannel).description,
                                                                          titleTextColor: AmityColorSet.alert)
                settingsItems.append(.textContent(content: itemDeleteChatContent))
                
                // MARK: Separator
                settingsItems.append(.separator)
                
                // MARK: Leave chat (Group Chat)
                let itemLeaveChatContent = AmitySettingsItem.TextContent(identifier: AmityChatSettingsItem.leave.identifier,
                                                                         icon: AmityChatSettingsItem.leave.icon,
                                                                         title: AmityChatSettingsItem.leave.title,
                                                                        description: nil,
                                                                         titleTextColor: AmityColorSet.alert)
                settingsItems.append(.textContent(content: itemLeaveChatContent))
                
                
                // MARK: Separator
//                settingsItems.append(.separator)
            } else {
                // MARK: Member list (Group Chat)
                let itemMembersContent = AmitySettingsItem.NavigationContent(identifier: AmityChatSettingsItem.members.identifier,
                                                                      icon: AmityChatSettingsItem.members.icon,
                                                                      title: AmityChatSettingsItem.members.title,
                                                                      description: nil)
                settingsItems.append(.navigationContent(content: itemMembersContent))
                
                // MARK: Muted or unmuted notification
                if let isNotificationEnabled = self.isNotificationEnabled {
                    let itemNotificationContent = AmitySettingsItem.TextContent(identifier: AmityChatSettingsItem.notification(isNotificationEnabled).identifier,
                                                                                icon: AmityChatSettingsItem.notification(isNotificationEnabled).icon,
                                                                                title: AmityChatSettingsItem.notification(isNotificationEnabled).title,
                                                                                description: nil)
                    settingsItems.append(.textContent(content: itemNotificationContent))
                }
                
                // MARK: Invite via QR / Link (Group chat [Member roles]) [No action]
                let itemInviteViaQRAndLink = AmitySettingsItem.TextContent(identifier: AmityChatSettingsItem.inviteViaQRAndLink.identifier,
                                                                            icon: AmityChatSettingsItem.inviteViaQRAndLink.icon,
                                                                            title: AmityChatSettingsItem.inviteViaQRAndLink.title,
                                                                            description: nil)
                settingsItems.append(.textContent(content: itemInviteViaQRAndLink))
                
                // MARK: Separator
//                settingsItems.append(.separator)
                
                // MARK: Leave chat (Group Chat)
                let itemLeaveChatContent = AmitySettingsItem.TextContent(identifier: AmityChatSettingsItem.leave.identifier,
                                                                         icon: AmityChatSettingsItem.leave.icon,
                                                                         title: AmityChatSettingsItem.leave.title,
                                                                        description: nil,
                                                                         titleTextColor: AmityColorSet.alert)
                settingsItems.append(.textContent(content: itemLeaveChatContent))
                
                // MARK: Separator
                settingsItems.append(.separator)
            }
        }
        
        completion?(settingsItems)
    }
}
