//
//  AmityForwardMemberPickerScreenViewModel.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 24/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

class AmityForwardMemberPickerScreenViewModel: AmityForwardMemberPickerScreenViewModelType {
    weak var delegate: AmityForwardMemberPickerScreenViewModelDelegate?
    
    // MARK: - Repository
    private var userRepository: AmityUserRepository?
    private var userRelationship: AmityUserFollowManager?

    // MARK: - Controller
    private var fetchUserController: AmityFetchForwardUserController?
    private var searchUserController: AmityForwardSearchUserController?
    private var selectUserContrller: AmityForwardSelectUserController?
    
    // MARK: - Properties
    private var users: AmityFetchUserController.GroupUser = []
    private var searchUsers: [AmitySelectMemberModel] = []
    private var newSelectedUsers: [AmitySelectMemberModel] = [] {
        didSet {
            delegate?.screenViewModelCanDone(enable: !newSelectedUsers.isEmpty)
        }
    }
    private var currentUsers: [AmitySelectMemberModel] = []
    private var isSearch: Bool = false
    
    init(type: AmityFollowerViewType) {
        userRepository = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
        userRelationship = AmityUserFollowManager(client: AmityUIKitManagerInternal.shared.client)
        fetchUserController = AmityFetchForwardUserController(repository: userRelationship, type: type)
        searchUserController = AmityForwardSearchUserController(repository: userRelationship, type: type)
        selectUserContrller = AmityForwardSelectUserController()
    }
}

// MARK: - DataSource
extension AmityForwardMemberPickerScreenViewModel {
    func numberOfAlphabet() -> Int {
        return isSearch ? 1 : users.count
    }
    
    func numberOfUsers(in section: Int) -> Int {
        return isSearch ? searchUsers.count : users[section].value.count
    }
    
    func numberOfSelectedUsers() -> Int {
        return newSelectedUsers.count
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
        return newSelectedUsers[indexPath.item]
    }
    
    func isSearching() -> Bool {
        return isSearch
    }
    
    func isCurrentUserInGroup(id: String) -> Bool {
        return currentUsers.contains(where: { $0.userId == id })
    }
    
    func getStoreUsers() -> [AmitySelectMemberModel] {
        return newSelectedUsers + currentUsers
    }
    
    func getNewSelectedUsers() -> [AmitySelectMemberModel] {
        return newSelectedUsers
    }
}

// MARK: - Action
extension AmityForwardMemberPickerScreenViewModel {
    
    func setCurrentUsers(users: [AmitySelectMemberModel]) {
        currentUsers = users
        
        if currentUsers.count == 0 {
            delegate?.screenViewModelDidSetCurrentUsers(title: AmityLocalizedStringSet.selectMemberListTitle.localizedString, isEmpty: true)
        } else {
            delegate?.screenViewModelDidSetCurrentUsers(title: String.localizedStringWithFormat(AmityLocalizedStringSet.selectMemberListSelectedTitle.localizedString, "\(newSelectedUsers.count)"), isEmpty: false)
        }
    }
    
    func setNewSelectedUsers(users: [AmitySelectMemberModel], isFromAnotherTab: Bool) {
        newSelectedUsers = users
        
        if newSelectedUsers.count == 0 {
            delegate?.screenViewModelDidSetNewSelectedUsers(title: AmityLocalizedStringSet.selectMemberListTitle.localizedString, isEmpty: true, isFromAnotherTab: isFromAnotherTab)
        } else {
            delegate?.screenViewModelDidSetNewSelectedUsers(title: String.localizedStringWithFormat(AmityLocalizedStringSet.selectMemberListSelectedTitle.localizedString, "\(newSelectedUsers.count)"), isEmpty: false, isFromAnotherTab: isFromAnotherTab)
        }
    }
    
    func getUsers() {
        fetchUserController?.newSelectedUsers = newSelectedUsers
        fetchUserController?.currentUsers = currentUsers
        fetchUserController?.getUser { (result) in
            switch result {
            case .success(let users):
                self.users = users
                self.delegate?.screenViewModelDidFetchUser()
            case .failure(let error):
                break
            }
        }
    }
    
    func searchUser(with text: String) {
        isSearch = true
        searchUserController?.search(with: text, newSelectedUsers: newSelectedUsers, currentUsers: currentUsers, { [weak self] (result) in
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
    
    func updateSelectedUserInfo() {
        if isSearch {
            // Edit selected of search user
            for (index, data) in searchUsers.enumerated() {
                if newSelectedUsers.contains(where: { $0.userId == data.userId } ) || currentUsers.contains(where: { $0.userId == data.userId } ) {
                    searchUsers[index].isSelected = true
                } else {
                    searchUsers[index].isSelected = false
                }
            }
        } else {
            // Edit selected of user
            for (indexGroup, (key, group)) in users.enumerated() {
                for (indexUser, user) in group.enumerated() {
                    if newSelectedUsers.contains(where: { $0.userId == user.userId } ) || currentUsers.contains(where: { $0.userId == user.userId } ) {
                        users[indexGroup].value[indexUser].isSelected = true
                    } else {
                        users[indexGroup].value[indexUser].isSelected = false
                    }
                }
            }
        }
    }
    
    func selectUser(at indexPath: IndexPath) {
        selectUserContrller?.selectUser(searchUsers: searchUsers, users: &users, newSelectedUsers: &newSelectedUsers, at: indexPath, isSearch: isSearch)
        if newSelectedUsers.count == 0 {
            delegate?.screenViewModelDidSelectUser(title: AmityLocalizedStringSet.selectMemberListTitle.localizedString, isEmpty: true)
        } else {
            delegate?.screenViewModelDidSelectUser(title: String.localizedStringWithFormat(AmityLocalizedStringSet.selectMemberListSelectedTitle.localizedString, "\(newSelectedUsers.count)"), isEmpty: false)
        }
    }
    
    func deselectUser(at indexPath: IndexPath) {
        selectUserContrller?.deselect(searchUsers: &searchUsers, users: &users, newSelectedUsers: &newSelectedUsers, at: indexPath)
        if newSelectedUsers.count == 0 {
            delegate?.screenViewModelDidSelectUser(title: AmityLocalizedStringSet.selectMemberListTitle.localizedString, isEmpty: true)
        } else {
            delegate?.screenViewModelDidSelectUser(title: String.localizedStringWithFormat(AmityLocalizedStringSet.selectMemberListSelectedTitle.localizedString, "\(newSelectedUsers.count)"), isEmpty: false)
        }
    }
    
    func loadmore() {
        var success: Bool = false
        if isSearch {
            guard let controller = searchUserController else { return }
            success = controller.loadmore(isSearch: isSearch)
        } else {
            guard let controller = fetchUserController else { return }
            fetchUserController?.newSelectedUsers = newSelectedUsers
            fetchUserController?.currentUsers = currentUsers
            success = controller.loadmore(isSearch: isSearch)
        }
        
        if success {
            delegate?.screenViewModelLoadingState(for: .loading)
        } else {
            delegate?.screenViewModelLoadingState(for: .loaded)
        }
    }
}
