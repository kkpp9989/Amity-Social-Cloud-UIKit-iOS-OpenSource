//
//  AmityReadingListScreenViewModel.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 8/12/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

class AmityReadingListScreenViewModel: AmityReadingListScreenViewModelType {
    
    weak var delegate: AmityReadingListScreenViewModelDelegate?
    
    // MARK: Repository
    private var userCollection: AmityCollection<AmityUser>?
    private var token: AmityNotificationToken?

    // MARK: - Properties
    private let debouncer = Debouncer(delay: 0.5)
    private var usersList: [AmityUserModel] = []
    private let messageObjc: AmityMessageModel?

    init(message: AmityMessageModel) {
        messageObjc = message
    }
}

// MARK: - DataSource
extension AmityReadingListScreenViewModel {
    
    func numberOfKeyword() -> Int {
        return usersList.count
    }
    
    func item(at indexPath: IndexPath) -> AmityUserModel? {
        guard !usersList.isEmpty else { return nil }
        return usersList[indexPath.row]
    }
    
}

// MARK: - Action
extension AmityReadingListScreenViewModel {

    func fetchData() {
        AmityEventHandler.shared.showKTBLoading()
        delegate?.screenViewModel(self, loadingState: .loading)
        let builderMemberships: Set<MessageReadMembershipFilter> = [.member]
        userCollection = messageObjc?.object.getReadUsers(memberships: builderMemberships)
        token = userCollection?.observe({ [weak self] (collection, _, error) in
            guard let strongSelf = self else { return }
            if let _ = error {
                strongSelf.delegate?.screenViewModelDidFetchSuccess(strongSelf)
                strongSelf.delegate?.screenViewModel(strongSelf, loadingState: .loaded)
                AmityEventHandler.shared.hideKTBLoading()
            } else {
                if collection.dataStatus == .fresh {
                    var users: [AmityUserModel] = []
                    for index in 0..<collection.count() {
                        guard let user = collection.object(at: index) else { continue }
                        users.append(AmityUserModel(user: user))
                    }
                    strongSelf.usersList = users
                    strongSelf.delegate?.screenViewModelDidFetchSuccess(strongSelf)
                    strongSelf.delegate?.screenViewModel(strongSelf, loadingState: .loaded)
                    AmityEventHandler.shared.hideKTBLoading()
                }
            }
        })
    }

    func loadMore() {
        guard let collection = userCollection else { return }
        switch collection.loadingStatus {
        case .loaded:
            if collection.hasNext {
                AmityEventHandler.shared.showKTBLoading()
                collection.nextPage()
            }
        default:
            break
        }
    }

    func clearData() {
        usersList.removeAll()
        delegate?.screenViewModelDidFetchSuccess(self)
    }
}
