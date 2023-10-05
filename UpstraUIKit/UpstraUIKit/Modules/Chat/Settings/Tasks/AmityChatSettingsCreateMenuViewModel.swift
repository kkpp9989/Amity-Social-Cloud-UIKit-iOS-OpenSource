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
    func createSettingsItems(isNotificationEnabled: Bool, isReportedUserByMe: Bool, _ completion: (([AmitySettingsItem]) -> Void)?)
}

final class AmityChatSettingsCreateMenuViewModel: AmityChatSettingsCreateMenuViewModelProtocol {

    // MARK: - Properties
    private let channel: AmityChannelModel
    private var isReportedUserByMe: Bool = false
    private var isNotificationEnabled: Bool = false
    private var isUserModerator: Bool = false
    
    // MARK: - Controller
    private let dispatchCounter = DispatchGroup()
    
    init(channel: AmityChannelModel) {
        self.channel = channel
    }
    
    func createSettingsItems(isNotificationEnabled: Bool, isReportedUserByMe: Bool, _ completion: (([AmitySettingsItem]) -> Void)?) {
        self.isNotificationEnabled = isNotificationEnabled
        self.isReportedUserByMe = isReportedUserByMe
        prepareDataSource(completion)
    }
    
    private func prepareDataSource(_ completion: (([AmitySettingsItem]) -> Void)?) {
        var settingsItems = [AmitySettingsItem]()
        
        switch channel.channelType {
        case .conversation: // 1:1 Chat
            // MARK: Muted or unmuted notification [Mock]
            let itemNotificationContent = AmitySettingsItem.TextContent(identifier: AmityChatSettingsItem.notification(isNotificationEnabled).identifier,
                                                                        icon: AmityChatSettingsItem.notification(isNotificationEnabled).icon,
                                                                        title: AmityChatSettingsItem.notification(isNotificationEnabled).title,
                                                                        description: nil)
            settingsItems.append(.textContent(content: itemNotificationContent))
            
            // MARK: Invite user (1:1 Chat)
            let itemInviteUserContent = AmitySettingsItem.TextContent(identifier: AmityChatSettingsItem.inviteUser.identifier,
                                                                  icon: AmityChatSettingsItem.inviteUser.icon,
                                                                  title: AmityChatSettingsItem.inviteUser.title,
                                                                  description: nil)
            settingsItems.append(.textContent(content: itemInviteUserContent))
            
            // MARK: Report / unreport User (1:1 Chat) [Mock]
            var itemReportUserContent = AmitySettingsItem.TextContent(identifier: AmityChatSettingsItem.report(isReportedUserByMe).identifier,
                                                               icon: AmityChatSettingsItem.report(isReportedUserByMe).icon,
                                                               title: AmityChatSettingsItem.report(isReportedUserByMe).title,
                                                               description: nil)
            settingsItems.append(.textContent(content: itemReportUserContent))
            
            // MARK: Separator
            settingsItems.append(.separator)
            
            // MARK: Delete chat (1:1 Chat & Group chat [Moderator roles]) // [Mock]
            var itemDeleteChatContent = AmitySettingsItem.TextContent(identifier: AmityChatSettingsItem.delete.identifier,
                                                                      icon: AmityChatSettingsItem.delete.icon,
                                                                      title: AmityChatSettingsItem.delete.title,
                                                                      description: nil,
                                                                      titleTextColor: AmityColorSet.alert)
            settingsItems.append(.textContent(content: itemDeleteChatContent))
            
            // MARK: Separator
            settingsItems.append(.separator)
        default: // Group chat
            if isUserModerator {
                // MARK: Group profile (Group chat [Moderator roles])
                // Not ready
                
                // MARK: Member list (Group Chat)
                let itemMembersContent = AmitySettingsItem.NavigationContent(identifier: AmityChatSettingsItem.members.identifier,
                                                                      icon: AmityChatSettingsItem.members.icon,
                                                                      title: AmityChatSettingsItem.members.title,
                                                                      description: nil)
                settingsItems.append(.navigationContent(content: itemMembersContent))
                
                // MARK: Muted or unmuted notification [Mock]
                let itemNotificationContent = AmitySettingsItem.TextContent(identifier: AmityChatSettingsItem.notification(isNotificationEnabled).identifier,
                                                                            icon: AmityChatSettingsItem.notification(isNotificationEnabled).icon,
                                                                            title: AmityChatSettingsItem.notification(isNotificationEnabled).title,
                                                                            description: nil)
                settingsItems.append(.textContent(content: itemNotificationContent))
                
                // MARK: Separator
                settingsItems.append(.separator)
                
                // MARK: Leave chat (Group Chat)
                // Not ready
                
                // MARK: Separator
                settingsItems.append(.separator)
                
                // MARK: Delete chat (1:1 Chat & Group chat [Moderator roles]) // [Mock]
                var itemDeleteChatContent = AmitySettingsItem.TextContent(identifier: AmityChatSettingsItem.delete.identifier,
                                                                          icon: AmityChatSettingsItem.delete.icon,
                                                                          title: AmityChatSettingsItem.delete.title,
                                                                          description: "Deleting this chat will remove all messages and files. This cannot be undone.",
                                                                          titleTextColor: AmityColorSet.alert)
                settingsItems.append(.textContent(content: itemDeleteChatContent))
                
                // MARK: Separator
                settingsItems.append(.separator)
            } else {
                // MARK: Member list (Group Chat)
                let itemMembersContent = AmitySettingsItem.NavigationContent(identifier: AmityChatSettingsItem.members.identifier,
                                                                      icon: AmityChatSettingsItem.members.icon,
                                                                      title: AmityChatSettingsItem.members.title,
                                                                      description: nil)
                settingsItems.append(.navigationContent(content: itemMembersContent))
                
                // MARK: Muted or unmuted notification [Mock]
                let itemNotificationContent = AmitySettingsItem.TextContent(identifier: AmityChatSettingsItem.notification(isNotificationEnabled).identifier,
                                                                            icon: AmityChatSettingsItem.notification(isNotificationEnabled).icon,
                                                                            title: AmityChatSettingsItem.notification(isNotificationEnabled).title,
                                                                            description: nil)
                settingsItems.append(.textContent(content: itemNotificationContent))
                
                // MARK: Invite via QR / Link (Group chat [Member roles])
                // Not ready
                
                // MARK: Separator
                settingsItems.append(.separator)
                
                // MARK: Leave chat (Group Chat)
                // Not ready
                
                // MARK: Separator
                settingsItems.append(.separator)
            }
        }
        
        completion?(settingsItems)
    }
    
}
