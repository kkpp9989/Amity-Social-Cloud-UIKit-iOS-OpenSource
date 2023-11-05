//
//  AmityChannelsSearchViewModel.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 16/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation
import AmitySDK

class AmityChannelsSearchViewModel: AmityChannelsSearchScreenViewModelType {
    
    weak var delegate: AmityChannelsSearchScreenViewModelDelegate?
    
    // MARK: Repository
    private let channelRepository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)

    // MARK: - Properties
    private let debouncer = Debouncer(delay: 0.5)
    private var channelList: [AmityChannelModel] = []
    private var currentKeyword: String = ""
    private var isEndingResult: Bool = false
    private var isLoadingMore: Bool = false
    private let dispatchGroup = DispatchGroup()
    private var dummyList: [String] = []
    private var tokenArray: [AmityNotificationToken?] = []
    private var paginateToken: String = ""

    init() {
    }
}

// MARK: - DataSource
extension AmityChannelsSearchViewModel {
    
    func numberOfKeyword() -> Int {
        return channelList.count
    }
    
    func item(at indexPath: IndexPath) -> AmityChannelModel? {
        guard !channelList.isEmpty else { return nil }
        return channelList[indexPath.row]
    }
    
}

// MARK: - Action
extension AmityChannelsSearchViewModel {
    
    func search(withText text: String?) {
        /* Check text is nil or is searching for ignore searching */
        guard let newKeyword = text else { return }
        
        /* Check is current keyword with input text for clear data and reset static value or not */
        if currentKeyword != newKeyword {
            if !isLoadingMore {
                dummyList = []
                paginateToken = ""
            }
            channelList = []
            currentKeyword = newKeyword
            isEndingResult = false
        }
        
        delegate?.screenViewModel(self, loadingState: .loading)
        var serviceRequest = RequestSearchingChat()
        serviceRequest.keyword = currentKeyword
        serviceRequest.paginateToken = paginateToken
        /* Set static value to true for block new searching in this time */
        serviceRequest.requestSearchChannels { [self] result in
            switch result {
            case .success(let dataResponse):
                /* Check is data not more than size request is mean is ending result */
                if let paginateToken = dataResponse.paging?.next, !paginateToken.isEmpty {
                    self.paginateToken = paginateToken
                } else {
                    isEndingResult = true
                }
                let channelIds = dataResponse.channels?.compactMap { $0.id } ?? []
                dummyList = channelIds
                getChannelIds(channelIds)
            case .failure(let error):
                print(error)
                
                /* Hide loading indicator */
                DispatchQueue.main.async { [self] in
                    delegate?.screenViewModel(self, loadingState: .loaded)
                    if channelList.isEmpty {
                        delegate?.screenViewModelDidSearchNotFound(self)
                    } else {
                        delegate?.screenViewModelDidSearch(self)
                    }
                }
            }
        }
    }
    
    private func getChannelIds(_ channelIds: [String]) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            
            for channelId in channelIds {
                strongSelf.dispatchGroup.enter()
                
                // Use a flag to track whether leave has been called for this task
                var leaveCalled = false
                
                let token = strongSelf.channelRepository.getChannel(channelId).observe { [weak self] (channel, error) in
                    guard let strongSelf = self else { return }
                    guard let object = channel.snapshot else { return }
                    
                    if let _ = AmityError(error: error) {
                        // Check if leave has already been called
                        if !leaveCalled {
                            leaveCalled = true
                            strongSelf.dispatchGroup.leave()
                        }
                    } else {
                        let channelModel = AmityChannelModel(object: object)
                        strongSelf.channelList.append(channelModel)
                        
                        // Check if leave has already been called
                        if !leaveCalled {
                            leaveCalled = true
                            strongSelf.dispatchGroup.leave()
                        }
                    }
                }
                
                strongSelf.tokenArray.append(token)
            }
            
            // Wait for all iterations to complete
            strongSelf.dispatchGroup.notify(queue: .main) {
                let sortedArray = strongSelf.sortArrayPositions(array1: strongSelf.dummyList, array2: strongSelf.channelList)
                strongSelf.prepareData(updatedChannelList: sortedArray)
                strongSelf.tokenArray.removeAll()
            }
        }
    }

    
    private func prepareData(updatedChannelList: [AmityChannelModel]) {
        DispatchQueue.main.async { [self] in
            channelList = updatedChannelList
            /* Hide loading indicator */
            delegate?.screenViewModel(self, loadingState: .loaded)
            isLoadingMore = false
            
            if channelList.isEmpty {
                delegate?.screenViewModelDidSearchNotFound(self)
            } else {
                delegate?.screenViewModelDidSearch(self)
            }
        }
    }
    
    func loadMore() {
        /* Check is ending result or result not found for ignore load more */
        if isEndingResult { return }
        
        /* Set static value to true for prepare data in loading more case */
        isLoadingMore = true
        
        /* Get data next section */
        delegate?.screenViewModel(self, loadingState: .loading)
        debouncer.run { [self] in
            search(withText: currentKeyword)
        }
    }
    
    func join(withModel model: AmityChannelModel) {
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: channelRepository.joinChannel(channelId:), parameters: model.channelId) {_, error in
            if let error = AmityError(error: error) {
                print(error)
            } else {
                self.getChannelIds(self.dummyList)
            }
        }
    }
    
    private func sortArrayPositions(array1: [String], array2: [AmityChannelModel]) -> [AmityChannelModel] {
        var sortedArray: [AmityChannelModel] = []
        
        for channelId in array1 {
            if let index = array2.firstIndex(where: { $0.channelId == channelId }) {
                sortedArray.append(array2[index])
            }
        }
        
        return sortedArray
    }

    func clearData() {
        channelList.removeAll()
        dummyList.removeAll()
        
        delegate?.screenViewModelDidSearchNotFound(self)
    }
}
