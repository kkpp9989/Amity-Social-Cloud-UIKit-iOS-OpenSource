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
    
    init(subChannelId: String, media: AmityMedia, repository: AmityMessageRepository) {
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
                        Log.add("[UIKit][Message][Image] mediaid: \(strongSelf.media.id) | Can't get image uploading for send/resend message")
                        strongSelf.finish()
                    }
                }
            case .image(let image): // From resend image message (Deprecated)
                let imageURL = strongSelf.createTempImage(image: image)
                strongSelf.createImageMessage(imageURL: imageURL, fileURLString: imageURL.absoluteString)
            case .localURL(let imageURL): // From resend image message
                guard let imageData = try? Data(contentsOf: imageURL),
                      let image = UIImage(data: imageData) else {
                    Log.add("[UIKit][Message][Image] mediaid: \(strongSelf.media.id) | Can't get image from local url for send/resend message")
                    strongSelf.finish()
                    return
                }
                let fileName = imageURL.lastPathComponent
                let imageURL = strongSelf.createTempImage(image: image, fileName: fileName)
                strongSelf.createImageMessage(imageURL: imageURL, fileURLString: imageURL.absoluteString)
            default:
                Log.add("[UIKit][Message][Image] mediaid: \(strongSelf.media.id) | Media state of processing invalid for send/resend message")
                strongSelf.finish()
            }
        }
    }
    
    private func cacheImageFile(imageData: Data, fileName: String) {
        AmityFileCache.shared.cacheData(for: .imageDirectory, data: imageData, fileName: fileName, completion: {_ in})
        Log.add("[UIKit][Message][Image] mediaid: \(media.id) | Cache image success")
    }
    
    private func deleteCacheImageFile(fileName: String) {
        AmityFileCache.shared.deleteFile(for: .imageDirectory, fileName: fileName)
        Log.add("[UIKit][Message][Image] mediaid: \(media.id) | Delete cache image success")
    }
    
    private func createTempImage(image: UIImage, fileName: String? = nil) -> URL {
        // save image to temp directory and send local url path for uploading
        let imageName = fileName ?? "\(UUID().uuidString).jpg"
        
        // Write image file to temp folder for send message
        let imageUrl = FileManager.default.temporaryDirectory.appendingPathComponent(imageName)
        let data = image.scalePreservingAspectRatio().jpegData(compressionQuality: 1.0)
        try? data?.write(to: imageUrl)
        
        Log.add("[UIKit][Message][Image] mediaid: \(media.id) | Create temp image success")
        
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
                Log.add("[UIKit][Message][Image] mediaid: \(self?.media.id) | Create image message (URL: \(imageURL)) fail with error: \(error?.localizedDescription)")
                self?.finish()
                return
            }
            
            // Delete cache if exists
            Log.add("[UIKit][Message][Image] mediaid: \(self?.media.id) | Create image message (URL: \(imageURL)) success with message Id: \(message.messageId) | type: \(message.messageType)")
            self?.deleteCacheImageFile(fileName: imageURL.lastPathComponent)
            self?.finish()
        }
    }
}

