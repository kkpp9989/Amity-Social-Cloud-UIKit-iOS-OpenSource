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
            guard let strongSelf = self else { return }
            
            let state = strongSelf.file.state
            switch state {
            case .local(let document):
                let fileURL = document.fileURL
                self?.cacheFile(fileURL: fileURL)
                self?.createFileMessage(fileURL: fileURL)
            case .uploaded(let data), .downloadable(let data):
                let fileId = data.fileId
                self?.createFileMessage(fileId: fileId)
            default:
                Log.add("[UIKit][Message][file] fileid: \(strongSelf.file.id) | File state of processing invalid for send/resend message")
                self?.finish()
            }
        }
    }
    
    private func cacheFile(fileURL: URL) {
        guard let fileData = try? Data(contentsOf: fileURL) else { return }
        AmityFileCache.shared.cacheData(for: .fileDirectory, data: fileData, fileName: fileURL.lastPathComponent, completion: {_ in})
        Log.add("[UIKit][Message][file] fileid: \(file.id) | Cache file success")
    }
    
    private func deleteCacheFile(fileURL: URL) {
        AmityFileCache.shared.deleteFile(for: .fileDirectory, fileName: fileURL.lastPathComponent)
        Log.add("[UIKit][Message][file] fileid: \(file.id) | Delete cache file success")
    }
    
    private func createFileMessage(fileURL: URL) {
        let channelId = self.subChannelId
        let createOptions = AmityFileMessageCreateOptions(subChannelId: channelId, attachment: .localURL(url: fileURL))
        
        guard let repository = repository else {
            finish()
            return
        }
        
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: repository.createFileMessage(options:), parameters: createOptions) { [weak self] message, error in
            guard error == nil, let message = message else {
                Log.add("[UIKit][Message][File] fileid: \(self?.file.id) | Create file message (URL: \(fileURL)) fail with error: \(error?.localizedDescription)")
                self?.finish()
                return
            }
            
            // Delete file to temp file message data if cache its
            Log.add("[UIKit][Message][File] fileid: \(self?.file.id) | Create file message (URL: \(fileURL)) success with message Id: \(message.messageId) | type: \(message.messageType)")
            self?.deleteCacheFile(fileURL: fileURL)
            self?.finish()
        }
    }
    
    private func createFileMessage(fileId: String) {
        let channelId = self.subChannelId
        let createOptions = AmityFileMessageCreateOptions(subChannelId: channelId, attachment: .fileId(id: fileId))
        
        guard let repository = repository else {
            finish()
            return
        }
        
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: repository.createFileMessage(options:), parameters: createOptions) { [weak self] message, error in
            guard error == nil, let message = message else {
                Log.add("[UIKit][Message][File] fileid: \(self?.file.id) | Create file message (fileId: \(fileId)) fail with error: \(error?.localizedDescription)")
                self?.finish()
                return
            }
            
            Log.add("[UIKit][Message][File] fileid: \(self?.file.id) | Create file message (fileId: \(fileId)) success with message Id: \(message.messageId) | type: \(message.messageType)")
            self?.finish()
        }
    }
}
