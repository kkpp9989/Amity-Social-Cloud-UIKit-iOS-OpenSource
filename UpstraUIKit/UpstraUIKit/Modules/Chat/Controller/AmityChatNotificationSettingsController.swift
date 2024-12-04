//
//  AmityChatNotificationSettingsController.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 2/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import AmitySDK
import UIKit

protocol AmityChatNotificationSettingsControllerProtocol {
    func retrieveNotificationSettings(completion: ((Result<AmityChannelNotificationSettings, Error>) -> Void)?)
    func enableNotificationSettings(completion: AmityRequestCompletion?)
    func disableNotificationSettings(completion: AmityRequestCompletion?)
}

final class AmityChatNotificationSettingsController: AmityChatNotificationSettingsControllerProtocol {
    
    private let repository: AmityChannelRepository
    private let channelId: String
    private let notificationManager: AmityChannelNotificationsManager
    
    init(withChannelId _channelId: String) {
        channelId = _channelId
        repository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
        notificationManager = repository.notificationManagerForChannel(withId: _channelId)
    }
    
    func retrieveNotificationSettings(completion: ((Result<AmityChannelNotificationSettings, Error>) -> Void)?) {
        notificationManager.getSettings { settings, error in
            if let notificationSettings = settings {
                completion?(.success(notificationSettings))
            } else {
                completion?(.failure(error ?? AmityError.unknown))
            }
        }
    }
    
    func enableNotificationSettings(completion: AmityRequestCompletion?) {
        notificationManager.enable(completion: completion)
    }
    
    func disableNotificationSettings(completion: AmityRequestCompletion?) {
        notificationManager.disable(completion: completion)
    }
    
}

