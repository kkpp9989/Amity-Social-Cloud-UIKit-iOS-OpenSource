//
//  AmityChatFriendScreenViewModel.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 2/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

class AmityChatFriendScreenViewModel: AmityChatFriendScreenViewModelType {
    
    weak var delegate: AmityChatFriendScreenViewModelDelegate?

    // MARK: - Properties
    let userId: String
    let type: AmityFollowerViewType
    let isCurrentUser: Bool
    private let userRepository: AmityUserRepository
    private let followManager: AmityUserFollowManager
    private var followToken: AmityNotificationToken?
    private var followersList: [AmityFollowRelationship] = []
    private var followersCollection: AmityCollection<AmityFollowRelationship>?
    private var flagger: AmityUserFlagger?
    private let channelRepository: AmityChannelRepository
    
    // MARK: - Initializer
    init(userId: String, type: AmityFollowerViewType) {
        userRepository = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
        channelRepository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
        followManager = userRepository.followManager
        self.userId = userId
        self.isCurrentUser = userId == AmityUIKitManagerInternal.shared.client.currentUserId
        self.type = type
    }
}

// MARK: - DataSource
extension AmityChatFriendScreenViewModel {
    func numberOfItems() -> Int {
        return followersList.count
    }
    
    func item(at indexPath: IndexPath) -> AmityUserModel? {
        guard let model = getUser(at: indexPath) else { return nil }
        return AmityUserModel(user: model)
    }
}

// MARK: - Action
extension AmityChatFriendScreenViewModel {
    func getFollowsList() {
        AmityEventHandler.shared.showKTBLoading()
        if userId == AmityUIKitManagerInternal.shared.client.currentUserId {
            followersCollection = type == .followers ? followManager.getMyFollowerList(with: .accepted) : followManager.getMyFollowingList(with: .accepted)
        } else {
            followersCollection = type == .followers ? followManager.getUserFollowerList(withUserId: userId) : followManager.getUserFollowingList(withUserId: userId)
        }
        
        followToken = followersCollection?.observe { [weak self] collection, _, error in
            self?.prepareDataSource(collection: collection, error: error)
        }
    }
    
    func loadMoreFollowingList() {
        guard let collection = followersCollection else { return }
        
        switch collection.loadingStatus {
        case .loaded:
            if collection.hasNext {
                collection.nextPage()
            }
        default: break
        }
    }
    
    func reportUser(at indexPath: IndexPath) {
    }
    
    func unreportUser(at indexPath: IndexPath) {
    }
    
    func getReportUserStatus(at indexPath: IndexPath) {
    }
    
    func removeUser(at indexPath: IndexPath) {
    }
    
    func createChannel(user: AmityUserModel) {
        let userIds: [String] = [user.userId, AmityUIKitManagerInternal.shared.currentUserId]

        let builder = AmityConversationChannelBuilder()
        builder.setUserId(user.userId)
        builder.setDisplayName(user.displayName)
        builder.setMetadata(["user_id_member": userIds])
        
        AmityEventHandler.shared.showKTBLoading()
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: channelRepository.createChannel, parameters: builder) { [weak self] channelObject, _ in
            guard let strongSelf = self else { return }
            if let channel = channelObject {
                strongSelf.delegate?.screenViewModel(strongSelf, didCreateChannel: channel)
            }
        }
    }
}

private extension AmityChatFriendScreenViewModel {
    func getUser(at indexPath: IndexPath) -> AmityUser? {
        let recordAtRow = followersList[indexPath.row]
        return type == .followers ? recordAtRow.sourceUser : recordAtRow.targetUser
    }
    
    private func prepareDataSource(collection: AmityCollection<AmityFollowRelationship>, error: Error?) {
        if let _ = error {
            followToken?.invalidate()
            delegate?.screenViewModelDidGetListFail()
            return
        }
        
        switch collection.dataStatus {
        case .fresh:
            var followers: [AmityFollowRelationship] = []
            for i in 0..<collection.count() {
                guard let follow = collection.object(at: i) else { continue }
                followers.append(follow)
            }
            
            followersList = followers
            delegate?.screenViewModelDidGetListSuccess()
        default:
            delegate?.screenViewModelDidGetListSuccess()
        }
    }
}
