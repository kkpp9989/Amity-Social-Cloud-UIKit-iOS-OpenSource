//
//  AmityForwardChannelPickerScreenViewModel.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 25/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

class AmityForwardChannelPickerScreenViewModel: AmityForwardChannelPickerScreenViewModelType {
    weak var delegate: AmityForwardChannelPickerScreenViewModelDelegate?
    
    // MARK: - Repository
    private var channelRepository: AmityChannelRepository?

    // MARK: - Controller
    private var fetchChannelController: AmityFetchForwardChannelController?
    private var searchUserController: AmityForwardSearchChannelController?
    private var selectUserContrller: AmityForwardSelectUserController?
    
    private var users: AmityFetchForwardChannelController.GroupUser = []
    private var searchUsers: [AmitySelectMemberModel] = []
    private var newSelectedUsers: [AmitySelectMemberModel] = [] {
        didSet {
            delegate?.screenViewModelCanDone(enable: !newSelectedUsers.isEmpty)
        }
    }
    private var currentUsers: [AmitySelectMemberModel] = []
    private var currentKeyword: String = ""
    private var isSearch: Bool = false
    private var targetType: AmityChannelViewType
    
    init(type: AmityChannelViewType) {
        channelRepository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
        fetchChannelController = AmityFetchForwardChannelController(repository: channelRepository, type: type)
        searchUserController = AmityForwardSearchChannelController(repository: channelRepository, type: type)
        selectUserContrller = AmityForwardSelectUserController()
        targetType = type
    }
}

// MARK: - DataSource
extension AmityForwardChannelPickerScreenViewModel {
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
        return currentUsers + newSelectedUsers
    }
    
    func getNewSelectedUsers() -> [AmitySelectMemberModel] {
        return newSelectedUsers
    }
}

// MARK: - Action
extension AmityForwardChannelPickerScreenViewModel {
    
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
    
    func getChannels() {
        fetchChannelController?.newSelectedUsers = newSelectedUsers
        fetchChannelController?.currentUsers = currentUsers
        fetchChannelController?.getChannel(isMustToChangeSomeChannelToUser: true) { (result) in
            switch result {
            case .success(let users):
                self.users = users
                self.delegate?.screenViewModelDidFetchUser()
            case .failure(let error):
                break
            }
        }
    }
    
//    func searchUser(with text: String) {
//        isSearch = true
//        searchUserController?.search(with: text, newSelectedUsers: newSelectedUsers, currentUsers: currentUsers, { [weak self] (result) in
//            switch result {
//            case .success(let users):
//                self?.searchUsers = users
//                self?.delegate?.screenViewModelDidSearchUser()
//            case .failure(let error):
//                switch error {
//                case .textEmpty:
//                    self?.isSearch = false
//                    self?.delegate?.screenViewModelDidSearchUser()
//                case .unknown:
//                    break
//                }
//            }
//        })
//    }
    
    func searchUser(with text: String) {
        searchUserController?.delegate = self
        isSearch = true
        currentKeyword = text
        if targetType == .group {
            searchUserController?.searchGroupType(with: text, newSelectedUsers: newSelectedUsers, currentUsers: currentUsers, { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let users):
                        self?.searchUsers = users
                        self?.delegate?.screenViewModelDidSearchUser()
                    case .failure(let error):
                        switch error {
                        case .textEmpty:
                            self?.isSearch = false
                            self?.updateSelectedUserInfo()
                            self?.delegate?.screenViewModelDidSearchUser()
                        case .unknown:
                            break
                        }
                    }
                }
            })
        } else {
            searchUserController?.searchRecentType(with: text, newSelectedUsers: newSelectedUsers, currentUsers: currentUsers, users: users, { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let users):
                        self?.searchUsers = users
                        self?.delegate?.screenViewModelDidSearchUser()
                    case .failure(let error):
                        switch error {
                        case .textEmpty:
                            self?.isSearch = false
                            self?.updateSelectedUserInfo()
                            self?.delegate?.screenViewModelDidSearchUser()
                        case .unknown:
                            break
                        }
                    }
                }
            })
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
    
    // [Back up]
//    func loadmore() {
//        var success: Bool = false
//        if isSearch {
//            guard let controller = searchUserController else { return }
//            success = controller.loadmore(isSearch: isSearch)
//        } else {
//            guard let controller = fetchChannelController else { return }
//            fetchChannelController?.newSelectedUsers = newSelectedUsers
//            fetchChannelController?.currentUsers = currentUsers
//            success = controller.loadmore(isSearch: isSearch)
//        }
//
//        if success {
//            delegate?.screenViewModelLoadingState(for: .loading)
//        } else {
//            delegate?.screenViewModelLoadingState(for: .loaded)
//        }
//    }
    
    func loadmore() {
        if isSearch && targetType == .group {
            searchUserController?.loadMore(isSearch: isSearch)
        } else {
            guard let controller = fetchChannelController else { return }
            fetchChannelController?.newSelectedUsers = newSelectedUsers
            fetchChannelController?.currentUsers = currentUsers
            let success = controller.loadmore(isSearch: isSearch)
            
            if success {
                delegate?.screenViewModelLoadingState(for: .loading)
            } else {
                delegate?.screenViewModelLoadingState(for: .loaded)
            }
        }
    }
}

extension AmityForwardChannelPickerScreenViewModel: AmityForwardSearchChannelControllerDelegate {
    func willLoadMore(isLoadingMore: Bool) {
        if isLoadingMore && targetType == .group {
            searchUser(with: currentKeyword)
        }
    }
}
