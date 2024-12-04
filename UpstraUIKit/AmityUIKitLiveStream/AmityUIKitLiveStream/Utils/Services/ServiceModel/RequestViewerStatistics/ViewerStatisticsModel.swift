//
//  ViewerStatisticsModel.swift
//  AmityUIKitLiveStream
//
//  Created by Thanaphat Thanawatpanya on 21/7/2566 BE.
//

import Foundation

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

