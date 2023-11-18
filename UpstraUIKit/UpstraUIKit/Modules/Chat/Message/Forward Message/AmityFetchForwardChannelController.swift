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
    
    private let dispatchGroup = DispatchGroup()
    private var tokenArray: [AmityNotificationToken] = []
    private let debouncer = Debouncer(delay: 0.3)
    
    init(repository: AmityChannelRepository?, type: AmityChannelViewType) {
        self.repository = repository
        self.targetType = type
    }
    
    func getChannel(isMustToChangeSomeChannelToUser: Bool, _ completion: @escaping (Result<GroupUser, Error>) -> Void) {
        let query = AmityChannelQuery()
        query.filter = .userIsMember
        query.includeDeleted = false
        
        if targetType == .recent {
            collection = repository?.getChannels(with: query)
        } else {
            query.types = [AmityChannelQueryType.community]
            collection = repository?.getChannels(with: query)
        }
        
        token = collection?.observeOnce { [weak self] (userCollection, change, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                completion(.failure(error))
            } else {
                let endIndex = strongSelf.targetType == .recent ? min(10, userCollection.count()) : userCollection.count()
                // Dictionary to keep track of whether leave has been called for a specific channelId
                var channelIdLeaveMap: [String: Bool] = [:]
                for index in 0..<endIndex {
                    strongSelf.dispatchGroup.enter()
                    channelIdLeaveMap[String(index)] = false
                    guard let object = userCollection.object(at: index) else { continue }
                    let model = AmitySelectMemberModel(object: object)
                    model.isSelected = strongSelf.storeUsers.contains { $0.userId == object.channelId }
                    if !strongSelf.channel.contains(where: { $0.userId == object.channelId }) {
                        if !object.isDeleted {
                            if object.channelType == .conversation && isMustToChangeSomeChannelToUser {
                                let otherUserId = AmityChannelModel(object: object).getOtherUserId()
                                let userRepository = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
                                let tempToken = userRepository.getUser(otherUserId).observeOnce({ liveObject, error in
                                    if let userObject = liveObject.snapshot {
                                        let userModel = AmitySelectMemberModel(object: userObject)
                                        strongSelf.channel.append(userModel)
                                    } else {
                                        strongSelf.channel.append(model)
                                    }
                                    if let leaveCalled = channelIdLeaveMap[String(index)], !leaveCalled {
                                        channelIdLeaveMap[String(index)] = true
                                        strongSelf.dispatchGroup.leave()
                                    }
                                })
                                strongSelf.tokenArray.append(tempToken)
                            } else {
                                strongSelf.channel.append(model)
                                if let leaveCalled = channelIdLeaveMap[String(index)], !leaveCalled {
                                    channelIdLeaveMap[String(index)] = true
                                    strongSelf.dispatchGroup.leave()
                                }
                            }
                        } else {
                            if let leaveCalled = channelIdLeaveMap[String(index)], !leaveCalled {
                                channelIdLeaveMap[String(index)] = true
                                strongSelf.dispatchGroup.leave()
                            }
                        }
                    } else {
                        if let leaveCalled = channelIdLeaveMap[String(index)], !leaveCalled {
                            channelIdLeaveMap[String(index)] = true
                            strongSelf.dispatchGroup.leave()
                        }
                    }
                }
                
                strongSelf.dispatchGroup.notify(queue: .main) {
                    strongSelf.tokenArray.removeAll()
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
