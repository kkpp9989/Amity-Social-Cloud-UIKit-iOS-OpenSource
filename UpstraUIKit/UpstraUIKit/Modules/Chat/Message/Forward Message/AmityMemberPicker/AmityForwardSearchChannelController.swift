//
//  AmityForwardSearchChannelController.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 11/12/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityForwardSearchChannelControllerDelegate {
    func willLoadMore(isLoadingMore: Bool)
}

final class AmityForwardSearchChannelController {
    
    private weak var repository: AmityChannelRepository?
    private var collection: AmityCollection<AmityChannel>?
    
    private var targetType: AmityChannelViewType
    private var channels: [AmitySelectMemberModel] = []
    
    private let dispatchGroup = DispatchGroup()
    private let debouncer = Debouncer(delay: 0.3)
    
    private var paginateToken: String = ""
    private var isEndingResult: Bool = false
    private var isLoadingMore: Bool = false
    private var currentKeyword: String = ""
    
    public var delegate: AmityForwardSearchChannelControllerDelegate?
    
    init(repository: AmityChannelRepository?, type: AmityChannelViewType) {
        self.repository = repository
        self.targetType = type
    }
    
    // Search and filter from current fetched user data because recent chat must show not more than 10 item
    func searchRecentType(with text: String, newSelectedUsers: [AmitySelectMemberModel], currentUsers: [AmitySelectMemberModel], users: AmityFetchForwardChannelController.GroupUser, _ completion: @escaping (Result<[AmitySelectMemberModel], AmitySearchUserControllerError>) -> Void) {
        if text == "" {
            completion(.failure(.textEmpty))
        }
        
        var filteredUsers: [AmitySelectMemberModel] = []
        for (_, (_, group)) in users.enumerated() {
            for (_, user) in group.enumerated() {
                // Set selected
                user.isSelected = newSelectedUsers.contains(where: { $0.userId == user.userId } ) || currentUsers.contains(where: { $0.userId == user.userId } ) ? true : false
                // Add to list if displayname contained keyword
                if let displayName = user.displayName?.lowercased(), displayName.contains(text.lowercased()) {
                    filteredUsers.append(user)
                }
            }
        }
        
        completion(.success(filteredUsers))
    }
    
