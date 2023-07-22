//
//  ViewerStatisticsModel.swift
//  AmityUIKitLiveStream
//
//  Created by Thanaphat Thanawatpanya on 21/7/2566 BE.
//

import Foundation

struct ViewerStatisticsModel: Codable {
    let viewerCount: Int?
    let postId: String?
    
    enum CodingKeys: String, CodingKey {
        case viewerCount = "viewerCount"
        case postId = "postId"
    }
}
