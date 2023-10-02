//
//  ChatSettingViewController.swift
//  AmityUIKit
//
//  Created by min khant on 05/05/2021.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

final class AmityChatSettingsViewController: AmityViewController {
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var settingTableView: AmitySettingsItemTableView!
    
    // MARK: - Properties
    private var screenViewModel: AmityChatSettingsScreenViewModelType!
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    
    static func make(channelId: String) -> AmityViewController {
        let vc = AmityChatSettingsViewController(
            nibName: AmityChatSettingsViewController.identifier,
            bundle: AmityUIKitManager.bundle)
        vc.screenViewModel = AmityChatSettingsScreenViewModel(channelId: channelId)
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
//        guard let community = screenViewModel.dataSource.community else { return }
//        switch settingsItem {
//        case .navigationContent(let content):
//            guard let item = AmityCommunitySettingsItem(rawValue: content.identifier) else { return }
//            switch item {
//            case .editProfile:
//                let vc = AmityCommunityEditorViewController.make(withCommunityId: community.communityId)
//                vc.delegate = self
//                let nav = UINavigationController(rootViewController: vc)
//                nav.modalPresentationStyle = .fullScreen
//                present(nav, animated: true, completion: nil)
//            case .members:
//                let vc = AmityCommunityMemberSettingsViewController.make(community: community.object)
//                navigationController?.pushViewController(vc, animated: true)
//            case .notification:
//                let vc = AmityCommunityNotificationSettingsViewController.make(community: community)
//                navigationController?.pushViewController(vc, animated: true)
//            case .postReview:
//                let vc = AmityPostReviewSettingsViewController.make(communityId: community.communityId)
//                navigationController?.pushViewController(vc, animated: true)
//            default:
//                break
//            }
//        case .textContent(let content):
//            guard let item = AmityCommunitySettingsItem(rawValue: content.identifier) else { return }
//            switch item {
//            case .leaveCommunity:
//                let alertTitle = AmityLocalizedStringSet.CommunitySettings.alertTitleLeave.localizedString
//                let actionTitle = AmityLocalizedStringSet.General.leave.localizedString
//                var description = AmityLocalizedStringSet.CommunitySettings.alertDescLeave.localizedString
//                let isOnlyOneMember = screenViewModel.dataSource.community?.membersCount == 1
//                if screenViewModel.dataSource.isModerator(userId: AmityUIKitManagerInternal.shared.currentUserId) {
//                    description = AmityLocalizedStringSet.CommunitySettings.alertDescModeratorLeave.localizedString
//                }
//
//                AmityAlertController.present(
//                    title: alertTitle,
//                    message: description.localizedString,
//                    actions: [.cancel(handler: nil), .custom(title: actionTitle.localizedString, style: .destructive, handler: { [weak self] in
//                        guard let strongSelf = self else { return }
//                        if isOnlyOneMember {
//                            let description = AmityLocalizedStringSet.CommunitySettings.alertDescLastModeratorLeave.localizedString
//                            AmityAlertController.present(title: alertTitle, message: description, actions: [.cancel(handler: nil), .custom(title: AmityLocalizedStringSet.General.close.localizedString, style: .destructive, handler: { [weak self] in
//                                    self?.screenViewModel.action.closeCommunity()
//                            })],
//                            from: strongSelf)
//                        } else {
//                            strongSelf.screenViewModel.action.leaveCommunity()
//                        }
//                    })],
//                    from: self)
//            case .closeCommunity:
//                AmityAlertController.present(
//                    title: AmityLocalizedStringSet.CommunitySettings.alertTitleClose.localizedString,
//                    message: AmityLocalizedStringSet.CommunitySettings.alertDescClose.localizedString,
//                    actions: [.cancel(handler: nil),
//                              .custom(title: AmityLocalizedStringSet.General.close.localizedString,
//                                      style: .destructive,
//                                      handler: { [weak self] in
//                                        self?.screenViewModel.action.closeCommunity()
//                                      })],
//                    from: self)
//            default:
//                break
//            }
//        default:
//            break
//        }
    }
}

extension AmityChatSettingsViewController: AmityChatSettingsScreenViewModelDelegate {
    
    func screenViewModel(_ viewModel: AmityChatSettingsScreenViewModelType, didGetSettingMenu settings: [AmitySettingsItem]) {
        settingTableView.settingsItems = settings
    }
    
    func screenViewModel(_ viewModel: AmityChatSettingsScreenViewModelType, didGetChannelSuccess channel: AmityChannel) {
        title = viewModel.dataSource.title
    }
    
    func screenViewModel(_ viewModel: AmityChatSettingsScreenViewModelType, failure error: AmityError) {
        // Not ready
    }
}
