//
//  AmityUserSettingsItem.swift
//  AmityUIKit
//
//  Created by Hamlet on 28.05.21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit

enum AmityUserSettingsItem: String {
    case manage
    case unfollow
    case report
    case unreport
    case basicInfo
    case editProfile
    case notification // [Custom for ONE Krungthai][Improvement] Add notification case for handle notification setting item
    
    var identifier: String {
        return self.rawValue
    }
    
    var title: String {
        switch self {
        case .manage:
            return AmityLocalizedStringSet.UserSettings.itemHeaderManageInfo.localizedString
        case .unfollow:
            return AmityLocalizedStringSet.UserSettings.itemUnfollow.localizedString
        case .report:
            return AmityLocalizedStringSet.UserSettings.itemReportUser.localizedString
        case .unreport:
            return AmityLocalizedStringSet.UserSettings.itemUnreportUser.localizedString
        case .basicInfo:
            return AmityLocalizedStringSet.UserSettings.itemHeaderBasicInfo.localizedString
        case .editProfile:
            return AmityLocalizedStringSet.UserSettings.itemEditProfile.localizedString
        case .notification: // [Custom for ONE Krungthai][Improvement] Add notification case for get title of notification setting item
            return AmityLocalizedStringSet.UserSettings.itemNotifications.localizedString
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .unfollow:
            return AmityIconSet.UserSettings.iconItemUnfollowUser
        case .report, .unreport:
            return AmityIconSet.UserSettings.iconItemReportUser
        case .editProfile:
            return AmityIconSet.UserSettings.iconItemEditProfile
        case .notification: // [Custom for ONE Krungthai][Improvement] Add notification case for get image of notification setting item
            return AmityIconSet.UserSettings.iconNotification
        case .basicInfo, .manage:
            return nil
        }
    }
}
