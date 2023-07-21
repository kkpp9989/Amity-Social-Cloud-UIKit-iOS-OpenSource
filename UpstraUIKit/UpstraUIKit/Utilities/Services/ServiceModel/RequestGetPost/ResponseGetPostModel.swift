//
//  ResponseGetPostModel.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 19/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation

struct ResponseGetPostModel: Codable {
    let postId: String?
    let status: Int?
    
    enum CodingKeys: String, CodingKey {
        case postId = "postId"
        case status = "status"
    }
}
