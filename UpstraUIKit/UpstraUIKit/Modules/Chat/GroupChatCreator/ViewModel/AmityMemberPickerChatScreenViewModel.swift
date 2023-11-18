//
//  AmityMemberPickerChatScreenViewModel.swift
//  AmityUIKit
//
//  Created by Sitthiphong Kanhasura on 22/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

final class AmityMemberPickerChatScreenViewModel: AmityMemberPickerChatScreenViewModelType {
	weak var delegate: AmityMemberPickerChatScreenViewModelDelegate?
	
	// MARK: - Repository
	private var userRepository: AmityUserRepository?
	private let channelRepository: AmityChannelRepository
	private var existingChannelToken: AmityNotificationToken?
	
	// MARK: - Controller
	private var fetchUserController: AmityFetchUserController?
	private var searchUserController: AmitySearchUserController?
	private var selectUserContrller: AmitySelectUserController?
	
	private var users: AmityFetchUserController.GroupUser = []
	private var searchUsers: [AmitySelectMemberModel] = []
	private var storeUsers: [AmitySelectMemberModel] = [] {
		didSet {
			delegate?.screenViewModelCanDone(enable: !storeUsers.isEmpty)
		}
	}
	private var amityUserUpdateBuilder: AmityCommunityChannelBuilder
	
	private var isSearch: Bool = false
	
	init(amityUserUpdateBuilder: AmityCommunityChannelBuilder) {
		userRepository = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
		fetchUserController = AmityFetchUserController(repository: userRepository)
		searchUserController = AmitySearchUserController(repository: userRepository)
		selectUserContrller = AmitySelectUserController()
		self.amityUserUpdateBuilder = amityUserUpdateBuilder
		channelRepository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
	}
}

// MARK: - DataSource
extension AmityMemberPickerChatScreenViewModel {
	func numberOfAlphabet() -> Int {
		return isSearch ? 1 : users.count
	}
	
	func numberOfUsers(in section: Int) -> Int {
		return isSearch ? searchUsers.count : users[section].value.count
	}
	
	func numberOfSelectedUsers() -> Int {
		return storeUsers.count
	}
	
	func alphabetOfHeader(in section: Int) -> String {
		return users[section].key
	}
	
	func user(at indexPath: IndexPath) -> AmitySelectMemberModel? {
		if isSearch {
			guard !searchUsers.isEmpty else { return nil }
			return searchUsers[indexPath.row]
		} else {
			guard !users.isEmpty else { return nil }
			return users[indexPath.section].value[indexPath.row]
		}
	}
	
	func selectUser(at indexPath: IndexPath) -> AmitySelectMemberModel {
		return storeUsers[indexPath.item]
	}
	
	func isSearching() -> Bool {
		return isSearch
	}
	
	func getStoreUsers() -> [AmitySelectMemberModel] {
		return storeUsers
	}
}

// MARK: - Action
extension AmityMemberPickerChatScreenViewModel {
	
	func setCurrentUsers(users: [AmitySelectMemberModel]) {
		storeUsers = users
	}
	
	func getUsers() {
		fetchUserController?.storeUsers = storeUsers
		fetchUserController?.getUser { (result) in
			switch result {
			case .success(let users):
				self.users = users
				self.delegate?.screenViewModelDidFetchUser()
			case .failure:
				break
			}
		}
	}
	
	func searchUser(with text: String) {
		isSearch = true
		searchUserController?.search(with: text, storeUsers: storeUsers, { [weak self] (result) in
			switch result {
			case .success(let users):
				self?.searchUsers = users
				self?.delegate?.screenViewModelDidSearchUser()
			case .failure(let error):
				switch error {
				case .textEmpty:
					self?.isSearch = false
					self?.delegate?.screenViewModelDidSearchUser()
				case .unknown:
					break
				}
			}
		})
	}
	
	func selectUser(at indexPath: IndexPath) {
		selectUserContrller?.selectUser(searchUsers: searchUsers, users: &users, storeUsers: &storeUsers, at: indexPath, isSearch: isSearch)
		if storeUsers.count == 0 {
			delegate?.screenViewModelDidSelectUser(title: AmityLocalizedStringSet.selectMemberListTitle.localizedString, isEmpty: true)
		} else {
			delegate?.screenViewModelDidSelectUser(title: String.localizedStringWithFormat(AmityLocalizedStringSet.selectMemberListSelectedTitle.localizedString, "\(storeUsers.count)"), isEmpty: false)
		}
	}
	
	func deselectUser(at indexPath: IndexPath) {
		selectUserContrller?.deselect(users: &users, storeUsers: &storeUsers, at: indexPath)
		if storeUsers.count == 0 {
			delegate?.screenViewModelDidSelectUser(title: AmityLocalizedStringSet.selectMemberListTitle.localizedString, isEmpty: true)
		} else {
			delegate?.screenViewModelDidSelectUser(title: String.localizedStringWithFormat(AmityLocalizedStringSet.selectMemberListSelectedTitle.localizedString, "\(storeUsers.count)"), isEmpty: false)
		}
	}
	
	func loadmore() {
		var success: Bool = false
		if isSearch {
			guard let controller = searchUserController else { return }
			success = controller.loadmore(isSearch: isSearch)
		} else {
			guard let controller = fetchUserController else { return }
			fetchUserController?.storeUsers = storeUsers
			success = controller.loadmore(isSearch: isSearch)
		}
		
		if success {
			delegate?.screenViewModelLoadingState(for: .loading)
		} else {
			delegate?.screenViewModelLoadingState(for: .loaded)
		}
	}
	
	func createChannel(users: [AmitySelectMemberModel], displayName: String) {
		AmityEventHandler.shared.showKTBLoading()
		createCommunityChannel(users: users, displayName: displayName)
	}
	
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
