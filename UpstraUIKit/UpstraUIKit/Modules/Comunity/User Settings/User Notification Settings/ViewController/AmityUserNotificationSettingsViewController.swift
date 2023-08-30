//
//  AmityUserNotificationSettingsViewController.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 30/8/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

class AmityUserNotificationSettingsViewController: AmityViewController {
    
    @IBOutlet var tableView: AmitySettingsItemTableView!
    
    private var screenViewModel: AmityUserNotificationSettingsScreenViewModelType!
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initial ONE Krungthai Custom theme
        theme = ONEKrungthaiCustomTheme(viewController: self)

        screenViewModel.delegate = self
        setupView()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        screenViewModel.action.retrieveNotifcationSettings()
        
        // Set color navigation bar by custom theme
        theme?.setBackgroundNavigationBar()
    }
    
    static func make() -> AmityUserNotificationSettingsViewController {
        let notificationSettingsController = AmityUserNotificationSettingsController()
        let viewModel: AmityUserNotificationSettingsScreenViewModelType = AmityUserNotificationSettingsScreenViewModel()
        let vc = AmityUserNotificationSettingsViewController(nibName: AmityUserNotificationSettingsViewController.identifier, bundle: AmityUIKitManager.bundle)
        vc.screenViewModel = viewModel
        return vc
    }
}

// MARK: - Setup view
private extension AmityUserNotificationSettingsViewController {
    
    private func setupView() {
        title = AmityLocalizedStringSet.UserSettings.UserNotificationsSettings.titleNavigationbar.localizedString
    }
    
    private func setupTableView() {
        tableView.isEmptyViewHidden = Reachability.shared.isConnectedToNetwork
        tableView.updateEmptyView(title: AmityLocalizedStringSet.noInternetConnection.localizedString, subtitle: nil, image: AmityIconSet.noInternetConnection)
        tableView.actionHandler = { [weak self] settingsItem in
            self?.handleActionItem(settingsItem: settingsItem)
        }
    }
    
    private func handleActionItem(settingsItem: AmitySettingsItem) {
        switch settingsItem {
        case .toggleContent(let content):
            if content.isToggled {
                screenViewModel.action.enableNotificationSetting()
            } else {
                screenViewModel.action.disableNotificationSetting()
            }
        case .navigationContent(let content):
            guard let item = AmityUserNotificationSettingsItem(rawValue: content.identifier) else { return }
            switch item {
            case .mainToggle:
                assertionFailure("Item type must be a navigation type")
            }
        default:
            break
        }
    }
}

extension AmityUserNotificationSettingsViewController: AmityUserNotificationSettingsViewModelDelegate {
    func screenViewModel(_ viewModel: AmityUserNotificationSettingsScreenViewModelType, didUpdateSettingItem settings: [AmitySettingsItem]) {
        tableView.settingsItems = settings
    }
    
    func screenViewModel(_ viewModel: AmityUserNotificationSettingsScreenViewModelType, didUpdateLoadingState state: AmityLoadingState) {
        switch state {
        case .loading:
            tableView.showLoadingIndicator()
        case .loaded:
            tableView.tableFooterView = nil
        case .initial:
            break
        }
    }
    
    func screenViewModel(_ viewModel: AmityUserNotificationSettingsScreenViewModelType, didFailWithError error: AmityError) {
        
        AmityHUD.hide { [weak self] in
            guard let strongSelf = self else { return }
            let title = strongSelf.screenViewModel.dataSource.isSocialNotificationEnabled ? AmityLocalizedStringSet.CommunitySettings.alertFailTitleTurnNotificationOn.localizedString :  AmityLocalizedStringSet.CommunitySettings.alertFailTitleTurnNotificationOff.localizedString
            AmityAlertController.present(title: title,
                                       message: AmityLocalizedStringSet.somethingWentWrongWithTryAgain.localizedString,
                                       actions: [.ok(handler: nil)], from: strongSelf)
        }
    }
}