    // Search and filter from search channel API
    func searchGroupType(with text: String, newSelectedUsers: [AmitySelectMemberModel], currentUsers: [AmitySelectMemberModel], _ completion: @escaping (Result<[AmitySelectMemberModel], AmitySearchUserControllerError>) -> Void) {
        if currentKeyword != text {
            paginateToken = ""
            channels = []
            currentKeyword = text
            isEndingResult = false
            isLoadingMore = false
        }
        
        if text == "" {
            completion(.failure(.textEmpty))
        }
        
        var request = RequestSearchingChat()
        request.keyword = currentKeyword
        request.isMemberOnly = true
        request.paginateToken = paginateToken
        request.requestSearchChannels(types: [targetType]) { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let dataResponse):
                // Get pagination of response if need
                if let paginateToken = dataResponse.paging?.next, !paginateToken.isEmpty {
                    strongSelf.paginateToken = paginateToken
                } else {
                    strongSelf.isEndingResult = true
                }
                // Get data from response
                let resultChannels = dataResponse.channels ?? []
                let dummyChannelIdList = resultChannels.compactMap({ $0.channelId }) // Use for sort response
//                print("[Search][Channel][Group] Amount latest result search : \(resultChannels.count) | paginateToken: \(strongSelf.paginateToken)")
                let endIndex = resultChannels.count
                // Dictionary to keep track of whether leave has been called for a specific channelId
                var channelIdLeaveMap: [String: Bool] = [:]
                // Process data
                for index in 0..<endIndex {
                    strongSelf.dispatchGroup.enter()
                    channelIdLeaveMap[String(index)] = false
                    // Filter channels
                    if strongSelf.targetType == .broadcast, let channelId = resultChannels[index].channelId { // Case : Broadcast type
                        // Get channels that have broadcasting permission only
                        let object = resultChannels[index]
                        DispatchQueue.main.async {
                            let userController = AmityChatUserController(channelId: channelId)
                            userController.getEditGroupChannelPermission { isHavePermission in
                                if isHavePermission {
                                    AmityUIKitManagerInternal.shared.fileService.getImageURLByFileId(fileId: object.avatarFileId ?? "") { resultImageURL in
                                        var model: AmitySelectMemberModel
                                        switch resultImageURL {
                                        case .success(let imageURL):
                                            model = AmitySelectMemberModel(object: object, avatarURL: imageURL)
                                        case .failure(_):
                                            model = AmitySelectMemberModel(object: object, avatarURL: nil)
                                        }
                                        
                                        // Set selected of channel
                                        model.isSelected = newSelectedUsers.contains { $0.userId == object.channelId } || currentUsers.contains { $0.userId == object.channelId }
                                        // Add channel to list with condition
                                        if let isDeleted = object.isDeleted, !isDeleted,
                                           !strongSelf.channels.contains(where: { $0.userId == model.userId }) // [Workaround] Filter duplicate data
                                        {
                                            strongSelf.channels.append(model)
                                        }
                                        
                                        if let leaveCalled = channelIdLeaveMap[String(index)], !leaveCalled {
                                            channelIdLeaveMap[String(index)] = true
                                            strongSelf.dispatchGroup.leave()
                                        }
                                    }
                                } else {
                                    if let leaveCalled = channelIdLeaveMap[String(index)], !leaveCalled {
                                        channelIdLeaveMap[String(index)] = true
                                        strongSelf.dispatchGroup.leave()
                                    }
                                }
                            }
                        }
                    } else { // Case : Other type
                        // Get each channel data and create model
                        let object: Channel = resultChannels[index]
    //                    print("[Search][Channel][Group] Group name: \(object.displayName ?? "") | id: \(object.channelId ?? "")")
                        // Get image URL
                        AmityUIKitManagerInternal.shared.fileService.getImageURLByFileId(fileId: object.avatarFileId ?? "") { resultImageURL in
                            var model: AmitySelectMemberModel
                            switch resultImageURL {
                            case .success(let imageURL):
                                model = AmitySelectMemberModel(object: object, avatarURL: imageURL)
                            case .failure(_):
                                model = AmitySelectMemberModel(object: object, avatarURL: nil)
                            }
                            
                            // Set selected of channel
                            model.isSelected = newSelectedUsers.contains { $0.userId == object.channelId } || currentUsers.contains { $0.userId == object.channelId }
                            // Add channel to list with condition
                            if let isDeleted = object.isDeleted, !isDeleted,
                               !strongSelf.channels.contains(where: { $0.userId == model.userId }) // [Workaround] Filter duplicate data
                            {
                                strongSelf.channels.append(model)
                            }
                            
                            if let leaveCalled = channelIdLeaveMap[String(index)], !leaveCalled {
                                channelIdLeaveMap[String(index)] = true
                                strongSelf.dispatchGroup.leave()
                            }
                        }
                    }
                }
                
                strongSelf.dispatchGroup.notify(queue: .main) {
                    let sortedArray = strongSelf.sortArrayPositions(array1: dummyChannelIdList, array2: strongSelf.channels)
                    completion(.success(sortedArray))
                }
            case .failure(_):
                strongSelf.isLoadingMore = false
                completion(.failure(.unknown))
            }
        }
    }
    
    // Load more for search group type
    func loadMore(isSearch: Bool) {
        if isSearch {
            /* Check is ending result or result not found for ignore load more */
            if isEndingResult || channels.isEmpty { return }
            
            /* Set static value to true for prepare data in loading more case */
            isLoadingMore = targetType == .group ? true : false
        }
        
        /* Get data next section if need */
        debouncer.run { [self] in
            delegate?.willLoadMore(isLoadingMore: isLoadingMore)
        }
    }
    
    func clearData() {
        channels.removeAll()
        paginateToken = ""
        currentKeyword = ""
    }
    
    private func sortArrayPositions(array1: [String], array2: [AmitySelectMemberModel]) -> [AmitySelectMemberModel] {
        var sortedArray: [AmitySelectMemberModel] = []

        for channelId in array1 {
            if let index = array2.firstIndex(where: { $0.userId == channelId }) {
                sortedArray.append(array2[index])
            }
        }

        return sortedArray
    }
}


