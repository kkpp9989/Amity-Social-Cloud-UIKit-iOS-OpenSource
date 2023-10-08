//
//  GroupChatCreatorScreenViewModel.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 8/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

class GroupChatCreatorScreenViewModel: GroupChatCreatorScreenViewModelType {
    
    private let dispatchGroup = DispatchGroupWraper()
    private let amityUserUpdateBuilder = AmityCommunityChannelBuilder()
    private let fileRepository = AmityFileRepository(client: AmityUIKitManagerInternal.shared.client)
    private var existingChannelToken: AmityNotificationToken?
    private let channelRepository: AmityChannelRepository

    weak var delegate: GroupChatCreatorScreenViewModelDelegate?
    var user: AmityUserModel?
    
    private var selectUsersData: [AmitySelectMemberModel]

    init(_ selectUsersData: [AmitySelectMemberModel]) {
        self.channelRepository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
        self.selectUsersData = selectUsersData
    }
    
    func update(avatar: UIImage, completion: ((Bool) -> Void)?) {
        // Update user avatar
        dispatchGroup.enter()
        fileRepository.uploadImage(avatar, progress: nil) { [weak self] (imageData, error) in
            guard let self = self else { return }
            if let error = error {
                self.dispatchGroup.leaveWithError(error)
                completion?(false)
            }
            if let imageData = imageData {
                self.amityUserUpdateBuilder.setAvatar(imageData)
                self.dispatchGroup.leave()
                completion?(true)
            }
        }
    }
    
    func createChannel(users: [AmitySelectMemberModel], displayName: String) {
        AmityEventHandler.shared.showKTBLoading()
        createCommunityChannel(users: users, displayName: displayName)
    }
    
    private func createNewCommiunityChannel(builder: AmityCommunityChannelBuilder) {
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: channelRepository.createChannel, parameters: builder) { [weak self] channelObject, error in
            guard let weakSelf = self else { return }
            if let error = error {
                print(error.localizedDescription)
            }
            AmityEventHandler.shared.hideKTBLoading()
            if let channelId = channelObject?.channelId, let subChannelId = channelObject?.defaultSubChannelId {
                weakSelf.delegate?.screenViewModelDidCreateCommunity(weakSelf, channelId: channelId, subChannelId: subChannelId)
            }
        }
    }
    
    func createCommunityChannel(users: [AmitySelectMemberModel], displayName: String) {
        var allUsers = users
        var currentUser: AmitySelectMemberModel?
        if let user = AmityUIKitManagerInternal.shared.client.user?.snapshot {
            let userModel = AmitySelectMemberModel(object: user)
            currentUser = userModel
            allUsers.append(userModel)
        }
        let userIds = allUsers.map{ $0.userId }
        let channelId = userIds.sorted().joined(separator: "-")
        let combinedDisplayName = users.map { $0.displayName ?? "" }.joined(separator: ", ")
        let channelDisplayName = !displayName.isEmpty ? displayName : combinedDisplayName + ", " + AmityUIKitManagerInternal.shared.displayName
        amityUserUpdateBuilder.setUserIds(userIds)
        let metaData: [String:Any] = [
            "isDirectChat": allUsers.count == 2,
            "creatorId": currentUser?.userId ?? "",
            "sdk_type":"ios",
            "userIds": userIds
        ]
        amityUserUpdateBuilder.setMetadata(metaData)
        amityUserUpdateBuilder.setDisplayName(channelDisplayName)
        amityUserUpdateBuilder.setTags(["ch-comm","ios-sdk"])
        existingChannelToken?.invalidate()
        existingChannelToken = channelRepository.getChannel(channelId).observe({ [weak self] (channel, error) in
            guard let weakSelf = self else { return }
            if error != nil {
                /// Might be two reason
                /// 1. Network error
                /// 2. Channel haven't created yet
                weakSelf.createNewCommiunityChannel(builder: weakSelf.amityUserUpdateBuilder)
            }
            /// which mean we already have that channel and don't need to creaet new channel
            guard let channel = channel.snapshot else { return }
            AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: weakSelf.channelRepository.joinChannel, parameters: channelId)
            weakSelf.existingChannelToken?.invalidate()
            AmityEventHandler.shared.hideKTBLoading()
            weakSelf.delegate?.screenViewModelDidCreateCommunity(weakSelf, channelId: channelId, subChannelId: channel.defaultSubChannelId)
        })
    }
}
