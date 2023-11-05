//
//  AmitySearchMessagesModel.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 10/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation

// MARK: - AmitySearchMessagesModel
struct AmitySearchMessagesModel: Codable {
    let messages: [Message]
    let paging: Pagings
}

// MARK: - Message
struct Message: Codable {
    let messageID: String?
    let parentID: String?
    let channelID, channelPublicID: String?
    let reactionCount: Int?
    let hasFlags: Bool?
    let childCount: Int?
    let isDeleted: Bool?
    let channelType, path: String?
    let segment: Int?
    let creatorID, creatorPublicID, dataType, createdAt: String?
    let updatedAt, messageFeedID: String?
    let data: DataText?
    let flagCount: Int?

    enum CodingKeys: String, CodingKey {
        case messageID = "messageId"
        case parentID = "parentId"
        case channelID = "channelId"
        case channelPublicID = "channelPublicId"
        case reactionCount, hasFlags, childCount, isDeleted, channelType, path, segment
        case creatorID = "creatorId"
        case creatorPublicID = "creatorPublicId"
        case dataType, createdAt, updatedAt
        case messageFeedID = "messageFeedId"
        case data, flagCount
    }
}

// MARK: - DataClass
struct DataText: Codable {
    let text: String?
}

// MARK: - Paging
struct Pagings: Codable {
    let previous: String?
    let next: String?
}
