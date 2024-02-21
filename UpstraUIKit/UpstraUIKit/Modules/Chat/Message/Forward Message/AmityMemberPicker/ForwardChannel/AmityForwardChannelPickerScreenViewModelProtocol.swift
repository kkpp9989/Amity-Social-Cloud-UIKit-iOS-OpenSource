//
//  AmityForwardChannelPickerScreenViewModelProtocol.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 25/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityForwardChannelPickerScreenViewModelDelegate: AnyObject {
    func screenViewModelDidFetchUser()
    func screenViewModelDidSearchUser()
    func screenViewModelDidSelectUser(title: String, isEmpty: Bool)
    func screenViewModelDidSetCurrentUsers(title: String, isEmpty: Bool)
    func screenViewModelDidSetNewSelectedUsers(title: String, isEmpty: Bool, isFromAnotherTab: Bool, keyword: String)
    func screenViewModelLoadingState(for state: AmityLoadingState)
    func screenViewModelCanDone(enable: Bool)
    func screenViewModelClearData()
}

protocol AmityForwardChannelPickerScreenViewModelDataSource {
    var targetType: AmityChannelViewType { get }
    func numberOfAlphabet() -> Int
    func numberOfUsers(in section: Int) -> Int
    func numberOfSelectedUsers() -> Int
    func alphabetOfHeader(in section: Int) -> String
    func user(at indexPath: IndexPath) -> AmitySelectMemberModel?
    func selectUser(at indexPath: IndexPath) -> AmitySelectMemberModel
    func isSearching() -> Bool
    func getStoreUsers() -> [AmitySelectMemberModel]
    func getNewSelectedUsers() -> [AmitySelectMemberModel]
    func isCurrentUserInGroup(id: String) -> Bool
}

protocol AmityForwardChannelPickerScreenViewModelAction {
    func getChannels()
    func searchUser(with text: String)
    func selectUser(at indexPath: IndexPath)
    func deselectUser(at indexPath: IndexPath)
    func loadmore()
    func setCurrentUsers(users: [AmitySelectMemberModel])
    func setNewSelectedUsers(users: [AmitySelectMemberModel], isFromAnotherTab: Bool, keyword: String)
    func updateSelectedUserInfo()
    func clearData()
}

protocol AmityForwardChannelPickerScreenViewModelType: AmityForwardChannelPickerScreenViewModelAction, AmityForwardChannelPickerScreenViewModelDataSource {
    var action: AmityForwardChannelPickerScreenViewModelAction { get }
    var dataSource: AmityForwardChannelPickerScreenViewModelDataSource { get }
    var delegate: AmityForwardChannelPickerScreenViewModelDelegate? { get set }
}

extension AmityForwardChannelPickerScreenViewModelType {
    var action: AmityForwardChannelPickerScreenViewModelAction { return self }
    var dataSource: AmityForwardChannelPickerScreenViewModelDataSource { return self }
}
