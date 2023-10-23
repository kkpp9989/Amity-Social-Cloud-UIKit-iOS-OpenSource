//
//  AmityMemberPickerChatViewModelProtocol.swift
//  AmityUIKit
//
//  Created by Sitthiphong Kanhasura on 22/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityMemberPickerChatScreenViewModelDelegate: AnyObject {
	func screenViewModelDidFetchUser()
	func screenViewModelDidSearchUser()
	func screenViewModelDidSelectUser(title: String, isEmpty: Bool)
	func screenViewModelLoadingState(for state: AmityLoadingState)
	func screenViewModelCanDone(enable: Bool)
	func screenViewModelDidCreateCommunity(_ viewModel: AmityMemberPickerChatScreenViewModelType, channelId: String, subChannelId: String)
}

protocol AmityMemberPickerChatScreenViewModelDataSource {
	func numberOfAlphabet() -> Int
	func numberOfUsers(in section: Int) -> Int
	func numberOfSelectedUsers() -> Int
	func alphabetOfHeader(in section: Int) -> String
	func user(at indexPath: IndexPath) -> AmitySelectMemberModel?
	func selectUser(at indexPath: IndexPath) -> AmitySelectMemberModel
	func isSearching() -> Bool
	func getStoreUsers() -> [AmitySelectMemberModel]
}

protocol AmityMemberPickerChatScreenViewModelAction {
	func getUsers()
	func searchUser(with text: String)
	func selectUser(at indexPath: IndexPath)
	func deselectUser(at indexPath: IndexPath)
	func loadmore()
	func setCurrentUsers(users: [AmitySelectMemberModel])
	func createChannel(users: [AmitySelectMemberModel], displayName: String)
}

protocol AmityMemberPickerChatScreenViewModelType: AmityMemberPickerChatScreenViewModelAction, AmityMemberPickerChatScreenViewModelDataSource {
	var action: AmityMemberPickerChatScreenViewModelAction { get }
	var dataSource: AmityMemberPickerChatScreenViewModelDataSource { get }
	var delegate: AmityMemberPickerChatScreenViewModelDelegate? { get set }
}

extension AmityMemberPickerChatScreenViewModelType {
	var action: AmityMemberPickerChatScreenViewModelAction { return self }
	var dataSource: AmityMemberPickerChatScreenViewModelDataSource { return self }
}

