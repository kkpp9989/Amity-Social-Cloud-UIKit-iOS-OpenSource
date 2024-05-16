//
//  AmityBroadcastMessageCreatorModel.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 31/1/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import AmitySDK

public enum AmityBroadcastMessageCreatorType {
    case text
    case image
    case imageWithCaption
    case file
}

class AmityBroadcastMessageCreatorModel {
    
    let broadcastType: AmityBroadcastMessageCreatorType
    let text: String?
    let medias: [AmityMedia]?
    let files: [AmityFile]?
    
    init(broadcastType: AmityBroadcastMessageCreatorType, text: String?, medias: [AmityMedia]?, files: [AmityFile]?) {
        self.broadcastType = broadcastType
        self.text = text
        self.medias = medias
        self.files = files
    }
}
