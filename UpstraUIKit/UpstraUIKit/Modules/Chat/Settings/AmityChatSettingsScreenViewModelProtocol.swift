//
//  AmityChatSettingsScreenViewModelProtocol.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 2/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//
/* [Custom for ONE Krungthai][Improvement] Change processing same as AmityCommunitySettingsScreenViewModelProtocol */

import UIKit
import AmitySDK

protocol AmityChatSettingsScreenViewModelDelegate: AnyObject {
    func screenViewModel(_ viewModel: AmityChatSettingsScreenViewModelType, didGetSettingMenu settings: [AmitySettingsItem])
    func screenViewModel(_ viewModel: AmityChatSettingsScreenViewModelType, didGetChannelSuccess channel: AmityChannelModel)
    func screenViewModelDidUpdateNotificationSettings(_ viewModel: AmityChatSettingsScreenViewModelType, isNotificationEnabled: Bool)
    func screenViewModelDidUpdateNotificationSettingsFail(_ viewModel: AmityChatSettingsScreenViewModelType, error: Error)
    func screenViewModelDidUpdateReportUser(_ viewModel: AmityChatSettingsScreenViewModelType, isReported: Bool)
    func screenViewModelDidUpdateReportUserFail(_ viewModel: AmityChatSettingsScreenViewModelType, error: Error)
}

protocol AmityChatSettingsScreenViewModelDataSource {
    var channel: AmityChannelModel? { get }
    var channelId: String { get }
    var title: String? { get }
}

protocol AmityChatSettingsScreenViewModelAction {
    func retrieveChannel()
    func retrieveNotificationSettings()
    func retrieveSettingsMenu()
    func changeNotificationSettings()
    func changeReportUserStatus()
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
