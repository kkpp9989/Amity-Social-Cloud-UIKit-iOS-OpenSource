//
//  AmityMessagesSearchScreenViewModel.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 10/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

struct MessageSearchModelData {
    var messageObjc: Message
    var channelObjc: AmityChannelModel
}

class AmityMessagesSearchScreenViewModel: AmityMessagesSearchScreenViewModelType {
    
    weak var delegate: AmityMessagesSearchScreenViewModelDelegate?
    
    // MARK: Repository
    private let messageRepository = AmityMessageRepository(client: AmityUIKitManagerInternal.shared.client)
    private let channelRepository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)

    // MARK: - Properties
    private let debouncer = Debouncer(delay: 0.5)
    private var messageList: [Message] = []
    private var channelList: [AmityChannelModel] = []
    private var dataList: [MessageSearchModelData] = []
    private var size: Int = 20
    private var currentKeyword: String = ""
    private var isEndingResult: Bool = false
    private var isLoadingMore: Bool = false
    private let dispatchGroup = DispatchGroup()
    private var dummyList: [String] = []
    private var paginateToken: String = ""
    private var tokenArray: [AmityNotificationToken?] = []

    init() {
    }
}

// MARK: - DataSource
extension AmityMessagesSearchScreenViewModel {
    
    func numberOfKeyword() -> Int {
        return dataList.count
    }
    
    func item(at indexPath: IndexPath) -> MessageSearchModelData? {
        guard !dataList.isEmpty else { return nil }
        return dataList[indexPath.row]
    }
    
}

// MARK: - Action
extension AmityMessagesSearchScreenViewModel {

