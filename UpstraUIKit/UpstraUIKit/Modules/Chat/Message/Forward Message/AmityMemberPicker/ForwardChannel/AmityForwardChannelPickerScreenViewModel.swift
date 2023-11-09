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
    private var userRepository: AmityUserFollowManager?
    private var channelRepository: AmityChannelRepository?

    // MARK: - Controller
    private var fetchChannelController: AmityFetchForwardChannelController?
    private var searchUserController: AmityForwardSearchUserController?
    private var selectUserContrller: AmityForwardSelectUserController?
    
    private var users: AmityFetchForwardChannelController.GroupUser = []
    private var searchUsers: [AmitySelectMemberModel] = []
    private var storeUsers: [AmitySelectMemberModel] = [] {
        didSet {
            delegate?.screenViewModelCanDone(enable: !storeUsers.isEmpty)
        }
    }
    
    private var isSearch: Bool = false
    
    init(type: AmityChannelViewType) {
        userRepository = AmityUserFollowManager(client: AmityUIKitManagerInternal.shared.client)
        channelRepository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
        fetchChannelController = AmityFetchForwardChannelController(repository: channelRepository, type: type)
        searchUserController = AmityForwardSearchUserController(repository: userRepository, type: .followers)
        selectUserContrller = AmityForwardSelectUserController()
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
extension AmityForwardChannelPickerScreenViewModel {
    
    func setCurrentUsers(users: [AmitySelectMemberModel], isFromAnotherTab: Bool) {
        storeUsers = users
        
        if storeUsers.count == 0 {
            delegate?.screenViewModelDidSetCurrentUsers(title: AmityLocalizedStringSet.selectMemberListTitle.localizedString, isEmpty: true, isFromAnotherTab: isFromAnotherTab)
        } else {
            delegate?.screenViewModelDidSetCurrentUsers(title: String.localizedStringWithFormat(AmityLocalizedStringSet.selectMemberListSelectedTitle.localizedString, "\(storeUsers.count)"), isEmpty: false, isFromAnotherTab: isFromAnotherTab)
        }
    }
    
    func getChannels() {
        fetchChannelController?.storeUsers = storeUsers
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
    
    func updateSelectedUserInfo() {
        if isSearch {
            // Edit selected of search user
            for (index, data) in searchUsers.enumerated() {
                if storeUsers.contains(where: { $0.userId == data.userId } ) {
                    searchUsers[index].isSelected = true
                } else {
                    searchUsers[index].isSelected = false
                }
            }
        } else {
            // Edit selected of user
            for (indexGroup, (key, group)) in users.enumerated() {
                for (indexUser, user) in group.enumerated() {
                    if storeUsers.contains(where: { $0.userId == user.userId } ) {
                        users[indexGroup].value[indexUser].isSelected = true
                    } else {
                        users[indexGroup].value[indexUser].isSelected = false
                    }
                }
            }
        }
    }
    
    func loadmore() {
        var success: Bool = false
        if isSearch {
            guard let controller = searchUserController else { return }
            success = controller.loadmore(isSearch: isSearch)
        } else {
            guard let controller = fetchChannelController else { return }
            fetchChannelController?.storeUsers = storeUsers
            success = controller.loadmore(isSearch: isSearch)
        }
        
        if success {
            delegate?.screenViewModelLoadingState(for: .loading)
        } else {
            delegate?.screenViewModelLoadingState(for: .loaded)
        }
    }
}
