//
//  AmityPreviewSelectedFromPickerScreenViewModel.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 1/2/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import AmitySDK
import UIKit

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
    private let queue = OperationQueue()
    
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

    // MARK: - Action (Send message) : Broadcast
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
                sendTextMessage(text: message.text ?? "", channelId: channelId)
            case .image:
                sendMediaMessage(medias: message.medias ?? [], type: .image, channelId: channelId)
            case .imageWithCaption:
                sendMediaMessage(medias: message.medias ?? [], type: .image, channelId: channelId, caption: message.text ?? "")
            case .file:
                sendFileMessage(files: message.files ?? [], channelId: channelId)
            }
        }
        
        // Wait for all requests to complete
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.screenViewModelDidSendBroadcastMessage(isSuccess: true)
        }
    }
    
    // MARK: - Action (Send message) : Text
    private func sendTextMessage(text: String, channelId: String) {
        let createOptions = AmityTextMessageCreateOptions(subChannelId: channelId, text: text)
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: messageRepository.createTextMessage(options:), parameters: createOptions) { [weak self] message, error in
            guard error == nil, let _ = message else {
                Log.add(#"[UIKit] Create text message "\#(text)" fail with error: \#(error?.localizedDescription)"#)
                self?.dispatchGroup.leave()
                return
            }
            
            Log.add(#"[UIKit] Create text message "\#(text)" success with message Id: \#(message?.messageId) | type: \#(message?.messageType)"#)
            self?.dispatchGroup.leave()
        }
    }
    
    // MARK: - Action (Send message) : Media
    private func sendMediaMessage(medias: [AmityMedia], type: AmityMediaType, channelId: String, caption: String? = nil) {
        for media in medias {
            // Separate process from state of media
            if type == .image { // Case : Image type
                switch media.state {
                case .localAsset(_): // From send image message
                    media.getImageForUploading { [weak self] result in
                        guard let strongSelf = self else { return }
                        switch result {
                        case .success(let image):
                            let imageURL = strongSelf.createTempImage(image: image)
                            strongSelf.createImageMessage(imageURL: imageURL, channelId: channelId, caption: caption)
                        case .failure:
                            print("failure")
                            strongSelf.dispatchGroup.leave()
                        }
                    }
                case .image(let image): // From resend image message
                    let imageURL = createTempImage(image: image)
                    createImageMessage(imageURL: imageURL, channelId: channelId, caption: caption)
                case .uploadedImage(let imageData): // From send image message from editor
                    createImageMessage(fileId: imageData.fileId, channelId: channelId, caption: caption)
                default:
                    print("failure")
                    dispatchGroup.leave()
                }
            } else { // Case : Other type
                dispatchGroup.leave()
            }
        }
    }
    
    // MARK: - Action (Send message) : Image
    private func createImageMessage(imageURL: URL, channelId: String, caption: String? = nil) {
        let createOptions: AmityImageMessageCreateOptions
        if let caption = caption {
            createOptions = AmityImageMessageCreateOptions(subChannelId: channelId, attachment: .localURL(url: imageURL), caption: caption, fullImage: true)
        } else {
            createOptions = AmityImageMessageCreateOptions(subChannelId: channelId, attachment: .localURL(url: imageURL), fullImage: true)
        }

        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: messageRepository.createImageMessage(options:), parameters: createOptions) { [weak self] message, error in
            guard error == nil, let _ = message else {
                Log.add("[UIKit] Create image message (URL: \(imageURL)) fail with error: \(error?.localizedDescription)")
                self?.deleteCacheImageFile(fileName: imageURL.lastPathComponent)
                self?.dispatchGroup.leave()
                return
            }
            
            Log.add("[UIKit] Create image message (URL: \(imageURL)) success with message Id: \(message?.messageId) | type: \(message?.messageType)")
            // Delete cache if exists
            self?.deleteCacheImageFile(fileName: imageURL.lastPathComponent)
            self?.dispatchGroup.leave()
        }
    }
    
    private func createImageMessage(fileId: String, channelId: String, caption: String? = nil) {
        let createOptions: AmityImageMessageCreateOptions
        if let caption = caption {
            createOptions = AmityImageMessageCreateOptions(subChannelId: channelId, attachment: .fileId(id: fileId), caption: caption, fullImage: true)
        } else {
            createOptions = AmityImageMessageCreateOptions(subChannelId: channelId, attachment: .fileId(id: fileId), fullImage: true)
        }

        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: messageRepository.createImageMessage(options:), parameters: createOptions) { [weak self] message, error in
            guard error == nil, let _ = message else {
                Log.add("[UIKit] Create image message (fileId: \(fileId)) fail with error: \(error?.localizedDescription)")
                self?.dispatchGroup.leave()
                return
            }
            
            Log.add("[UIKit] Create image message (fileId: \(fileId)) success with message Id: \(message?.messageId) | type: \(message?.messageType)")
            self?.dispatchGroup.leave()
        }
    }
    
    private func createTempImage(image: UIImage) -> URL {
        // save image to temp directory and send local url path for uploading
        let imageName = "\(UUID().uuidString).jpg"
        
        // Write image file to temp folder for send message
        let imageUrl = FileManager.default.temporaryDirectory.appendingPathComponent(imageName)
        let data = image.scalePreservingAspectRatio().jpegData(compressionQuality: 1.0)
        try? data?.write(to: imageUrl)
        
        // Cached image file for resend message
        if let imageData = data {
            cacheImageFile(imageData: imageData, fileName: imageName)
        }
        
        return imageUrl
    }
    
    private func cacheImageFile(imageData: Data, fileName: String) {
        AmityFileCache.shared.cacheData(for: .imageDirectory, data: imageData, fileName: fileName, completion: {_ in})
    }
    
    private func deleteCacheImageFile(fileName: String) {
        AmityFileCache.shared.deleteFile(for: .imageDirectory, fileName: fileName)
    }
    
    // MARK: - Action (Send message) : File
    private func sendFileMessage(files: [AmityFile], channelId: String) {
        let operations = files.map { UploadFileMessageOperation(subChannelId: channelId, file: $0, repository: messageRepository) }
        
        // Define serial dependency A <- B <- C <- ... <- Z
        for (left, right) in zip(operations, operations.dropFirst()) {
            right.addDependency(left)
        }

        queue.addOperations(operations, waitUntilFinished: false)
        dispatchGroup.leave()
    }
    
}
