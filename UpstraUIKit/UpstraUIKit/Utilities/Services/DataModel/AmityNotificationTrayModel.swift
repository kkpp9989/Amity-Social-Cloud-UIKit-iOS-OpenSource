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
    let totalPages, nextPage: Int
    let data: [NotificationTray]
}

// MARK: - Datum
public struct NotificationTray: Codable {
    let vTaridUid, description, verb, imageURL: String
    let avatarCustomURL, targetType, targetName: String
    let hasRead: Bool
    let lastUpdate: Int
    let actors: Actors
    let actorsCount: Int
    let parentTargetID, targetID, lastActionID: String
    let lastActionSegmentNo: Int

    enum CodingKeys: String, CodingKey {
        case vTaridUid = "v_tarid_uid"
        case description, verb
        case imageURL = "imageUrl"
        case avatarCustomURL = "avatarCustomUrl"
        case targetType, targetName, hasRead, lastUpdate, actors, actorsCount
        case parentTargetID = "parentTargetId"
        case targetID = "targetId"
        case lastActionID = "lastActionId"
        case lastActionSegmentNo
    }
}

// MARK: - Actors
public struct Actors: Codable {
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
