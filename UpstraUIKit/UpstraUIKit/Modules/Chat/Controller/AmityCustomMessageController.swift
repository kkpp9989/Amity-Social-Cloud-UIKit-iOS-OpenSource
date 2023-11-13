//
//  AmityCustomMessageController.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 10/11/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation
import AmitySDK

public enum AmityGroupChatEvent {
    case addMember
    case removeMember
    case leavedChat
    case joinedChat
}

final class AmityCustomMessageController {
    
    private let channelId: String
    private let messageRepository: AmityMessageRepository
    
    init(channelId: String) {
        self.channelId = channelId
        messageRepository = AmityMessageRepository(client: AmityUIKitManagerInternal.shared.client)
    }
    
    func send(event: AmityGroupChatEvent, subjectUserName: String, objectUserName: String?, completion: @escaping (Result<AmityMessageModel, Error>) -> Void) {
        var customData: [String: String]
        
        switch event {
        case .addMember:
            customData = ["text": "\(subjectUserName) invited \(objectUserName ?? "-") to joined this chat"]
        case .removeMember:
            customData = ["text": "\(subjectUserName) removed \(objectUserName ?? "-") from this chat"]
        case .leavedChat:
            customData = ["text": "\(subjectUserName) left this chat"]
        case .joinedChat:
            customData = ["text": "\(subjectUserName) joined this chat"]
        }
        
        // Send message
        let options = AmityCustomMessageCreateOptions(subChannelId: channelId, data: customData)
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: messageRepository.createCustomMessage, parameters: options) { message, error in
            if let message = message {
                let messageModel = AmityMessageModel(object: message)
                completion(.success(messageModel))
            } else if let error = error {
                completion(.failure(error))
            }
        }
    }
}
