//
//  ChatSettingViewController.swift
//  AmityUIKit
//
//  Created by min khant on 05/05/2021.
//  Copyright © 2021 Amity. All rights reserved.
//
/* [Custom for ONE Krungthai][Improvement] Change processing same as AmityCommunitySettingsViewController and add new action some setting */

import UIKit
import AmitySDK

// MARK: - Viewcontroller
final class AmityChatSettingsViewController: AmityViewController {
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var settingTableView: AmitySettingsItemTableView!
    
    // MARK: - Properties
    private var screenViewModel: AmityChatSettingsScreenViewModelType!
    private var isCanEditGroupChannel: Bool?
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    
    static func make(channelId: String) -> AmityViewController {
        let vc = AmityChatSettingsViewController(
            nibName: AmityChatSettingsViewController.identifier,
            bundle: AmityUIKitManager.bundle)

        let chatNotificationController = AmityChatNotificationSettingsController(withChannelId: channelId)
        let channelController = AmityChannelController(channelId: channelId)
        let userController = AmityChatUserController(channelId: channelId)
        vc.screenViewModel = AmityChatSettingsScreenViewModel(channelId: channelId,
                                                              chatNotificationController: chatNotificationController,
                                                              channelController: channelController,
                                                              userController: userController)
        return vc
    }
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initial ONE Krungthai Custom theme
        theme = ONEKrungthaiCustomTheme(viewController: self)
        
        screenViewModel.delegate = self
        setupView()
        setupSettingTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        screenViewModel.action.retrieveChannel()
        screenViewModel.action.retrieveNotificationSettings()
        
        // Set color navigation bar by custom theme
        theme?.setBackgroundNavigationBar()
    }
    
    private func setupView() {
        view.backgroundColor = AmityColorSet.backgroundColor
    }
        
    private func setupSettingTableView() {
        settingTableView.actionHandler = { [weak self] settingsItem in
            self?.handleActionItem(settingsItem: settingsItem)
        }
    }
    
    private func handleActionItem(settingsItem: AmitySettingsItem) {
        guard let channel = screenViewModel.dataSource.channel else { return }
        switch settingsItem {
        case .textContent(content: let content):
            switch content.identifier {
            case "report": // (1:1 Chat)
                AmityHUD.show(.loading)
                screenViewModel.action.changeReportUserStatus()
            case "leave": // (Group chat)
                let alertTitle = AmityLocalizedStringSet.ChatSettings.leaveChatTitle.localizedString
                var description: String
                if let isCanEditGroupChannel = screenViewModel.dataSource.isCanEditGroupChannel, isCanEditGroupChannel {
                    if channel.memberCount == 1 {
                        description = AmityLocalizedStringSet.ChatSettings.leaveChatModeratorRoleWithOneMemberGroupChatMessage.localizedString
                        AmityAlertController.present(
                            title: alertTitle,
                            message: description,
                            actions: [.cancel(handler: nil), .custom(title: AmityLocalizedStringSet.General.close.localizedString, style: .destructive, handler: { [weak self] in
                                guard let strongSelf = self else { return }
                                strongSelf.screenViewModel.action.deleteChat()
                            })],
                            from: self)
                    } else {
                        description = AmityLocalizedStringSet.ChatSettings.leaveChatModeratorRoleWithManyMemberGroupChatMessage.localizedString
                        AmityAlertController.present(
                            title: alertTitle,
                            message: description,
                            actions: [.cancel(handler: nil), .custom(title: AmityLocalizedStringSet.General.leave.localizedString, style: .destructive, handler: { [weak self] in
                                guard let strongSelf = self else { return }
                                strongSelf.screenViewModel.action.leaveChat()
                            })],
                            from: self)
                    }
                } else {
                    description = AmityLocalizedStringSet.ChatSettings.leaveChatMemberRoleGroupChatMessage.localizedString
                    AmityAlertController.present(
                        title: alertTitle,
                        message: description,
                        actions: [.cancel(handler: nil), .custom(title: AmityLocalizedStringSet.General.leave.localizedString, style: .destructive, handler: { [weak self] in
                            guard let strongSelf = self else { return }
                            strongSelf.screenViewModel.action.leaveChat()
                        })],
                        from: self)
                }
            case "delete": // (1:1 Chat, Group Chat [Moderator role])
                let alertTitle = AmityLocalizedStringSet.ChatSettings.deleteChatTitle.localizedString
                var description: String
                if channel.channelType == .conversation {
                    description = AmityLocalizedStringSet.ChatSettings.deleteConversationChatMessage.localizedString
                } else {
                    description = AmityLocalizedStringSet.ChatSettings.deleteGroupChatMessage.localizedString
                }
                
                AmityAlertController.present(
                    title: alertTitle,
                    message: description,
                    actions: [.cancel(handler: nil), .custom(title: AmityLocalizedStringSet.General.delete.localizedString, style: .destructive, handler: { [weak self] in
                        guard let strongSelf = self else { return }
                        strongSelf.screenViewModel.action.deleteChat()
                    })],
                    from: self)
            case "members": // (Group Chat)
                // Open members list
                // Not ready
                break
            case "groupProfile": // (Group Chat [Moderator role])
                // Open group profile setting
                // Not ready
                break
            case "inviteUser": // (1:1 Chat)
                AmityChannelEventHandler.shared.channelCreateNewChat(
                    from: self,
                    completionHandler: { [weak self] storeUsers in
                        guard let weakSelf = self else { return }
                        print("[Storeusers] :\(storeUsers)")
                })
                // Not ready
                break
            case "notification": // (1:1 Chat, Group Chat)
                AmityHUD.show(.loading)
                screenViewModel.action.changeNotificationSettings()
                break
            default:
                break
            }
            
        case .navigationContent(content: let content):
            switch content.identifier {
            case "report":
                // Not ready
                break
            case "leave":
                // Not ready
                break
            case "delete":
                // Not ready
                break
            case "members":
                // Not ready
                break
            case "groupProfile":
                // Not ready
                break
            case "inviteUser":
                // Not ready
                break
            case "notification":
                // Not ready
                break
            default:
                break
            }
        default:
            break
        }

    }
}

