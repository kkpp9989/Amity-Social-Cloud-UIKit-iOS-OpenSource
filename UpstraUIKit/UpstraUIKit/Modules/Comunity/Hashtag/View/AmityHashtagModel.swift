//
//  AmityHashtagModel.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 19/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation

//  MARK: - AmityHashtagModel
public struct HashtagModel: Codable {
    let hashtag: [AmityHashtagModel]?
    
    enum CodingKeys: String, CodingKey {
        case hashtag = "hashtags"
    }
}

//  MARK: - Hashtag
public struct AmityHashtagModel: Codable {
    let text: String?
    let count: Int?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case text = "text"
        case count = "count"
        case createdAt = "createdAt"
    }
}
