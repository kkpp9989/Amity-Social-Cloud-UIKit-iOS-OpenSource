//
//  AmityNotificationTray.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 20/9/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation

// MARK: - AmityNotificationTray
public struct AmityNotificationTrayModel: Codable {
    let totalPages: Int
    let nextPage: Int?
    let data: [NotificationTray]
}

// MARK: - Datum
public struct NotificationTray: Codable {
    var hasRead: Bool
    let lastUpdate: Int
    let parentTargetID, lastActionID: String
    let lastActionSegmentNo: Int?
    let verb, avatarCustomURL, description: String
    let imageURL: String
    let vTaridUid, targetType: String
    let actorsCount: Int
    let targetName: String
    let actors: [Actor]
    let targetID: String

    enum CodingKeys: String, CodingKey {
        case hasRead, lastUpdate
        case parentTargetID = "parentTargetId"
        case lastActionID = "lastActionId"
        case lastActionSegmentNo, verb
        case avatarCustomURL = "avatarCustomUrl"
        case description
        case imageURL = "imageUrl"
        case vTaridUid = "v_tarid_uid"
        case targetType, actorsCount, targetName, actors
        case targetID = "targetId"
    }
    
    func getTargetType() -> NotificationTargetType? {
        switch targetType {
        case "post":
            return NotificationTargetType.post
        case "comment":
            return NotificationTargetType.comment
        case "community":
            return NotificationTargetType.community
        default:
            return nil
        }
    }
}

// MARK: - Actor
public struct Actor: Codable {
    let name: String
}

// MARK: - AmityNotificationUnreadCount
struct AmityNotificationUnreadCount: Codable {
    let data: DataClass
}

// MARK: - DataClass
struct DataClass: Codable {
    let totalUnreadCount: Int
}

// MARK: - Enum of target type
public enum NotificationTargetType: String {
    case post = "post"
    case comment = "comment"
    case community = "community"
}
