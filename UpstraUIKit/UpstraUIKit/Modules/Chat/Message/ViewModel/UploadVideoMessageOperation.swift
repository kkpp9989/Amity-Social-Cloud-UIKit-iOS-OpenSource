//
//  UploadVideoMessageOperation.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 10/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

class UploadVideoMessageOperation: AsyncOperation {
    
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
            // get local video url for uploading
            self?.media.getLocalURLForUploading { [weak self] url in
                guard let url = url else {
                    self?.media.state = .error
                    self?.finish()
                    return
                }
                
                self?.createVideoMessage(videoURL: url)
            }
        }
    }
    
    private func createVideoMessage(videoURL: URL) {
        let channelId = self.subChannelId
        let createOptions = AmityVideoMessageCreateOptions(subChannelId: channelId, videoFileURL: videoURL)
        
        guard let repository = repository else {
            finish()
            return
        }
        
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: repository.createVideoMessage(options:), parameters: createOptions) { [weak self] message, error in
            guard error == nil, let message = message else {
                Log.add("[UIKit] Create video message fail with error: \(error?.localizedDescription)")
                return
            }
            Log.add("[UIKit] Create video message success with message Id: \(message.messageId)")
            self?.token = repository.getMessage(message.messageId).observe { (liveObject, error) in
                guard error == nil, let message = liveObject.snapshot else {
                    self?.token = nil
                    self?.finish()
                    return
                }
                Log.add("[UIKit] Sync state video message : \(message.syncState)")
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
