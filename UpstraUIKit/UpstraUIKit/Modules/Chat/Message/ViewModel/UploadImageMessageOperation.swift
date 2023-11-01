//
//  UploadImageMessageOperation.swift
//  AmityUIKit
//
//  Created by Nutchaphon Rewik on 17/11/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit
import Photos
import AmitySDK

class UploadImageMessageOperation: AsyncOperation {
    
    private let subChannelId: String
    private let media: AmityMedia
    private weak var repository: AmityMessageRepository?
    
    private var token: AmityNotificationToken?
    
    init(subChannelId: String, media: AmityMedia, repository: AmityMessageRepository, isFromResend: Bool = false) {
        self.subChannelId = subChannelId
        self.media = media
        self.repository = repository
    }
    
    deinit {
        token = nil
    }

    override func main() {
        // Perform actual task on main queue.
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            
            // Separate process from state of media
            switch strongSelf.media.state {
            case .localAsset(_): // From send image message
                self?.media.getImageForUploading { result in
                    switch result {
                    case .success(let image):
                        let imageURL = strongSelf.createTempImage(image: image)
                        strongSelf.createImageMessage(imageURL: imageURL, fileURLString: imageURL.absoluteString)
                    case .failure:
                        strongSelf.finish()
                    }
                }
            case .image(let image): // From resend image message
                let imageURL = strongSelf.createTempImage(image: image)
                strongSelf.createImageMessage(imageURL: imageURL, fileURLString: imageURL.absoluteString)
            default:
                strongSelf.finish()
            }
        }
    }
    
    private func cacheImageFile(imageData: Data, fileName: String) {
        AmityFileCache.shared.cacheData(for: .imageDirectory, data: imageData, fileName: fileName, completion: {_ in})
    }
    
    private func deleteCacheImageFile(fileName: String) {
        AmityFileCache.shared.deleteFile(for: .imageDirectory, fileName: fileName)
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
    
    private func createImageMessage(imageURL: URL, fileURLString: String) {
        let channelId = self.subChannelId
        let createOptions = AmityImageMessageCreateOptions(subChannelId: channelId, attachment: .localURL(url: imageURL), fullImage: true)
        
        guard let repository = repository else {
            finish()
            return
        }
                
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: repository.createImageMessage(options:), parameters: createOptions) { [weak self] message, error in
            guard error == nil, let message = message else {
                Log.add("[UIKit] Create image message (URL: \(imageURL)) fail with error: \(error?.localizedDescription)")
                return
            }
            
            // Delete cache if exists
            self?.deleteCacheImageFile(fileName: imageURL.lastPathComponent)
            
            Log.add("[UIKit] Create image message (URL: \(imageURL)) success with message Id: \(message.messageId) | type: \(message.messageType)")
            self?.token = repository.getMessage(message.messageId).observe { (liveObject, error) in
                guard error == nil, let message = liveObject.snapshot else {
                    self?.token = nil
                    self?.finish()
                    return
                }
                Log.add("[UIKit] Sync state image message (URL: \(imageURL)) : \(message.syncState) | type: \(message.messageType)")
                switch message.syncState {
                case .syncing, .default:
                    // We don't cache local file URL as sdk handles itself
                    break
                case .synced, .error:
                    self?.token = nil
                    self?.finish()
                @unknown default:
                    fatalError()
                }
            }
        }
        
    }
    
}

