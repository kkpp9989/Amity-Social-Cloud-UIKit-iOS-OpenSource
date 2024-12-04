//
//  AmityMessageTextFullEditorScreenViewModel.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 31/1/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import AmitySDK
import UIKit

enum CreateMessageEdtiorError: Error {
    case cannotGetFile
    case cannotGetImage
    case invalidMedia
    case invalidFile
}

extension CreateMessageEdtiorError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .cannotGetFile:
            return NSLocalizedString(
                "Can't get file.",
                comment: "Resource Not Found"
            )
        case .cannotGetImage:
            return NSLocalizedString(
                "Can't get image",
                comment: "Resource Not Found"
            )
        case .invalidMedia:
            return NSLocalizedString(
                "The media type is not valid.",
                comment: "Invalid Media Type"
            )
        case .invalidFile:
            return NSLocalizedString(
                "The file type is not valid.",
                comment: "Invalid File Type"
            )
        }
    }
}

class AmityMessageTextFullEditorScreenViewModel: AmityMessageTextFullEditorScreenViewModelType {
    
    // MARK: - Controller (Message)
    private let messageRepository: AmityMessageRepository = AmityMessageRepository(client: AmityUIKitManagerInternal.shared.client)
    
    // MARK: - Properties
    private var messageObjectToken: AmityNotificationToken?
    
    // MARK: - Delegate
    public weak var delegate: AmityMessageTextFullEditorScreenViewModelDelegate?
    
    // MARK: - Utilities
    private let dispatchGroup: DispatchGroup = DispatchGroup()
    private let queue = OperationQueue()
    
    // MARK: - Datasource
    func loadMessage(for postId: String) {
        // Don't use now
    }
    
    // MARK: - Action (Send message) : Broadcast
    func createMessage(message: AmityBroadcastMessageCreatorModel, channelId: String) {
        AmityEventHandler.shared.showKTBLoading()
        // Requesting Broadcast message each channel
        let broadcastType = message.broadcastType
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
    
    // MARK: - Action (Send message) : Text
    private func sendTextMessage(text: String, channelId: String) {
        let createOptions = AmityTextMessageCreateOptions(subChannelId: channelId, text: text)
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: messageRepository.createTextMessage(options:), parameters: createOptions) { [weak self] message, error in
            if let message = message {
                Log.add(#"[UIKit] Create text message "\#(text)" success with message Id: \#(message.messageId) | type: \#(message.messageType)"#)
                self?.createMessageResponseHandler(forMessage: message, error: nil)
            } else if let error = error {
                Log.add(#"[UIKit] Create text message "\#(text)" fail with error: \#(error.localizedDescription)"#)
                self?.createMessageResponseHandler(forMessage: nil, error: error)
            }
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
                            strongSelf.createMessageResponseHandler(forMessage: nil, error: CreateMessageEdtiorError.cannotGetImage)
                        }
                    }
                case .image(let image): // From resend image message
                    let imageURL = createTempImage(image: image)
                    createImageMessage(imageURL: imageURL, channelId: channelId, caption: caption)
                case .uploadedImage(let imageData): // From send image message from editor
                    createImageMessage(fileId: imageData.fileId, channelId: channelId, caption: caption)
                default:
                    createMessageResponseHandler(forMessage: nil, error: CreateMessageEdtiorError.cannotGetImage)
                }
            } else { // Case : Other type
                createMessageResponseHandler(forMessage: nil, error: CreateMessageEdtiorError.invalidMedia)
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
            if let message = message {
                Log.add("[UIKit] Create image message (URL: \(imageURL)) success with message Id: \(message.messageId) | type: \(message.messageType)")
                self?.createMessageResponseHandler(forMessage: message, error: nil)
            } else if let error = error {
                Log.add("[UIKit] Create image message (URL: \(imageURL)) fail with error: \(error.localizedDescription)")
                self?.createMessageResponseHandler(forMessage: nil, error: error)
            }
            
            // Delete cache if exists
            self?.deleteCacheImageFile(fileName: imageURL.lastPathComponent)
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
            if let message = message {
                Log.add("[UIKit] Create image message (fileId: \(fileId)) success with message Id: \(message.messageId) | type: \(message.messageType)")
                self?.createMessageResponseHandler(forMessage: message, error: nil)
            } else if let error = error {
                Log.add("[UIKit] Create image message (fileId: \(fileId)) fail with error: \(error.localizedDescription)")
                self?.createMessageResponseHandler(forMessage: nil, error: error)
            }
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
        for file in files {
            let state = file.state
            switch state {
            case .local(let document):
                let fileURL = document.fileURL
                cacheFile(fileURL: fileURL)
                createFileMessage(fileURL: fileURL, channelId: channelId)
            case .uploaded(let data), .downloadable(let data):
                let fileId = data.fileId
                createFileMessage(fileId: fileId, channelId: channelId)
            default:
                createMessageResponseHandler(forMessage: nil, error: CreateMessageEdtiorError.cannotGetFile)
            }
        }
    }
    
    private func createFileMessage(fileURL: URL, channelId: String) {
        let createOptions = AmityFileMessageCreateOptions(subChannelId: channelId, attachment: .localURL(url: fileURL))
        
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: messageRepository.createFileMessage(options:), parameters: createOptions) { [weak self] message, error in
            if let message = message {
                Log.add("[UIKit] Create file message (URL: \(fileURL)) success with message Id: \(message.messageId) | type: \(message.messageType)")
                self?.createMessageResponseHandler(forMessage: message, error: nil)
            } else if let error = error {
                Log.add("[UIKit] Create file message (URL: \(fileURL)) fail with error: \(error.localizedDescription)")
                self?.createMessageResponseHandler(forMessage: nil, error: error)
            }
            
            // Delete file to temp file message data if cache its
            self?.deleteCacheFile(fileURL: fileURL)
        }
    }
    
    private func createFileMessage(fileId: String, channelId: String) {
        let createOptions = AmityFileMessageCreateOptions(subChannelId: channelId, attachment: .fileId(id: fileId))
        
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: messageRepository.createFileMessage(options:), parameters: createOptions) { [weak self] message, error in
            if let message = message {
                Log.add("[UIKit] Create file message (fileId: \(fileId)) success with message Id: \(message.messageId) | type: \(message.messageType)")
                self?.createMessageResponseHandler(forMessage: message, error: nil)
            } else if let error = error {
                Log.add("[UIKit] Create file message (fileId: \(fileId)) fail with error: \(error.localizedDescription)")
                self?.createMessageResponseHandler(forMessage: nil, error: error)
            }
        }
    }
    
    private func cacheFile(fileURL: URL) {
        guard let fileData = try? Data(contentsOf: fileURL) else { return }
        AmityFileCache.shared.cacheData(for: .fileDirectory, data: fileData, fileName: fileURL.lastPathComponent, completion: {_ in})
    }
    
    private func deleteCacheFile(fileURL: URL) {
        AmityFileCache.shared.deleteFile(for: .fileDirectory, fileName: fileURL.lastPathComponent)
    }
    
    // MARK: - Response Helpers
    private func createMessageResponseHandler(forMessage message: AmityMessage?, error: Error?) {
        AmityEventHandler.shared.hideKTBLoading()
        delegate?.screenViewModelDidCreateMessage(self, message: message, error: error)
    }
}
