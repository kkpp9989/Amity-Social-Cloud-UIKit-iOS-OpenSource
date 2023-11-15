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
    private var channelList: [Channel] = []
    private var currentKeyword: String = ""
    private var isEndingResult: Bool = false
    private var isLoadingMore: Bool = false
    private let dispatchGroup = DispatchGroup()
//    private var dummyList: [String] = [] // [Original]
    private var dummyList: [Channel] = []
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
    
    func item(at indexPath: IndexPath) -> Channel? {
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
        
        AmityEventHandler.shared.showKTBLoading()
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

                var channels: [Channel] = dataResponse.channels ?? []
                let channelsPermission: [ChannelUserPermission] = dataResponse.channelsPermission ?? []

                // Map data user permission to channels data : .membership
                for (index, data) in channels.enumerated() {
                    if let indexOfChannelId = channelsPermission.firstIndex(where: { $0.channelId == data.channelId }) {
                        channels[index].membership = channelsPermission[indexOfChannelId].membership
                    }
                }
                
                // Prepare data
                prepareData(updatedChannelList: channels)
            case .failure(let error):
                print(error)
                
                /* Hide loading indicator */
                DispatchQueue.main.async { [self] in
                    AmityEventHandler.shared.hideKTBLoading()
                    if channelList.isEmpty {
                        delegate?.screenViewModelDidSearchNotFound(self)
                    } else {
                        delegate?.screenViewModelDidSearch(self)
                    }
                }
            }
        }
    }
    
    private func prepareData(updatedChannelList: [Channel]) {
        DispatchQueue.main.async { [self] in
            channelList = updatedChannelList
            /* Hide loading indicator */
            AmityEventHandler.shared.hideKTBLoading()
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
        AmityEventHandler.shared.showKTBLoading()
        debouncer.run { [self] in
            search(withText: currentKeyword)
        }
    }
    
    func join(withModel model: Channel) {
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: channelRepository.joinChannel(channelId:), parameters: model.channelId ?? "") {_, error in
            if let error = AmityError(error: error) {
                print(error)
            } else {
                // Send custom message with join chat scenario
                let subjectDisplayName = AmityUIKitManagerInternal.shared.client.user?.snapshot?.displayName ?? AmityUIKitManager.displayName
                let customMessageController = AmityCustomMessageController(channelId: model.channelId ?? "")
                customMessageController.send(event: .joinedChat, subjectUserName: subjectDisplayName, objectUserName: "") { result in
                    switch result {
                    case .success(_):
                        print(#"[Custom message] send message success : "\#(subjectDisplayName) joined this chat"#)
                    case .failure(_):
                        print(#"[Custom message] send message fail : "\#(subjectDisplayName) joined this chat"#)
                    }
                }
                
                // Update result search again for update join info
                self.search(withText: self.currentKeyword)
            }
        }
    }
    
    // อย่าลืมกลับมาแก้
//    private func sortArrayPositions(array1: [String], array2: [AmityChannelModel]) -> [AmityChannelModel] {
//        var sortedArray: [AmityChannelModel] = []
//
//        for channelId in array1 {
//            if let index = array2.firstIndex(where: { $0.channelId == channelId }) {
//                sortedArray.append(array2[index])
//            }
//        }
//
//        return sortedArray
//    }

    func clearData() {
        channelList.removeAll()
        dummyList.removeAll()
        
        delegate?.screenViewModelDidSearch(self)
    }
}
