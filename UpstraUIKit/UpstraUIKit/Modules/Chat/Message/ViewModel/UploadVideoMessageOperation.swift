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
    private let fileId: String
    private let media: AmityMedia
    private weak var repository: AmityMessageRepository?
    
    private var token: AmityNotificationToken?
    
    init(subChannelId: String, media: AmityMedia, repository: AmityMessageRepository, fileId: String) {
        self.subChannelId = subChannelId
        self.media = media
        self.repository = repository
        self.fileId = fileId
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
                    Log.add("[UIKit][Message][Video] mediaid: \(self?.media.id) | Can't get video from local URL for send/resend message")
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
        let createOptions = AmityVideoMessageCreateOptions(subChannelId: channelId, attachment: .localURL(url: videoURL))
        
        guard let repository = repository else {
            finish()
            return
        }
        
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: repository.createVideoMessage(options:), parameters: createOptions) { [weak self] message, error in
            guard error == nil, let message = message else {
                Log.add("[UIKit][Message][Video] mediaid: \(self?.media.id) | Create video message (URL: \(videoURL)) fail with error: \(error?.localizedDescription)")
                self?.finish()
                return
            }
            
            Log.add("[UIKit][Message][Video] mediaid: \(self?.media.id) | Create video message (URL: \(videoURL)) success with message Id: \(message.messageId) | type: \(message.messageType)")
            self?.finish()
        }
    }
    
    private func createVideoMessage(fileId: String) {
        let channelId = self.subChannelId
        let createOptions = AmityVideoMessageCreateOptions(subChannelId: channelId, attachment: .fileId(id: fileId))
        
        guard let repository = repository else {
            finish()
            return
        }
        
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: repository.createVideoMessage(options:), parameters: createOptions) { [weak self] message, error in
            guard error == nil, let message = message else {
                Log.add("[UIKit][Message][Video] mediaid: \(self?.media.id) | Create video message (fileId: \(fileId)) fail with error: \(error?.localizedDescription)")
                self?.finish()
                return
            }
            
            Log.add("[UIKit][Message][Video] mediaid: \(self?.media.id) | Create video message (fileId: \(fileId)) success with message Id: \(message.messageId) | type: \(message.messageType)")
            self?.finish()
        }
    }
}
