//
//  AmityPreviewSelectedFromPickerScreenViewModel.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 1/2/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import AmitySDK

class AmityPreviewSelectedFromPickerScreenViewModel: AmityPreviewSelectedFromPickerScreenViewModelType {
    
    // MARK: - Controller (Message)
    private let messageRepository: AmityMessageRepository = AmityMessageRepository(client: AmityUIKitManagerInternal.shared.client)
    
    // MARK: - Delegate
    weak var delegate: AmityPreviewSelectedFromPickerScreenViewModelDelegate?
    
    // MARK: - Data
    private let datas: [AmitySelectMemberModel]
    
    // MARK: - Data (Message)
    private var broadcastMessage: AmityBroadcastMessageCreatorModel?
    
    // MARK: - Utilities
    private let dispatchGroup: DispatchGroup = DispatchGroup()
    
    init(selectedData: [AmitySelectMemberModel], broadcastMessage: AmityBroadcastMessageCreatorModel? = nil) {
        datas = selectedData
        self.broadcastMessage = broadcastMessage
    }

}

// MARK: - DataSource
extension AmityPreviewSelectedFromPickerScreenViewModel {

    func numberOfDatas() -> Int {
        datas.count
    }
    
    func data(at row: Int) -> AmitySelectMemberModel? {
        datas[row]
    }
    
}

// MARK: - Action (Send message)
extension AmityPreviewSelectedFromPickerScreenViewModel {

    func sendBroadcastMessage() {
        guard let message = broadcastMessage else {
            delegate?.screenViewModelDidSendBroadcastMessage(isSuccess: false)
            return
        }
        
        // Requesting Broadcast message each channel
        for channel in datas {
            dispatchGroup.enter()
            let broadcastType = message.broadcastType
            let channelId = channel.userId
            switch broadcastType {
            case .text:
                let createOptions = AmityTextMessageCreateOptions(subChannelId: channelId, text: message.text ?? "")
                AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: messageRepository.createTextMessage(options:), parameters: createOptions) { [weak self] message, error in
                    guard let strongSelf = self else { return }
                    strongSelf.dispatchGroup.leave()
                }
            case .image: // Not ready
                dispatchGroup.leave()
            case .imageWithCaption: // Not ready
                dispatchGroup.leave()
            case .file: // Not ready
                dispatchGroup.leave()
            }
        }
        
        // Wait for all requests to complete
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.screenViewModelDidSendBroadcastMessage(isSuccess: true)
        }
    }
    
}
