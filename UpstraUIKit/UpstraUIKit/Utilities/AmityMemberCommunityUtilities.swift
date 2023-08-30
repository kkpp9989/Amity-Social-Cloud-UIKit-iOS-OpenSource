//
//  AmityMemberCommunityUtilities.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 25/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation
import AmitySDK

struct AmityMemberCommunityUtilities {
    static func isModeratorUserInCommunity(withUserId userId: String, communityId: String) -> Bool {
        let membershipParticipation = AmityCommunityMembership(client: AmityUIKitManagerInternal.shared.client, andCommunityId: communityId)
        let member = membershipParticipation.getMember(withId: userId)
        return member?.hasModeratorRole ?? false
    }
    
    static func isImportantCommunityByCommunityModel(community: AmityCommunityModel) -> Bool {
        if let metadata = community.metadata, let isImportant = metadata["isImportant"] as? Bool, isImportant {
            return true
        } else {
            return false
        }
    }
}
