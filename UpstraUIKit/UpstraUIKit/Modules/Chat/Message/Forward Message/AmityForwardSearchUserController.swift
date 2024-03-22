//
//  AmityForwardSearchUserController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 25/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//


import UIKit
import AmitySDK

final class AmityForwardSearchUserController {
    
    private weak var repository: AmityUserFollowManager?
    
    private var collection: AmityCollection<AmityFollowRelationship>?
    private var token: AmityNotificationToken?
    private var users: [AmitySelectMemberModel] = []
    private var searchTask: DispatchWorkItem?
    
    private var targetType: AmityFollowerViewType

    init(repository: AmityUserFollowManager?, type: AmityFollowerViewType) {
        self.repository = repository
        self.targetType = type
    }
    
    func search(with text: String, newSelectedUsers: [AmitySelectMemberModel], currentUsers: [AmitySelectMemberModel], _ completion: @escaping (Result<[AmitySelectMemberModel], AmitySearchUserControllerError>) -> Void) {
        users = []
//        searchTask?.cancel()
        if text == "" {
            completion(.failure(.textEmpty))
        } else {
            if targetType == .following {
                collection = repository?.getMyFollowingList(with: .accepted)
            } else {
                collection = repository?.getMyFollowerList(with: .accepted)
            }
            
//            let request =  DispatchWorkItem { [weak self] in
                token = collection?.observe { [weak self] (userCollection, change, error) in
                    guard let strongSelf = self else { return }
                    strongSelf.token?.invalidate()
                    if let error = error {
                        completion(.failure(.unknown))
                    } else {
                        for index in 0..<userCollection.count() {
                            guard let object = userCollection.object(at: index) else { continue }
                            let model = AmitySelectMemberModel(object: object, type: strongSelf.targetType)
                            if !currentUsers.contains(where: {$0.userId == model.userId}) && !model.isCurrnetUser {
                                if strongSelf.targetType == .followers {
                                    model.isSelected = newSelectedUsers.contains { $0.userId == object.sourceUserId }
                                    if !(object.sourceUser?.isDeleted ?? false) {
                                        if !(object.sourceUser?.isGlobalBanned ?? false) {
                                            let specialCharacterSet = CharacterSet(charactersIn: "!@#$%&*()_+=|<>?{}[]~-")
                                            if object.sourceUserId.rangeOfCharacter(from: specialCharacterSet) == nil {
                                                strongSelf.users.append(model)
                                            }
                                        }
                                    }
                                } else {
                                    model.isSelected = newSelectedUsers.contains { $0.userId == object.targetUserId }
                                    if !(object.sourceUser?.isDeleted ?? false) {
                                        if !(object.sourceUser?.isGlobalBanned ?? false) {
                                            let specialCharacterSet = CharacterSet(charactersIn: "!@#$%&*()_+=|<>?{}[]~-")
                                            if object.targetUserId.rangeOfCharacter(from: specialCharacterSet) == nil {
                                                strongSelf.users.append(model)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        if let collection = strongSelf.collection {
                            switch collection.loadingStatus {
                            case .loaded:
                                if collection.hasNext {
                                    collection.nextPage()
                                } else {
                                    let filteredUsers = strongSelf.users.filter { user in
                                        if let displayName = user.displayName {
                                            return displayName.lowercased().contains(text.lowercased())
                                        }
                                        return false // Handle the case where displayName is nil
                                    }
                                    completion(.success(filteredUsers))
                                }
                            default:
                                let filteredUsers = strongSelf.users.filter { user in
                                    if let displayName = user.displayName {
                                        return displayName.lowercased().contains(text.lowercased())
                                    }
                                    return false // Handle the case where displayName is nil
                                }
                                completion(.success(filteredUsers))
                            }
                        }
                    }
                }
//            }
            
//            searchTask = request
//            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3, execute: request)
        }
    }
    
    func loadmore(isSearch: Bool) -> Bool {
        if isSearch {
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
