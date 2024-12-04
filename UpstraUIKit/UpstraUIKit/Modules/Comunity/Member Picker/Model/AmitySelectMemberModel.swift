//
//  AmitySelectMemberModel.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 30/8/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit
import AmitySDK

public enum AmitySelectType {
    case user, community, channel
}

public final class AmitySelectMemberModel: Equatable {
    
    public static func == (lhs: AmitySelectMemberModel, rhs: AmitySelectMemberModel) -> Bool {
        return lhs.userId == rhs.userId
    }
    
    public let userId: String
    public let displayName: String?
    public var email = String()
    public var isSelected: Bool = false
    public let avatarURL: String
    public let defaultDisplayName: String = AmityLocalizedStringSet.General.anonymous.localizedString
    public let type: AmitySelectType
    public var isCurrnetUser: Bool {
        return userId == AmityUIKitManagerInternal.shared.client.currentUserId
    }
    public var object: AmityChannel? = nil
    public var originalId: String?
    
    init(object: AmityUser) {
        self.userId = object.userId
        self.displayName = object.displayName
        if let metadata = object.metadata {
            self.email = metadata["email"] as? String ?? ""
        }
        self.avatarURL = object.getAvatarInfo()?.fileURL ?? ""
        self.type = .user
    }
    
    init(object: AmityCommunityMembershipModel) {
        self.userId = object.userId
        self.displayName = object.displayName
        self.avatarURL = object.avatarURL
        self.type = .community
    }
    
    init(object: AmityChannelMembershipModel) {
        self.userId = object.userId
        self.displayName = object.displayName
        self.avatarURL = object.avatarURL
        self.type = .channel
    }
    
    init(object: AmityFollowRelationship, type: AmityFollowerViewType) {
        let data = type == .followers ? object.sourceUser : object.targetUser
        self.userId = data?.userId ?? ""
        self.displayName = data?.displayName ?? ""
        self.avatarURL = data?.getAvatarInfo()?.fileURL ?? ""
        if let metadata = data?.metadata {
            self.email = metadata["email"] as? String ?? ""
        }
        self.type = .user
    }
    
    init(object: AmityChannel) {
        self.userId = object.channelId
        self.displayName = object.displayName
        self.avatarURL = object.getAvatarInfo()?.fileURL ?? ""
        self.object = object
        self.type = .channel
    }
    
    init(object: Channel, avatarURL: String?) { // From search channel API
        self.userId = object.channelId ?? ""
        self.displayName = object.displayName ?? ""
        self.avatarURL = avatarURL ?? ""
        self.type = .channel
    }
}
