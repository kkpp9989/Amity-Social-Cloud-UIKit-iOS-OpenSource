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
    let channelsPermission: [ChannelUserPermission]?
    let paging: Paging?
    
    enum CodingKeys: String, CodingKey {
        case channels
        case channelsPermission = "channelUsers"
        case paging
    }
}

// MARK: - Channel
struct Channel: Codable {
    let channelId: String?
    let channelCustomId: String?
    let displayName: String?
    let channelType: String?
    let avatarFileId: String?
    var membership: String?

    enum CodingKeys: String, CodingKey {
        case channelId = "channelInternalId"
        case channelCustomId = "channelPublicId"
        case displayName
        case channelType = "type"
        case avatarFileId
    }
}

// MARK: - Channel User Permission
struct ChannelUserPermission: Codable {
    let membership: String?
    let channelId: String?
    
    enum CodingKeys: String, CodingKey {
        case membership
        case channelId
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
