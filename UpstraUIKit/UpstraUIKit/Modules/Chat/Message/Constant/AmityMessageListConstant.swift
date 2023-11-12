//
//  AmityMessageListConstant.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 5/8/2563 BE.
//  Copyright © 2563 Amity Communication. All rights reserved.
//

import UIKit

public enum AmityMessageTypes: CaseIterable {
    case textIncoming
    case textOutgoing
    case imageIncoming
    case imageOutgoing
    case audioIncoming
    case audioOutgoing
    case videoIncoming
    case videoOutgoing
    case fileIncoming
    case fileOutgoing
    case replyIncoming
    case replyOutgoing
    case operation
    
    var identifier: String {
        switch self {
        case .textIncoming: return "textIncoming"
        case .textOutgoing: return "textOutgoing"
        case .imageIncoming: return "imageIncoming"
        case .imageOutgoing: return "imageOutgoing"
        case .audioIncoming: return "audioIncoming"
        case .audioOutgoing: return "audioOutgoing"
        case .videoIncoming: return "videoIncoming"
        case .videoOutgoing: return "videoOutgoing"
        case .fileIncoming: return "fileIncoming"
        case .fileOutgoing: return "fileOutgoing"
        case .replyIncoming: return "replyIncoming"
        case .replyOutgoing: return "replyOutgoing"
        case .operation: return "operation"
        }
    }
    
    var nib: UINib {
        switch self {
        case .textIncoming:
            return UINib(nibName: "AmityMessageTextIncomingTableViewCell", bundle: AmityUIKitManager.bundle)
        case .textOutgoing:
            return UINib(nibName: "AmityMessageTextOutgoingTableViewCell", bundle: AmityUIKitManager.bundle)
        case .imageIncoming:
            return UINib(nibName: "AmityMessageImageIncomingTableViewCell", bundle: AmityUIKitManager.bundle)
        case .imageOutgoing:
            return UINib(nibName: "AmityMessageImageOutgoingTableViewCell", bundle: AmityUIKitManager.bundle)
        case .audioIncoming:
            return UINib(nibName: "AmityMessageAudioIncomingTableViewCell", bundle: AmityUIKitManager.bundle)
        case .audioOutgoing:
            return UINib(nibName: "AmityMessageAudioOutgoingTableViewCell", bundle: AmityUIKitManager.bundle)
        case .videoIncoming:
            return UINib(nibName: "AmityMessageVideoIncomingTableViewCell", bundle: AmityUIKitManager.bundle)
        case .videoOutgoing:
            return UINib(nibName: "AmityMessageVideoOutgoingTableViewCell", bundle: AmityUIKitManager.bundle)
        case .fileIncoming:
            return UINib(nibName: "AmityMessageFileIncomingTableViewCell", bundle: AmityUIKitManager.bundle)
        case .fileOutgoing:
            return UINib(nibName: "AmityMessageFileOutgoingTableViewCell", bundle: AmityUIKitManager.bundle)
        case .replyIncoming:
            return UINib(nibName: "AmityMessageReplyIncomingTableViewCell", bundle: AmityUIKitManager.bundle)
        case .replyOutgoing:
            return UINib(nibName: "AmityMessageReplyOutgoingTableViewCell", bundle: AmityUIKitManager.bundle)
        case .operation:
            return UINib(nibName: "AmityOperationChatTableViewCell", bundle: AmityUIKitManager.bundle)
        }
    }
    
    var `class`: AmityMessageCellProtocol.Type {
        switch self {
        case .textIncoming, .textOutgoing:
            return AmityMessageTextTableViewCell.self
        case .imageIncoming:
            return AmityMessageImageIncomingTableViewCell.self
        case .imageOutgoing:
            return AmityMessageImageOutgoingTableViewCell.self
        case .audioIncoming, .audioOutgoing:
            return AmityMessageAudioTableViewCell.self
        case .videoIncoming:
            return AmityMessageVideoIncomingTableViewCell.self
        case .videoOutgoing:
            return AmityMessageVideoOutgoingTableViewCell.self
        case .fileIncoming:
            return AmityMessageFileIncomingTableViewCell.self
        case .fileOutgoing:
            return AmityMessageFileOutgoingTableViewCell.self
        case .replyIncoming, .replyOutgoing:
            return AmityMessageReplyTableViewCell.self
        case .operation:
            return AmityOperationChatTableViewCell.self
        }
    }
    
}
