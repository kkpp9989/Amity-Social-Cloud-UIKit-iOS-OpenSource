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
    let data: [NotificationTray]
}

// MARK: - Datum
public struct NotificationTray: Codable {
    let hasRead: Bool
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

// MARK: - Encode/decode helpers
class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }

    public var hashValue: Int {
        return 0
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}
