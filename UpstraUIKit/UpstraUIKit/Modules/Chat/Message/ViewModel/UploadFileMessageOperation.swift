//
//  UploadFileMessageOperation.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 11/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

import UIKit
import AmitySDK

class UploadFileMessageOperation: AsyncOperation {
    
    private let subChannelId: String
    private let file: AmityFile
    private weak var repository: AmityMessageRepository?
    
    private var token: AmityNotificationToken?
    
    init(subChannelId: String, file: AmityFile, repository: AmityMessageRepository) {
        self.subChannelId = subChannelId
        self.file = file
        self.repository = repository
    }
    
    deinit {
        token = nil
    }

    override func main() {
        // Perform actual task on main queue.
        DispatchQueue.main.async { [weak self] in
            // get local file url for uploading
            if let fileURL = self?.file.fileURL {
                self?.createFileMessage(fileURL: fileURL)
            } else {
                self?.finish()
            }
        }
    }
    
    private func createFileMessage(fileURL: URL) {
        let channelId = self.subChannelId
        let createOptions = AmityFileMessageCreateOptions(subChannelId: channelId, fileURL: fileURL)
        
        guard let repository = repository else {
            finish()
            return
        }
        
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: repository.createFileMessage(options:), parameters: createOptions) { [weak self] message, error in
            guard error == nil, let message = message else {
                Log.add("[UIKit] Create file message (URL: \(fileURL)) fail with error: \(error?.localizedDescription)")
                return
            }
            Log.add("[UIKit] Create file message (URL: \(fileURL)) success with message Id: \(message.messageId) | type: \(message.messageType)")
            self?.token = repository.getMessage(message.messageId).observe { (liveObject, error) in
                guard error == nil, let message = liveObject.snapshot else {
                    self?.token = nil
                    self?.finish()
                    return
                }
                Log.add("[UIKit] Sync state file (URL: \(fileURL)) message : \(message.syncState) | type: \(message.messageType)")
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
