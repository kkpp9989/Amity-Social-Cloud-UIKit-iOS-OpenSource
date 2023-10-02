//
//  AmityChatInfoController.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 2/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation
import AmitySDK

protocol AmityChatInfoControllerProtocol {
    func getChannel(_ completion: @escaping (Result<AmityChannelModel, AmityError>) -> Void)
}

final class AmityChatInfoController: AmityChatInfoControllerProtocol {
    
    private let repository: AmityChannelRepository
    private var channelId: String
    private var token: AmityNotificationToken?
    private var channel: AmityObject<AmityChannel>?
    
    init(channelId: String) {
        self.channelId = channelId
        repository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
    }
    
    func getChannel(_ completion: @escaping (Result<AmityChannelModel, AmityError>) -> Void) {
        // Get channel by channelId
        channel = repository.getChannel(channelId)
        token = channel?.observe({ channel, error in
            guard let object = channel.snapshot else {
                if let error = AmityError(error: error) {
                    completion(.failure(error))
                }
                return
            }
            
            let model = AmityChannelModel(object: object)
            completion(.success(model))
        })
    }
}
