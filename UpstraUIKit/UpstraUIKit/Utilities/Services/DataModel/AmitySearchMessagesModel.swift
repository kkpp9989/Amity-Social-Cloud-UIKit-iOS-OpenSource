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
    let success: Bool
    let messageIDS: [String]

    enum CodingKeys: String, CodingKey {
        case success
        case messageIDS = "messageIds"
    }
}
