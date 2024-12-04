//
//  ResponseDeleteChannelModel.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 4/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation

struct ResponseDeleteChannelModel: Codable {
    let status: String?
    let code: Int?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case status = "status"
        case code = "code"
        case message = "message"
    }
}
