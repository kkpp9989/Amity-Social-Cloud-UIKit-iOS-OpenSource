//
//  AmityMemberListRepositoryManager.swift
//  AmityUIKit
//
//  Created by Hamlet on 11.05.21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityMemberListRepositoryManagerProtocol {
    func search(withText text: String, sortyBy: AmityUserSortOption, _ completion: (([AmityUserModel]) -> Void)?)
    func loadMore() -> Bool
}

final class AmityMemberListRepositoryManager: AmityMemberListRepositoryManagerProtocol {
    
    private let repository: AmityUserRepository
    private var collection: AmityCollection<AmityUser>?
    private var token: AmityNotificationToken?
    
    init() {
        repository = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
    }
    
    func search(withText text: String, sortyBy: AmityUserSortOption, _ completion: (([AmityUserModel]) -> Void)?) {
        collection = repository.searchUser(text, sortBy: sortyBy)
        token?.invalidate()
        token = collection?.observe { [weak self] (collection, change, error) in
            if collection.dataStatus == .fresh {
                var membersList: [AmityUserModel] = []
                for index in 0..<collection.count() {
                    guard let object = collection.object(at: index) else { continue }
                    let model = AmityUserModel(user: object)
                    if !model.isCurrentUser {
                        membersList.append(model)
                    }
                }
                completion?(membersList)
                /* [Fix-defect] Disable invalidate result search observer for load more ability */
//                self?.token?.invalidate()
            }
        }
    }
    
    func loadMore() -> Bool {
        var isEndPagination: Bool = true
        guard let collection = collection else { return isEndPagination }
        switch collection.loadingStatus {
        case .loaded:
            if collection.hasNext {
                isEndPagination = false
                collection.nextPage()
            }
        default:
            break
        }
        
        return isEndPagination
    }
}
