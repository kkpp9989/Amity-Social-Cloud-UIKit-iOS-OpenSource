//
//  AmityForwardMemberPickerScreenViewModelProtocol.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 24/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityForwardMemberPickerScreenViewModelDelegate: AnyObject {
    func screenViewModelDidFetchUser()
    func screenViewModelDidSearchUser()
    func screenViewModelDidSelectUser(title: String, isEmpty: Bool)
    func screenViewModelDidSetCurrentUsers(title: String, isEmpty: Bool)
    func screenViewModelDidSetNewSelectedUsers(title: String, isEmpty: Bool, isFromAnotherTab: Bool, keyword: String)
    func screenViewModelLoadingState(for state: AmityLoadingState)
    func screenViewModelCanDone(enable: Bool)
    func screenViewModelClearData()
}

protocol AmityForwardMemberPickerScreenViewModelDataSource {
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

protocol AmityForwardMemberPickerScreenViewModelAction {
    func getUsers()
    func searchUser(with text: String)
    func selectUser(at indexPath: IndexPath)
    func deselectUser(at indexPath: IndexPath)
    func loadmore()
    func setCurrentUsers(users: [AmitySelectMemberModel])
    func setNewSelectedUsers(users: [AmitySelectMemberModel], isFromAnotherTab: Bool, keyword: String)
    func updateSelectedUserInfo()
    func clearData()
}

protocol AmityForwardMemberPickerScreenViewModelType: AmityForwardMemberPickerScreenViewModelAction, AmityForwardMemberPickerScreenViewModelDataSource {
    var action: AmityForwardMemberPickerScreenViewModelAction { get }
    var dataSource: AmityForwardMemberPickerScreenViewModelDataSource { get }
    var delegate: AmityForwardMemberPickerScreenViewModelDelegate? { get set }
}

extension AmityForwardMemberPickerScreenViewModelType {
    var action: AmityForwardMemberPickerScreenViewModelAction { return self }
    var dataSource: AmityForwardMemberPickerScreenViewModelDataSource { return self }
}
