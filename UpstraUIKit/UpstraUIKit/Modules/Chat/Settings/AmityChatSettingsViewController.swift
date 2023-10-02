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

        let chatNotificationController = AmityChatNotificationSettingsController(withChannelId: channelId)
        let chatInfoController = AmityChatInfoController(channelId: channelId)
        vc.screenViewModel = AmityChatSettingsScreenViewModel(channelId: channelId,
                                                              chatNotificationController: chatNotificationController,
                                                              chatInfoController: chatInfoController)
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
            case "report":
                screenViewModel.action.changeReportUserStatus()
            case "leave":
                // Open alert controller
                break
            case "delete":
                // Open alert controller
                break
            case "members":
                // Open members list
                break
            case "groupProfile":
                // Open group profile setting
                break
            case "inviteUser":
                // Open invite user
                break
            case "notification":
                AmityHUD.show(.loading)
                screenViewModel.action.changeNotificationSettings()
                break
            default:
                break
            }
            
        case .navigationContent(content: let content):
            switch content.identifier {
            case "report":
                break
            case "leave":
                break
            case "delete":
                break
            case "members":
                break
            case "groupProfile":
                break
            case "inviteUser":
                break
            case "notification":
                break
            default:
                break
            }
        default:
            break
        }

    }
}

extension AmityChatSettingsViewController: AmityChatSettingsScreenViewModelDelegate {

    func screenViewModel(_ viewModel: AmityChatSettingsScreenViewModelType, didGetSettingMenu settings: [AmitySettingsItem]) {
        settingTableView.settingsItems = settings
    }
    
    func screenViewModel(_ viewModel: AmityChatSettingsScreenViewModelType, didGetChannelSuccess channel: AmityChannelModel) {
        title = viewModel.dataSource.title
    }
    
    func screenViewModel(_ viewModel: AmityChatSettingsScreenViewModelType, failure error: AmityError) {
        // Not ready
    }
    
    func screenViewModelDidUpdateNotificationSettings(_ viewModel: AmityChatSettingsScreenViewModelType, isNotificationEnabled: Bool) {
        AmityHUD.show(.success(message: "\(isNotificationEnabled ? "Unmuted" : "Muted")"))
    }
    
    func screenViewModelDidUpdateNotificationSettingsFail(_ viewModel: AmityChatSettingsScreenViewModelType, error: Error) {
        AmityHUD.show(.error(message: error.localizedDescription))
    }
}
