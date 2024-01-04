//
//  AmityChannelPresence+Extension.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 4/1/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import AmitySDK

extension AmityChannelPresence: Hashable {
    
    public static func == (lhs: AmityChannelPresence, rhs: AmityChannelPresence) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(channelId)
        hasher.combine(userPresences)
        hasher.combine(isAnyMemberOnline)
    }
}

extension AmityUserPresence: Hashable {
    
    public static func == (lhs: AmityUserPresence, rhs: AmityUserPresence) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(isOnline)
        hasher.combine(lastHeartbeat)
        hasher.combine(userId)
    }
}
