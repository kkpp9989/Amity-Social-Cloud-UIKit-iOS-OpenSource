//
//  AmityChatHomeParentScreenViewModel.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 8/2/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

class AmityChatHomeParentScreenViewModel: AmityChatHomeParentScreenViewModelType {
    
    // MARK: - Delegate
    weak var delegate: AmityChatHomeParentScreenViewModelDelegate?
    
    // MARK: - Controller
    private let channelRepository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
    
    // MARK: - Utilities
    private let dispatchGroup = DispatchGroup()
    
    // MARK: - Properties
    private var broadcastChannelCollectionToken: AmityNotificationToken?
    private var isHaveCreateBroadcastPermission: Bool = false
    
    func getCreateBroadcastMessagePermission() {
        // Query broadcast channels
        let query = AmityChannelQuery()
        query.filter = .userIsMember
        query.includeDeleted = false
        query.types = [AmityChannelQueryType.broadcast]
        let channelsCollection = channelRepository.getChannels(with: query)
        
        // Check each group that have channel-moderator role
        broadcastChannelCollectionToken = channelsCollection.observe { [weak self] (collection, change, error) in
            guard let strongSelf = self, collection.dataStatus == .fresh else { return }
            // Set default value back to false before get new one
            strongSelf.isHaveCreateBroadcastPermission = false
            
            // Get permission each channel
            let channelModels = collection.allObjects().map( { AmityChannelModel(object: $0) } )
            for channel in channelModels {
                strongSelf.dispatchGroup.enter()
                AmityUIKitManagerInternal.shared.client.hasPermission(.editChannel, forChannel: channel.channelId) { isHavePermission in
                    if isHavePermission {
                        strongSelf.isHaveCreateBroadcastPermission = true
                    }
                    strongSelf.dispatchGroup.leave()
                }
            }
            
            strongSelf.dispatchGroup.notify(queue: .main) {
                strongSelf.delegate?.screenViewModelDidGetCreateBroadcastMessagePermission(strongSelf, isHavePermission: strongSelf.isHaveCreateBroadcastPermission)
            }
        }
    }
}
