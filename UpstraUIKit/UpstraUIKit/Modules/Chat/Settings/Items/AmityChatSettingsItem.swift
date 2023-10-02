//
//  AmityChatSettingsItem.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 2/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

enum AmityChatSettingsItem: Equatable {
    case report(Bool)
    case leave
    case delete
    case members
    case groupProfile
    case inviteUser
    case notification(Bool)
    
    var title: String {
        switch self {
        case .report(let isReported):
            if isReported {
                return AmityLocalizedStringSet.ChatSettings.unReportUser.localizedString
            }
            return AmityLocalizedStringSet.ChatSettings.reportUser.localizedString
        case .leave:
            return AmityLocalizedStringSet.ChatSettings.leaveChannel.localizedString
        case .delete:
            return "Delete chat"
        case .members:
            return AmityLocalizedStringSet.ChatSettings.member.localizedString
        case .groupProfile:
            return AmityLocalizedStringSet.ChatSettings.groupProfile.localizedString
        case .inviteUser:
            return AmityLocalizedStringSet.ChatSettings.inviteUser.localizedString
        case .notification(let isMuted):
            if isMuted {
                return AmityLocalizedStringSet.ChatSettings.mutedNotification.localizedString
            }
            return AmityLocalizedStringSet.ChatSettings.unmutedNotification.localizedString
        }
    }
    
    var description: String? {
        switch self {
        case .delete:
            return ""
        default:
            return nil
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .report:
            return UIColor(hex: "#292B32")
        case .leave:
            return UIColor(hex: "#FA4D30")
        case .delete:
            return UIColor(hex: "#FA4D30")
        case .members:
            return UIColor(hex: "#292B32")
        case .groupProfile:
            return UIColor(hex: "#292B32")
        case .inviteUser:
            return UIColor(hex: "#292B32")
        case .notification(_):
            return UIColor(hex: "#292B32")
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .groupProfile:
            return AmityIconSet.CommunitySettings.iconItemEditProfile
        case .members:
            return AmityIconSet.CommunitySettings.iconItemMembers
        case .report(let _):
            return AmityIconSet.UserSettings.iconItemReportUser
        case .inviteUser:
            return AmityIconSet.ChatSettings.iconInviteUser
        case .notification(let isMuted):
            if isMuted {
                return AmityIconSet.ChatSettings.iconUnmutedNotification
            }
            return AmityIconSet.ChatSettings.iconMutedNotification
        default:
            return nil
        }
    }
}
