//
//  ResponseGetViewerCountModel.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 24/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation

struct ResponseGetViewerCountModel: Codable {
    let viewerCount: Int?
    let postId: String?
    
    enum CodingKeys: String, CodingKey {
        case viewerCount = "viewerCount"
        case postId = "postId"
    }
}

// MARK: - ViewerStatisticsModel
struct ViewerStatisticsModel: Codable {
    let statusCode: Int?
    let data: ViewersModel?
}

// MARK: - ViewersModel
struct ViewersModel: Codable {
    let userIDS: [String]?
    let viewerCount: Int?

    enum CodingKeys: String, CodingKey {
        case userIDS = "userIds"
        case viewerCount
    }
}
