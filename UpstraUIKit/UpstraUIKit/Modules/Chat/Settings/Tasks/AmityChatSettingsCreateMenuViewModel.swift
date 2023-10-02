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
    func createSettingsItems(_ completion: (([AmitySettingsItem]) -> Void)?)
}

final class AmityChatSettingsCreateMenuViewModel: AmityChatSettingsCreateMenuViewModelProtocol {

    // MARK: - Properties
    private let channel: AmityChannel
    private let isUserModerator: Bool = false
    private let isReportedUser: Bool = false
    private let isMutedNotification: Bool = false
    
    // MARK: - Controller
    private let dispatchCounter = DispatchGroup()
    
    init(channel: AmityChannel) {
        self.channel = channel
    }
    
    func createSettingsItems(_ completion: (([AmitySettingsItem]) -> Void)?) {
        
        dispatchCounter.notify(queue: .main) { [weak self] in
            self?.prepareDataSource(completion)
        }
    }
    
    private func prepareDataSource(_ completion: (([AmitySettingsItem]) -> Void)?) {
        var settingsItems = [AmitySettingsItem]()
        
        switch channel.channelType {
        case .conversation: // 1:1 Chat
            // MARK: Muted or unmuted notification [Mock]
            let itemNotificationContent = AmitySettingsItem.TextContent(identifier: "",
                                                                        icon: AmityChatSettingsItem.notification(isMutedNotification).icon,
                                                                        title: AmityChatSettingsItem.notification(isMutedNotification).title,
                                                                        description: nil)
            settingsItems.append(.textContent(content: itemNotificationContent))
            
            // MARK: Invite user (1:1 Chat)
            let itemInviteUserContent = AmitySettingsItem.TextContent(identifier: "",
                                                                  icon: AmityChatSettingsItem.inviteUser.icon,
                                                                  title: AmityChatSettingsItem.inviteUser.title,
                                                                  description: nil)
            settingsItems.append(.textContent(content: itemInviteUserContent))
            
            // MARK: Report / unreport User (1:1 Chat) [Mock]
            var itemReportUserContent = AmitySettingsItem.TextContent(identifier: "",
                                                               icon: AmityChatSettingsItem.report(isReportedUser).icon,
                                                               title: AmityChatSettingsItem.report(isReportedUser).title,
                                                               description: nil)
            settingsItems.append(.textContent(content: itemReportUserContent))
            
            // MARK: Separator
            settingsItems.append(.separator)
            
            // MARK: Delete chat (1:1 Chat & Group chat [Moderator roles]) // [Mock]
            var itemDeleteChatContent = AmitySettingsItem.TextContent(identifier: "",
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
                let itemMembersContent = AmitySettingsItem.NavigationContent(identifier: "",
                                                                      icon: AmityChatSettingsItem.members.icon,
                                                                      title: AmityChatSettingsItem.members.title,
                                                                      description: nil)
                settingsItems.append(.navigationContent(content: itemMembersContent))
                
                // MARK: Muted or unmuted notification [Mock]
                let itemNotificationContent = AmitySettingsItem.TextContent(identifier: "",
                                                                            icon: AmityChatSettingsItem.notification(isMutedNotification).icon,
                                                                            title: AmityChatSettingsItem.notification(isMutedNotification).title,
                                                                            description: nil)
                settingsItems.append(.textContent(content: itemNotificationContent))
                
                // MARK: Separator
                settingsItems.append(.separator)
                
                // MARK: Leave chat (Group Chat)
                // Not ready
                
                // MARK: Separator
                settingsItems.append(.separator)
                
                // MARK: Delete chat (1:1 Chat & Group chat [Moderator roles]) // [Mock]
                var itemDeleteChatContent = AmitySettingsItem.TextContent(identifier: "",
                                                                          icon: AmityChatSettingsItem.delete.icon,
                                                                          title: AmityChatSettingsItem.delete.title,
                                                                          description: "Deleting this chat will remove all messages and files. This cannot be undone.",
                                                                          titleTextColor: AmityColorSet.alert)
                settingsItems.append(.textContent(content: itemDeleteChatContent))
                
                // MARK: Separator
                settingsItems.append(.separator)
            } else {
                // MARK: Member list (Group Chat)
                let itemMembersContent = AmitySettingsItem.NavigationContent(identifier: "",
                                                                      icon: AmityChatSettingsItem.members.icon,
                                                                      title: AmityChatSettingsItem.members.title,
                                                                      description: nil)
                settingsItems.append(.navigationContent(content: itemMembersContent))
                
                // MARK: Muted or unmuted notification [Mock]
                let itemNotificationContent = AmitySettingsItem.TextContent(identifier: "",
                                                                            icon: AmityChatSettingsItem.notification(isMutedNotification).icon,
                                                                            title: AmityChatSettingsItem.notification(isMutedNotification).title,
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
