//
//  AmityChannelController.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 2/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation
import AmitySDK

protocol AmityChannelControllerProtocol {
    func getChannel(_ completion: @escaping (Result<AmityChannelModel, AmityError>) -> Void)
    func leaveChannel(_ completion: @escaping (_ result: ()?, _ error: Error?) -> Void)
    func deleteChannel(_ completion: @escaping (_ result: Bool?, _ error: Error?) -> Void)
}

final class AmityChannelController: AmityChannelControllerProtocol {
    
    private let repository: AmityChannelRepository
    private var channelId: String
    private var token: AmityNotificationToken?
    private var channel: AmityObject<AmityChannel>?
    
    init(channelId: String) {
        self.channelId = channelId
        repository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
    }
    
    func getChannel(_ completion: @escaping (Result<AmityChannelModel, AmityError>) -> Void) {
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
    
    func leaveChannel(_ completion: @escaping (_ result: ()?, _ error: Error?) -> Void) {
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: repository.leaveChannel, parameters: channelId) { success, error in
            completion(success, error)
        }
    }
    
    func deleteChannel(_ completion: @escaping (_ result: Bool?, _ error: Error?) -> Void) {
        let serviceRequest = RequestChat()
        serviceRequest.requestDeleteChat(channelId: channelId) { result in
            switch result {
            case .success:
                // [Custom for ONE Krungthai] Post observer isDeletingChat for prevent app crash when delete chat then collection observer send old data
                NotificationCenter.default.post(name: Notification.Name.Chat.isDeletingChat, object: nil)
                print("[Channel List] postObserver: Chat.isDeletingChat")
                completion(true, nil)
            case .failure(let failure):
                completion(false, failure)
            }
        }
    }
}