// MARK: - Delegate
extension AmityChatSettingsViewController: AmityChatSettingsScreenViewModelDelegate {
    // MARK: - Get setting menu delegate
    func screenViewModel(_ viewModel: AmityChatSettingsScreenViewModelType, didGetSettingMenu settings: [AmitySettingsItem]) {
        settingTableView.settingsItems = settings
    }
    
    // MARK: - Get channel delegate
    func screenViewModel(_ viewModel: AmityChatSettingsScreenViewModelType, didGetChannelSuccess channel: AmityChannelModel) {
        title = viewModel.dataSource.title
    }
    
    func screenViewModel(_ viewModel: AmityChatSettingsScreenViewModelType, failure error: AmityError) {
        // Not ready
    }
    
    // MARK: - Update notification delegate
    func screenViewModelDidUpdateNotificationSettings(_ viewModel: AmityChatSettingsScreenViewModelType, isNotificationEnabled: Bool) {
        AmityHUD.show(.success(message: "\(isNotificationEnabled ? AmityLocalizedStringSet.ChatSettings.unmutedNotification.localizedString : AmityLocalizedStringSet.ChatSettings.mutedNotification.localizedString)"))
    }
    
    func screenViewModelDidUpdateNotificationSettingsFail(_ viewModel: AmityChatSettingsScreenViewModelType, error: Error) {
        AmityHUD.show(.error(message: error.localizedDescription))
    }
    
    // MARK: - Update report user status delegate
    func screenViewModelDidUpdateReportUser(_ viewModel: AmityChatSettingsScreenViewModelType, isReported: Bool) {
        AmityHUD.show(.success(message: "\(isReported ? AmityLocalizedStringSet.ChatSettings.reportSent.localizedString : AmityLocalizedStringSet.ChatSettings.unreportSent.localizedString)"))
    }
    
    func screenViewModelDidUpdateReportUserFail(_ viewModel: AmityChatSettingsScreenViewModelType, error: Error) {
        AmityHUD.show(.error(message: error.localizedDescription))
    }
    
    // MARK: - Leave channel delegate
    func screenViewModelDidLeaveChannel(_ viewModel: AmityChatSettingsScreenViewModelType) {
        // Handle back to view some each case
        if let chatHomePage = navigationController?.viewControllers.first(where: { $0.isKind(of: AmityChatHomePageViewController.self) }) {
            navigationController?.popToViewController(chatHomePage, animated: true)
        } else {
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    func screenViewModelDidLeaveChannelFail(_ viewModel: AmityChatSettingsScreenViewModelType, error: Error) {
        AmityAlertController.present(
            title: AmityLocalizedStringSet.ChatSettings.unableLeaveChatTitle.localizedString,
            message: AmityLocalizedStringSet.ChatSettings.unableLeaveChatMessage.localizedString,
            actions: [.ok(handler: nil)],
            from: self)
    }
    
    // MARK: - Delete channel delegate
    func screenViewModelDidDeleteChannel(_ viewModel: AmityChatSettingsScreenViewModelType) {
        // Handle back to view some each case
        if let chatHomePage = navigationController?.viewControllers.first(where: { $0.isKind(of: AmityChatHomePageViewController.self) }) {
            navigationController?.popToViewController(chatHomePage, animated: true)
        } else {
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    func screenViewModelDidDeleteChannelFail(_ viewModel: AmityChatSettingsScreenViewModelType, error: Error) {
        AmityAlertController.present(
            title: AmityLocalizedStringSet.ChatSettings.unableDeleteChatTitle.localizedString,
            message: AmityLocalizedStringSet.ChatSettings.unableDeleteChatMessage.localizedString,
            actions: [.ok(handler: nil)],
            from: self)
    }
    
}