    func search(withText text: String?) {
        /* Check text is nil or is searching for ignore searching */
        guard let newKeyword = text else { return }

        tokenArray.removeAll()

        /* Check is current keyword with input text for clear data and reset static value or not */
        if currentKeyword != newKeyword {
            if !isLoadingMore {
                dummyList = []
                messageList = []
                channelList = []
                paginateToken = ""
            }
            dataList = []
            currentKeyword = newKeyword
            isEndingResult = false
        }

        AmityEventHandler.shared.hideKTBLoading() // Hide old loading if need
        AmityEventHandler.shared.showKTBLoading()
//        delegate?.screenViewModel(self, loadingState: .loading)
        var serviceRequest = RequestSearchingChat()
        serviceRequest.keyword = currentKeyword
        serviceRequest.size = size
        serviceRequest.paginateToken = paginateToken
        /* Set static value to true for block new searching in this time */
        serviceRequest.requestSearchMessages { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let dataResponse):
                let updatedMessageList = dataResponse
                strongSelf.paginateToken = dataResponse.paging.next ?? ""
                /* Check is data not more than size request is mean is ending result */
                if updatedMessageList.messages.count < strongSelf.size {
                    strongSelf.isEndingResult = true
                }

                strongSelf.dummyList = updatedMessageList.messages.compactMap { $0.messageID }
                
                print("[Search][Channel][Message] Amount latest result search : \(strongSelf.dummyList.count)")

                let sortedArray = strongSelf.sortArrayPositions(array1: strongSelf.dummyList, array2: updatedMessageList.messages)
                strongSelf.prepareData(updatedMessageList: sortedArray)
            case .failure(let error):
                print("[Search][Channel][Message] Error from result search : \(error.localizedDescription)")

                DispatchQueue.main.async {
                    AmityEventHandler.shared.hideKTBLoading()
//                    strongSelf.delegate?.screenViewModel(strongSelf, loadingState: .loaded)
                    strongSelf.isLoadingMore = false
                }
                /* Hide loading indicator */
                DispatchQueue.main.async {
                    strongSelf.mapMessageAndChannelToDataList()
                }
            }
        }
    }

    private func prepareData(updatedMessageList: [Message]) {
        DispatchQueue.main.async { [self] in
            /* Check is loading result more from the current keyword or result from a new keyword */
            if isLoadingMore {
                // Filter out messages that are already in the messageList
                let filteredMessages = updatedMessageList.filter { message in
                    !messageList.contains { $0.messageID == message.messageID }
                }
                messageList += filteredMessages
            } else {
                messageList = updatedMessageList
            }

            let filteredChannelIds = messageList.compactMap { $0.channelID }
            getChannel(channelList: filteredChannelIds)
        }
    }

    func getChannel(channelList: [String]) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }

            for channelId in channelList {
                strongSelf.dispatchGroup.enter()

                // Use a flag to track whether leave has been called for this task
                var leaveCalled = false

                let token = strongSelf.channelRepository.getChannel(channelId).observe { [weak self] (channel, error) in
                    guard let strongSelf = self else {
                        // Check if leave has already been called
                        if !leaveCalled {
                            leaveCalled = true
                            strongSelf.dispatchGroup.leave()
                        }
                        return
                    }
                    guard let object = channel.snapshot else {
                        // Check if leave has already been called
                        if !leaveCalled {
                            leaveCalled = true
                            strongSelf.dispatchGroup.leave()
                        }
                        return
                    }

                    if let _ = AmityError(error: error) {
                    } else {
                        let channelModel = AmityChannelModel(object: object)
                        strongSelf.channelList.append(channelModel)
                    }
                    
                    // Check if leave has already been called
                    if !leaveCalled {
                        leaveCalled = true
                        strongSelf.dispatchGroup.leave()
                    }
                }

                strongSelf.tokenArray.append(token)
            }

            strongSelf.dispatchGroup.notify(queue: .main) {
                let sortedArray = strongSelf.sortArrayPositions(array1: channelList, array2: strongSelf.channelList)
                strongSelf.prepareData(updatedChannelList: sortedArray)
                strongSelf.tokenArray.removeAll()
            }
        }
    }

    private func prepareData(updatedChannelList: [AmityChannelModel]) {
        DispatchQueue.main.async { [self] in
            channelList = updatedChannelList

            mapMessageAndChannelToDataList()
        }
    }

    func loadMore() {
        /* Check is ending result or result not found for ignore load more */
        if isEndingResult || messageList.isEmpty { return }

        /* Set static value to true for prepare data in loading more case */
        isLoadingMore = true

        /* Get data next section */
//        AmityEventHandler.shared.showKTBLoading()
//        delegate?.screenViewModel(self, loadingState: .loading)
        debouncer.run { [self] in
            search(withText: currentKeyword)
        }
    }

    //  Sort function by list from fetchPosts
    private func sortArrayPositions(array1: [String], array2: [Message]) -> [Message] {
        var sortedArray: [Message] = []

        for messageId in array1 {
            if let index = array2.firstIndex(where: { $0.messageID == messageId }) {
                sortedArray.append(array2[index])
            }
        }

        return sortedArray
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

    private func mapMessageAndChannelToDataList() {
        dataList.removeAll() // Clear existing data

        for index in 0..<min(messageList.count, channelList.count) {
            let messageObjc = messageList[index]
            let channelObjc = channelList[index]

            dispatchGroup.enter() // Enter the group for each iteration

            // Perfo3rm your data processing here
            let data = MessageSearchModelData(
                messageObjc: messageObjc,
                channelObjc: channelObjc
            )

            dataList.append(data)

            // Leave the group when the processing for this iteration is complete
            dispatchGroup.leave()
        }

        // Wait for all iterations to complete
        dispatchGroup.notify(queue: .main) {
            /* Hide loading indicator */
            AmityEventHandler.shared.hideKTBLoading()
//            self.delegate?.screenViewModel(self, loadingState: .loaded)
            self.isLoadingMore = false

            if self.dataList.isEmpty {
                self.delegate?.screenViewModelDidSearchNotFound(self)
            } else {
                self.delegate?.screenViewModelDidSearch(self)
            }
        }
    }

    func clearData() {
        dataList.removeAll()
        messageList.removeAll()
        channelList.removeAll()
        dummyList.removeAll()

        delegate?.screenViewModelDidSearch(self)
    }
}
