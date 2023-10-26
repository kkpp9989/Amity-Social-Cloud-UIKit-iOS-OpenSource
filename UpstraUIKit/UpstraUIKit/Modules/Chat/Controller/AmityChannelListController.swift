//
//  AmityChannelListController.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 16/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation
import AmitySDK

public enum AmityChannelListViewType {
    case conversation, groupchat
}

final class AmityChannelListController {
    
    typealias GroupChannel = [(key: String, value: [AmitySelectChannelModel])]
    
    private let repository: AmityChannelRepository
    private var collection: AmityCollection<AmityChannel>?
    private var token: AmityNotificationToken?
    
    private var channels: [AmitySelectChannelModel] = []
    var storeChannels: [AmitySelectChannelModel] = []
    
    init() {
        repository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
    }
    
    func fetchChannelList(type: AmityChannelListViewType, _ completion: @escaping (Result<GroupChannel, Error>) -> Void) {
        let query = AmityChannelQuery()
        query.filter = .userIsMember
        query.includeDeleted = false
        
        switch type {
        case .conversation:
            query.types = [AmityChannelQueryType.conversation]
        case .groupchat:
            query.types = [AmityChannelQueryType.community]
        }
        
        collection = repository.getChannels(with: query)
        token = collection?.observe { [weak self] (channelCollection, change, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                completion(.failure(error))
            } else {
                for index in 0..<channelCollection.count() {
                    guard let object = channelCollection.object(at: index) else { continue }
                    let model = AmitySelectChannelModel(object: AmityChannelModel(object: object))
                    model.isSelected = strongSelf.storeChannels.contains { $0.channelId == object.channelId }
                    if !strongSelf.channels.contains(where: { $0.channelId == object.channelId }) {
                        strongSelf.channels.append(model)
                    }
                }
                
                let predicate: (AmitySelectChannelModel) -> (String) = { channel in
                    let displayName = channel.displayName
                    let c = String(displayName.prefix(1)).uppercased()
                    let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                    
                    if alphabet.contains(c) {
                        return c
                    } else {
                        return "#"
                    }
                }
                
                let groupChannels = Dictionary(grouping: strongSelf.channels, by: predicate).sorted { $0.0 < $1.0 }
                completion(.success(groupChannels))
            }
        }
    }
    
    func searchChannel(_ completion: @escaping (()?, Error?) -> Void) {
        
    }
}

