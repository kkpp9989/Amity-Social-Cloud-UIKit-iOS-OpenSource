//
//  LimitFileSizeSettingModel.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 10/1/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import Foundation

struct LimitFileSizeSettingModel: Codable {
    let limitFileSize: Double? // .mb
    let configId: String?
    
    enum CodingKeys: String, CodingKey {
        case limitFileSize = "fileSize"
        case configId
    }
}
