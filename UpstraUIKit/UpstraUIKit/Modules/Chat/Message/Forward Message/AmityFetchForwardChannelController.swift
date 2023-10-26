//
//  AmityFetchForwardChannelController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 25/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

final class AmityFetchForwardChannelController {
    
    typealias GroupUser = [(key: String, value: [AmitySelectMemberModel])]
    
    private weak var repository: AmityChannelRepository?
    private var collection: AmityCollection<AmityChannel>?
    private var token: AmityNotificationToken?
    
    private var targetType: AmityChannelViewType
    
    private var channel: [AmitySelectMemberModel] = []
    var storeUsers: [AmitySelectMemberModel] = []
    
    init(repository: AmityChannelRepository?, type: AmityChannelViewType) {
        self.repository = repository
        self.targetType = type
    }
    
    func getChannel(_ completion: @escaping (Result<GroupUser, Error>) -> Void) {
        let query = AmityChannelQuery()
        query.filter = .userIsMember
        query.includeDeleted = false
        
        if targetType == .recent {
            collection = repository?.getChannels(with: query)
        } else {
            query.types = [AmityChannelQueryType.broadcast, AmityChannelQueryType.live, AmityChannelQueryType.community]
            collection = repository?.getChannels(with: query)
        }
        
        token = collection?.observe { [weak self] (userCollection, change, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                completion(.failure(error))
            } else {
                let endIndex = strongSelf.targetType == .recent ? min(10, userCollection.count()) : userCollection.count()
                
                for index in 0..<endIndex {
                    guard let object = userCollection.object(at: index) else { continue }
                    let model = AmitySelectMemberModel(object: object)
                    model.isSelected = strongSelf.storeUsers.contains { $0.userId == object.channelId }
                    if !strongSelf.channel.contains(where: { $0.userId == object.channelId }) {
                        if !object.isDeleted {
                            strongSelf.channel.append(model)
                        }
                    }
                }
                
                let predicate: (AmitySelectMemberModel) -> (String) = { user in
                    guard let displayName = user.displayName else { return "#" }
                    let c = String(displayName.prefix(1)).uppercased()
                    let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                    
                    if alphabet.contains(c) {
                        return c
                    } else {
                        return "#"
                    }
                }
                
                let groupUsers = Dictionary(grouping: strongSelf.channel, by: predicate).sorted { $0.0 < $1.0 }
                completion(.success(groupUsers))
            }
        }
    }
    
    func loadmore(isSearch: Bool) -> Bool {
        if !isSearch {
            guard let collection = collection else { return false }
            switch collection.loadingStatus {
            case .loaded:
                if collection.hasNext {
                    collection.nextPage()
                    return true
                } else {
                    return false
                }
            default:
                return false
            }
        } else {
            return false
        }
    }

}
