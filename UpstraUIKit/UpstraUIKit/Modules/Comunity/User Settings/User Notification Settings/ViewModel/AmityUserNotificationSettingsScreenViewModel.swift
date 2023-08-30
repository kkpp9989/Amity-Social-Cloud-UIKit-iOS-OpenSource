//
//  AmityUserNotificationSettingsScreenViewModel.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 30/8/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import AmitySDK
import UIKit

final class AmityUserNotificationSettingsScreenViewModel: AmityUserNotificationSettingsScreenViewModelType {

    weak var delegate: AmityUserNotificationSettingsViewModelDelegate?
    
    // MARK: - Controller
    private let userNotificationController = AmityUserNotificationSettingsController()
    
    // MARK: - Properties
    private(set) var isSocialNotificationEnabled: Bool = false
    private var settingsItems: [AmitySettingsItem] = []
    
    private func prepareSettingItems(notification: AmityUserNotificationSettings) {
        var items: [AmitySettingsItem] = []
        
        let global = AmitySettingsItem.ToggleContent(
            identifier: AmityUserNotificationSettingsItem.mainToggle.identifier,
            iconContent: nil,
            title: AmityUserNotificationSettingsItem.mainToggle.title,
            description: AmityUserNotificationSettingsItem.mainToggle.description,
            isToggled: isSocialNotificationEnabled)
        items.append(.toggleContent(content: global))
        items.append(.separator)
        
        settingsItems = items
        delegate?.screenViewModel(self, didUpdateSettingItem: settingsItems)
    }
}

// MARK: - Delegate
extension AmityUserNotificationSettingsScreenViewModel {
    
    func enableNotificationSetting() {
        let modules: [AmityUserNotificationModule] = [AmityUserNotificationModule(moduleType: .social, isEnabled: true, roleFilter: nil)]
        userNotificationController.enableNotificationSettings(modules: modules) { [weak self] (success, error) in
            guard let strongSelf = self else { return }
            if success {
                strongSelf.retrieveNotifcationSettings()
            } else {
                strongSelf.delegate?.screenViewModel(strongSelf, didFailWithError: AmityError(error: error) ?? .unknown)
            }
        }
    }
    
    func disableNotificationSetting() {
        let modules: [AmityUserNotificationModule] = [AmityUserNotificationModule(moduleType: .social, isEnabled: false, roleFilter: nil)]
        userNotificationController.disableNotificationSettings(modules: modules) { [weak self] (success, error) in
            guard let strongSelf = self else { return }
            if success {
                self?.retrieveNotifcationSettings()
            } else {
                strongSelf.delegate?.screenViewModel(strongSelf, didFailWithError: AmityError(error: error) ?? .unknown)
            }
        }
    }
    
    func retrieveNotifcationSettings() {
        userNotificationController.retrieveNotificationSettings { [weak self] (result) in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let notification):
                if let socialModule = notification.modules.first(where: { $0.moduleType == .social }) {
                    strongSelf.isSocialNotificationEnabled = socialModule.isEnabled
                    strongSelf.prepareSettingItems(notification: notification)
                }
                break
            case .failure:
                break
            }
        }
    }
}

