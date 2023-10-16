//
//  AmitySearchChannelsModel.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 16/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation

// MARK: - SearchChannelsDataModel
struct SearchChannelsModel: Codable {
    let channels: [Channel]?
    let paging: Paging?
}

// MARK: - Channel
struct Channel: Codable {
    let id: String?
    let isDistinct: Bool?
    let type: TypeEnum?
    let tags: [String]?
    let lastActivity, updatedAt, createdAt: String?
    let rateLimitWindow: Int?
    let displayName: String?
    let messageAutoDeleteEnabled: Bool?
    let autoDeleteMessageByFlagLimit: Int?
    let isDeleted: Bool?
    let path, channelID, channelInternalID, channelPublicID: String?
    let isMuted, isRateLimited: Bool?
    let memberCount, messageCount, moderatorMemberCount: Int?
    let avatarFileID: String?
    let metadata: ChannelMetadata?
    let messagePreviewID: JSONNull?
    let muteTimeout: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case isDistinct, type, tags, lastActivity, updatedAt, createdAt, rateLimitWindow, displayName, messageAutoDeleteEnabled, autoDeleteMessageByFlagLimit, isDeleted, path
        case channelID = "channelId"
        case channelInternalID = "channelInternalId"
        case channelPublicID = "channelPublicId"
        case isMuted, isRateLimited, memberCount, messageCount, moderatorMemberCount
        case avatarFileID = "avatarFileId"
        case metadata
        case messagePreviewID = "messagePreviewId"
        case muteTimeout
    }
}

// MARK: - ChannelMetadata
struct ChannelMetadata: Codable {
    let userIDS: [String]?
    let isDirectChat: Bool?
    let sdkType, creatorID: String?
    let userIDMember: [String]?

    enum CodingKeys: String, CodingKey {
        case userIDS = "userIds"
        case isDirectChat
        case sdkType = "sdk_type"
        case creatorID = "creatorId"
        case userIDMember = "user_id_member"
    }
}

enum TypeEnum: String, Codable {
    case community = "community"
    case conversation = "conversation"
}

// MARK: - Paging
struct Paging: Codable {
    let next: String?
}
