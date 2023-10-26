//
//  AmityFetchForwardUserController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 24/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

final class AmityFetchForwardUserController {
    
    typealias GroupUser = [(key: String, value: [AmitySelectMemberModel])]
    
    private weak var repository: AmityUserRelationship?
    private var collection: AmityCollection<AmityFollowRelationship>?
    private var token: AmityNotificationToken?
    
    private var targetType: AmityFollowerViewType
    
    private var users: [AmitySelectMemberModel] = []
    var storeUsers: [AmitySelectMemberModel] = []
    
    init(repository: AmityUserRelationship?, type: AmityFollowerViewType) {
        self.repository = repository
        self.targetType = type
    }
    
    func getUser(_ completion: @escaping (Result<GroupUser, Error>) -> Void) {
        if targetType == .following {
            collection = repository?.getMyFollowings(with: .accepted)
        } else {
            collection = repository?.getMyFollowers(with: .accepted)
        }
        
        token = collection?.observe { [weak self] (userCollection, change, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                completion(.failure(error))
            } else {
                for index in 0..<userCollection.count() {
                    guard let object = userCollection.object(at: index) else { continue }
                    let model = AmitySelectMemberModel(object: object)
                    model.isSelected = strongSelf.storeUsers.contains { $0.userId == object.sourceUserId }
                    if !strongSelf.users.contains(where: { $0.userId == object.sourceUserId }) {
                        if !(object.sourceUser?.isDeleted ?? false) {
                            strongSelf.users.append(model)
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
                
                let groupUsers = Dictionary(grouping: strongSelf.users, by: predicate).sorted { $0.0 < $1.0 }
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
