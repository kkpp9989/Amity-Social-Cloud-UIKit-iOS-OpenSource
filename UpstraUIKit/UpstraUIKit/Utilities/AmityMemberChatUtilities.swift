//
//  AmityMemberChatUtilities.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 28/9/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation
import AmitySDK

struct AmityMemberChatUtilities {

    struct Conversation {
        static func getOtherUserByMemberShip(channelId : String, completion: @escaping (_ user: AmityUser?) -> Void) {
            let membershipParticipation = AmityChannelMembership(client: AmityUIKitManager.client, andChannel: channelId)
            let currentMemberList = membershipParticipation.getMembers(filter: .all, sortBy: .firstCreated, roles: []).observe { collection, change, error in
                print("------> error: \(error?.localizedDescription)")
                let object = collection.allObjects()
                if object.count > 0 {
                    let currentLoginedUserId = AmityUIKitManagerInternal.shared.currentUserId
                    let otherMember = object.filter { member in
                        return member.userId != currentLoginedUserId
                    }
                    if otherMember.count > 0, let otherMemberModel = otherMember[0].user {
                        completion(otherMemberModel)
                    } else {
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            }
        }
    }
}

public enum AmityMemberChatStatus {
    case available
    case offline
    case doNotDisturb
    case inTheOffice
    case workFromHome
    case inAMeeting
    case onLeave
    case outSick
}
