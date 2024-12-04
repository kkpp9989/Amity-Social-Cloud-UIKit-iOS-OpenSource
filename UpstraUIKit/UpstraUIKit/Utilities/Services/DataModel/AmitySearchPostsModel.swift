//
//  AmitySearchPostsModel.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 19/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation

// MARK: - AmitySearchPostsModel
struct AmitySearchPostsModel: Codable {
    var postIDS: [String]

    enum CodingKeys: String, CodingKey {
        case postIDS = "postIds"
    }
}
