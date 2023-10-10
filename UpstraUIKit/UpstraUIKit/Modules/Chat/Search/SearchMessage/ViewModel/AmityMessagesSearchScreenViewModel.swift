//
//  AmityMessagesSearchScreenViewModel.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 10/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

class AmityMessagesSearchScreenViewModel: AmityMessagesSearchScreenViewModelType {
    
    weak var delegate: AmityMessagesSearchScreenViewModelDelegate?
    
    // MARK: Repository
    private let messageRepository = AmityMessageRepository(client: AmityUIKitManagerInternal.shared.client)

    // MARK: - Properties
    private let debouncer = Debouncer(delay: 0.5)
    private var messageList: [AmitySDK.AmityMessage] = []
    private var fromIndex: Int = 0
    private var size: Int = 20
    private var currentKeyword: String = ""
    private var isEndingResult: Bool = false
    private var isLoadingMore: Bool = false
    private let dispatchGroup = DispatchGroup()
    private var dummyList: [String] = []
    private var tokenArray: [AmityNotificationToken?] = []

    init() {
    }
}

// MARK: - DataSource
extension AmityMessagesSearchScreenViewModel {
    
    func numberOfKeyword() -> Int {
        return messageList.count
    }
    
    func item(at indexPath: IndexPath) -> AmitySDK.AmityMessage? {
        guard !messageList.isEmpty else { return nil }
        return messageList[indexPath.row]
    }
    
}

// MARK: - Action
extension AmityMessagesSearchScreenViewModel {
    
    func search(withText text: String?) {
        /* Check text is nil or is searching for ignore searching */
        guard let newKeyword = text else { return }
        
        /* Check is current keyword with input text for clear data and reset static value or not */
        if currentKeyword != newKeyword {
            if !isLoadingMore {
                dummyList = []
            }
            messageList = []
            currentKeyword = newKeyword
            fromIndex = 0
            isEndingResult = false
            isLoadingMore = false
        }
        
        delegate?.screenViewModel(self, loadingState: .loading)
        var serviceRequest = RequestSearchingChat()
        serviceRequest.keyword = currentKeyword
        serviceRequest.size = size
        serviceRequest.from = fromIndex
        /* Set static value to true for block new searching in this time */
        serviceRequest.requestSearchMessages { [self] result in
            switch result {
            case .success(let dataResponse):
                let updatedMessageList = dataResponse
                /* Check is data not more than size request is mean is ending result */
                if updatedMessageList.count < size {
                    isEndingResult = true
                }
                getMessageIds(updatedMessageList)
            case .failure(let error):
                print(error)
                
                /* Hide loading indicator */
                DispatchQueue.main.async {
                    self.delegate?.screenViewModel(self, loadingState: .loaded)
                }
            }
        }
    }
    
    private func getMessageIds(_ messageIds: [String]) {
        dummyList += messageIds
        DispatchQueue.main.async { [self] in
            for messageId in messageIds {
                dispatchGroup.enter()
                let messageObject = messageRepository.getMessage(messageId)
                let token = messageObject.observe { [weak self] (message, error) in
                    guard let strongSelf = self else { return }
                    if let _ = AmityError(error: error) {
                        strongSelf.dispatchGroup.leave()
                    } else {
                        if let message = message.snapshot {
                            //  Handle message result
                            strongSelf.messageList.append(message)
                            strongSelf.dispatchGroup.leave()
                        }
                    }
                }
                
                tokenArray.append(token)
            }
            
            dispatchGroup.notify(queue: .main) {
                let sortedArray = self.sortArrayPositions(array1: self.dummyList, array2: self.messageList)
                self.prepareData(updatedMessageList: sortedArray)
                self.tokenArray.removeAll()
            }
            
            if dummyList.isEmpty {
                let sortedArray = self.sortArrayPositions(array1: self.dummyList, array2: self.messageList)
                self.prepareData(updatedMessageList: sortedArray)
            }
        }
    }
    
    private func prepareData(updatedMessageList: [AmitySDK.AmityMessage]) {
        DispatchQueue.main.async { [self] in
            /* Check is loading result more from current keyword or result from new keyword */
            if isLoadingMore {
                self.messageList += updatedMessageList
            } else {
                self.messageList = updatedMessageList
            }
            
            if messageList.isEmpty {
                delegate?.screenViewModelDidSearchNotFound(self)
            } else {
                delegate?.screenViewModelDidSearch(self)
            }
            
            /* Hide loading indicator */
            delegate?.screenViewModel(self, loadingState: .loaded)
        }
    }
    
    func loadMore() {
        /* Check is ending result or result not found for ignore load more */
        if isEndingResult || messageList.isEmpty { return }
        
        /* Set static value to true for prepare data in loading more case */
        isLoadingMore = true
        
        /* Get data next section */
        delegate?.screenViewModel(self, loadingState: .loading)
        debouncer.run { [self] in
            fromIndex += size
            search(withText: currentKeyword)
        }
    }
    
    //  Sort function by list from fetchPosts
    private func sortArrayPositions(array1: [String], array2: [AmitySDK.AmityMessage]) -> [AmitySDK.AmityMessage] {
        var sortedArray: [AmitySDK.AmityMessage] = []
        
        for messageId in array1 {
            if let index = array2.firstIndex(where: { $0.messageId == messageId }) {
                sortedArray.append(array2[index])
            }
        }
        
        return sortedArray
    }
}
