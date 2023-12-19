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
    
    func update(avatar: UIImage) async -> Bool {
        do {
            // Upload avatar image
            let imageData = try await fileRepository.uploadImage(avatar) { progress in
//                print("[Avatar][Chat] Upload progressing result: \(progress)")
                DispatchQueue.main.async {
                    self.delegate?.screenViewModelDidUpdateAvatarUploadingProgress(self, progressing: progress)
                }
            }
            // Set avatar to update builder
            amityUserUpdateBuilder.setAvatar(imageData)
            return true
        } catch {
//            print("[Avatar][Chat] Can't update avatar group chat with error: \(error.localizedDescription)")
            return false
        }
    }
    
	// MARK: - For Create New Group
    func createChannel(displayName: String) {
		if !displayName.isEmpty {
			amityUserUpdateBuilder.setDisplayName(displayName)
		}
		delegate?.screenViewModelDidCreateCommunity(self, builder: amityUserUpdateBuilder)
	}
	
	// MARK: - For Invite people from 1:1 chat
	func createChannel(users: [AmitySelectMemberModel], displayName: String) {
		AmityEventHandler.shared.showKTBLoading()
		createCommunityChannel(users: users, displayName: displayName)
	}
}

// MARK: - Private
extension GroupChatCreatorScreenViewModel {
	private func createNewCommiunityChannel(builder: AmityCommunityChannelBuilder, userIds: [String]) {
		AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: channelRepository.createChannel, parameters: builder) { [weak self] channelObject, error in
			guard let weakSelf = self else { return }
			if let error = error {
				print(error.localizedDescription)
			}
			AmityEventHandler.shared.hideKTBLoading()
			if let channelId = channelObject?.channelId, let subChannelId = channelObject?.defaultSubChannelId {
//				weakSelf.assignRoleAfterCreateChannel(channelId, subChannelId: subChannelId, userIds: userIds)
                weakSelf.delegate?.screenViewModelDidCreateCommunity(weakSelf, channelId: channelId, subChannelId: subChannelId)
			}
		}
	}
	
	private func assignRoleAfterCreateChannel(_ channelId: String, subChannelId: String, userIds: [String]) {
		let channelModeration = AmityChannelModeration(client: AmityUIKitManagerInternal.shared.client, andChannel: channelId)

		AmityAsyncAwaitTransformer.toCompletionHandler(asyncOperation: { return try await channelModeration.addRole(AmityChannelRole.channelModerator.rawValue, userIds: userIds) }) { (isSuccess, _) in
			self.delegate?.screenViewModelDidCreateCommunity(self, channelId: channelId, subChannelId: subChannelId)
		}
	}
	
	private func createCommunityChannel(users: [AmitySelectMemberModel], displayName: String) {
		var allUsers = users
		var currentUser: AmitySelectMemberModel?
		if let user = AmityUIKitManagerInternal.shared.client.user?.snapshot {
			let userModel = AmitySelectMemberModel(object: user)
			currentUser = userModel
			allUsers.append(userModel)
		}
		let userIds = allUsers.map{ $0.userId }
		let channelId = userIds.sorted().joined(separator: "-")
		amityUserUpdateBuilder.setUserIds(userIds)
		let metaData: [String:Any] = [
			"isDirectChat": allUsers.count == 2,
			"creatorId": currentUser?.userId ?? "",
			"sdk_type":"ios",
			"userIds": userIds
		]
		let combinedDisplayName = users.map { $0.displayName ?? "" }.joined(separator: ", ")
		let channelDisplayName = !displayName.isEmpty ? displayName : combinedDisplayName + ", " + AmityUIKitManagerInternal.shared.displayName
		amityUserUpdateBuilder.setMetadata(metaData)
		amityUserUpdateBuilder.setDisplayName(channelDisplayName)
		amityUserUpdateBuilder.setTags(["ch-comm","ios-sdk"])
        amityUserUpdateBuilder.setIsChannelPublic(false)
		existingChannelToken?.invalidate()
		existingChannelToken = channelRepository.getChannel(channelId).observe({ [weak self] (channel, error) in
			guard let weakSelf = self else { return }
			if error != nil {
				/// Might be two reason
				/// 1. Network error
				/// 2. Channel haven't created yet
				weakSelf.createNewCommiunityChannel(builder: weakSelf.amityUserUpdateBuilder, userIds: userIds)
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
