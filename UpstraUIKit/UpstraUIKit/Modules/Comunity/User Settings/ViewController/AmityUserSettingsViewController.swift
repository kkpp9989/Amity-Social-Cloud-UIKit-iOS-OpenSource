//
//  AmityUserSettingsViewController.swift
//  AmityUIKit
//
//  Created by Hamlet on 28.05.21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit

final class AmityUserSettingsViewController: AmityViewController {

    // MARK: - IBOutlet Properties
    @IBOutlet weak var settingTableView: AmitySettingsItemTableView!
    
    // MARK: - Properties
    private var screenViewModel: AmityUserSettingsScreenViewModelType!
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    
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
        // [Custom for ONE Krungthai][Improvement] Move fetch user setting and add retrieve notification settings in viewWill appear for update data when back from each edit setting
        screenViewModel.action.fetchUserSettings()
        screenViewModel.action.retrieveNotifcationSettings()
        
        // Set color navigation bar by custom theme
        theme?.setBackgroundNavigationBar()
    }
    
    static func make(withUserId userId: String)->  AmityUserSettingsViewController{
        let userNotificationController = AmityUserNotificationSettingsController()
        let viewModel: AmityUserSettingsScreenViewModelType = AmityUserSettingsScreenViewModel(userId: userId, userNotificationController: userNotificationController)
        
        let vc = AmityUserSettingsViewController(nibName: AmityUserSettingsViewController.identifier, bundle: AmityUIKitManager.bundle)
        vc.screenViewModel = viewModel
        return vc
    }
    
    // MARK: - Setup view
    private func setupView() {
        view.backgroundColor = AmityColorSet.backgroundColor
        title = AmityLocalizedStringSet.General.settings.localizedString
    }
    
    private func setupSettingTableView() {
        settingTableView.actionHandler = { [weak self] settingsItem in
            self?.handleActionItem(settingsItem: settingsItem)
        }
    }
    
    private func handleActionItem(settingsItem: AmitySettingsItem) {
        switch settingsItem {
        case .textContent(let content):
            guard let item = AmityUserSettingsItem(rawValue: content.identifier) else { return }
            switch item {
            case .unfollow:
                let userName = screenViewModel?.dataSource.user?.displayName ?? ""
                let alertTitle = "\(AmityLocalizedStringSet.UserSettings.itemUnfollow.localizedString) \(userName)"
                
                let message = String.localizedStringWithFormat(AmityLocalizedStringSet.UserSettings.UserSettingsMessages.unfollowMessage.localizedString, userName)
                
                AmityAlertController.present(
                    title: alertTitle,
                    message: message,
                    actions: [.cancel(handler: nil),
                              .custom(title: AmityLocalizedStringSet.UserSettings.itemUnfollow.localizedString,
                                      style: .destructive, handler: { [weak self] in
                                          self?.screenViewModel.action.unfollowUser()
                                      })],
                    from: self)
            case .report:
                screenViewModel.action.reportUser()
            case .unreport:
                screenViewModel.action.unreportUser()
            case .inviteViaQRAndLink:
                // ktb kk goto ahare qr from user setting
                AmityEventHandler.shared.gotoKTBShareQR(v:self ,url: "AmityUserSetting")
            case .basicInfo, .manage, .editProfile, .notification:
                break
            }
        case .navigationContent(let content):
            guard let item = AmityUserSettingsItem(rawValue: content.identifier) else { return }
            switch item {
            case .editProfile:
                AmityEventHandler.shared.editUserDidTap(from: self, userId: screenViewModel.dataSource.userId)
            case .notification: // [Custom for ONE Krungthai][Improvement] Add handle action of notification setting item
                let vc = AmityUserNotificationSettingsViewController.make()
                navigationController?.pushViewController(vc, animated: true)
            case .inviteViaQRAndLink:
                // ktb kk goto share qr from user setting
                //AmityEventHandler.shared.gotoKTBShareQR(v:self ,url: "AmityUserSetting")
                AmityEventHandler.shared.gotoKTBShareQR(v: self, type: .userProfile, id: screenViewModel?.dataSource.user?.userId ?? "", title: screenViewModel?.dataSource.user?.displayName ?? "", desc: screenViewModel?.dataSource.user?.displayName ?? "")
            case .basicInfo, .manage, .report, .unfollow, .unreport:
                break
            }
        default: break
        }
    }
}

extension AmityUserSettingsViewController: AmityUserSettingsScreenViewModelDelegate {
    func screenViewModelDidFlagUserSuccess() {
        AmityHUD.show(.success(message: AmityLocalizedStringSet.HUD.reportSent.localizedString))
    }
    
    func screenViewModelDidUnflagUserSuccess() {
        AmityHUD.show(.success(message: AmityLocalizedStringSet.HUD.unreportSent.localizedString))
    }
    
    func screenViewModel(_ viewModel: AmityUserSettingsScreenViewModelType, didGetSettingMenu settings: [AmitySettingsItem]) {
        settingTableView.settingsItems = settings
    }
    
    func screenViewModel(_ viewModel: AmityUserSettingsScreenViewModelType, didGetUserSuccess user: AmityUserModel) {
    }
    
    func screenViewModelDidUnfollowUser() {
    }
    
    func screenViewModelDidUnfollowUserFail() {
        let userName = screenViewModel?.dataSource.user?.displayName ?? ""
        let title = String.localizedStringWithFormat(AmityLocalizedStringSet.UserSettings.UserSettingsMessages.unfollowFailTitle.localizedString, userName)
        AmityAlertController.present(title: title,
                                   message: AmityLocalizedStringSet.somethingWentWrongWithTryAgain.localizedString,
                                   actions: [.ok(handler: nil)], from: self)
    }
    
    func screenViewModel(_ viewModel: AmityUserSettingsScreenViewModelType, failure error: AmityError) {
        switch error {
        case .unknown:
            AmityHUD.show(.error(message: AmityLocalizedStringSet.HUD.somethingWentWrong.localizedString))
        default:
            break
        }
    }
}
