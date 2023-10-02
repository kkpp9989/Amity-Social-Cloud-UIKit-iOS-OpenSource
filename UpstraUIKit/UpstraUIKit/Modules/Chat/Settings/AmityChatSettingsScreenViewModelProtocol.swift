//
//  AmityChatSettingsScreenViewModelProtocol.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 2/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityChatSettingsScreenViewModelDelegate: AnyObject {
    func screenViewModel(_ viewModel: AmityChatSettingsScreenViewModelType, didGetSettingMenu settings: [AmitySettingsItem])
    func screenViewModel(_ viewModel: AmityChatSettingsScreenViewModelType, didGetChannelSuccess channel: AmityChannel)
}

protocol AmityChatSettingsScreenViewModelDataSource {
    var channel: AmityChannel? { get }
    var channelId: String { get }
    var title: String? { get }
}

protocol AmityChatSettingsScreenViewModelAction {
    func retrieveChannel()
    func retrieveNotificationSettings()
    func retrieveSettingsMenu()
}

protocol AmityChatSettingsScreenViewModelType: AmityChatSettingsScreenViewModelAction, AmityChatSettingsScreenViewModelDataSource {
    var action: AmityChatSettingsScreenViewModelAction { get }
    var dataSource: AmityChatSettingsScreenViewModelDataSource { get }
    var delegate: AmityChatSettingsScreenViewModelDelegate? { get set }
}

extension AmityChatSettingsScreenViewModelType {
    var action: AmityChatSettingsScreenViewModelAction { return self }
    var dataSource: AmityChatSettingsScreenViewModelDataSource { return self }
}
