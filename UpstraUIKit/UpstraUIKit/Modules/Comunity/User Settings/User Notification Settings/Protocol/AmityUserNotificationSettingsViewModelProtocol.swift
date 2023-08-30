//
//  AmityUserNotificationSettingsViewModelProtocol.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 30/8/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

enum AmityUserNotificationSettingsItem: String {
    case mainToggle
    
    var identifier: String {
        return self.rawValue
    }
    
    var title: String {
        switch self {
        case .mainToggle:
            return AmityLocalizedStringSet.UserSettings.UserNotificationsSettings.titleNotifications.localizedString
        }
    }
    
    var description: String? {
        switch self {
        case .mainToggle:
            return AmityLocalizedStringSet.UserSettings.UserNotificationsSettings.descriptionNotifications.localizedString
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .mainToggle:
            return AmityIconSet.UserSettings.iconNotificationSettings
        }
    }
    
}

protocol AmityUserNotificationSettingsViewModelDelegate: AnyObject {
    func screenViewModel(_ viewModel: AmityUserNotificationSettingsScreenViewModelType, didUpdateSettingItem settings: [AmitySettingsItem])
    func screenViewModel(_ viewModel: AmityUserNotificationSettingsScreenViewModelType, didUpdateLoadingState state: AmityLoadingState)
    func screenViewModel(_ viewModel: AmityUserNotificationSettingsScreenViewModelType, didFailWithError error: AmityError)
}

protocol AmityUserNotificationSettingsViewModelDataSource {
    var isSocialNotificationEnabled: Bool { get }
}

protocol AmityUserNotificationSettingsViewModelAction {
    func retrieveNotifcationSettings()
    func enableNotificationSetting()
    func disableNotificationSetting()
}

protocol AmityUserNotificationSettingsScreenViewModelType: AmityUserNotificationSettingsViewModelAction, AmityUserNotificationSettingsViewModelDataSource {
    var delegate: AmityUserNotificationSettingsViewModelDelegate? { get set }
    var action: AmityUserNotificationSettingsViewModelAction { get }
    var dataSource: AmityUserNotificationSettingsViewModelDataSource { get }
}

extension AmityUserNotificationSettingsScreenViewModelType {
    var action: AmityUserNotificationSettingsViewModelAction { return self }
    var dataSource: AmityUserNotificationSettingsViewModelDataSource { return self }
}
