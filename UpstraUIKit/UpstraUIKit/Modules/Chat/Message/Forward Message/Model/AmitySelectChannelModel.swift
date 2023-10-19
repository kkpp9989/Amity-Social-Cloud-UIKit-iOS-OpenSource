//
//  AmitySelectChannelModel.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 16/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

public final class AmitySelectChannelModel: Equatable {
    
    public static func == (lhs: AmitySelectChannelModel, rhs: AmitySelectChannelModel) -> Bool {
        return lhs.channelId == rhs.channelId
    }
    
    public let channelId: String
    public let channelType: AmityChannelType
    public let displayName: String
    public var email = String()
    public var isSelected: Bool = false
    public let avatarURL: String
    public let defaultDisplayName: String = AmityLocalizedStringSet.General.anonymous.localizedString
    public let object: AmityChannel
    
    init(object: AmityChannelModel) {
        self.channelId = object.channelId
        self.channelType = object.channelType
        self.displayName = object.displayName
        self.avatarURL = object.avatarURL
        self.object = object.object
    }
}
