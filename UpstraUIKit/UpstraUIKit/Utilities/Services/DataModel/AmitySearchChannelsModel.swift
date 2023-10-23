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
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case displayName
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
