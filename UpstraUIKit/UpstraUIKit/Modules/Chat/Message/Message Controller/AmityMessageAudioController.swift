//
//  AmityMessageAudioController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 2/12/2563 BE.
//  Copyright © 2563 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK
import Foundation
import AVFAudio

// Manage audio message
final class AmityMessageAudioController {
    
    private let subChannelId: String
    private weak var repository: AmityMessageRepository?
    
    private var token: AmityNotificationToken?
    private var message: AmityObject<AmityMessage>?
    
    init(subChannelId: String, repository: AmityMessageRepository?) {
        self.subChannelId = subChannelId
        self.repository = repository
    }
    
    // Send message
    func create(completion: @escaping () -> Void) {
        guard let audioURL = AmityAudioRecorder.shared.getAudioFileURL(),
              let tempAudioURL = cacheAudioFile(at: audioURL) else {
            Log.add("Audio file not found")
            return
        }
        
        createAudioMessage(from: tempAudioURL, completion: completion)
    }
    
    // Resend message
    func create(tempAudioURL: URL, completion: @escaping () -> Void) {
        createAudioMessage(from: tempAudioURL, completion: completion)
    }
    
    private func createAudioMessage(from audioURL: URL, completion: @escaping () -> Void) {
        guard let repository = repository else {
            return
        }
        
        var metaData:[String: Any] = [:]
        do
        {
            let avAudioPlayer = try AVAudioPlayer (contentsOf:audioURL)
            let duration = avAudioPlayer.duration
            let ms = Double(duration * 1000)
            metaData = ["duration": ms]
        }
        catch{
            metaData = ["duration": 0]
        }

        let createOptions = AmityAudioMessageCreateOptions(subChannelId: subChannelId, attachment: .localURL(url: audioURL), metadata: metaData)
        
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: repository.createAudioMessage(options:), parameters: createOptions) { message, error in
            guard error == nil, let message = message else {
                return
            }
            self.token = repository.getMessage(message.messageId).observe { [weak self] (collection, error) in
                guard error == nil, let message = collection.snapshot else {
                    self?.token = nil
                    return
                }
                let currentFileName = audioURL.lastPathComponent
                self?.deleteCacheAudioFile(fileName: currentFileName)
                completion()
            }
        }
    }
    
    private func cacheAudioFile(at fileURL: URL) -> URL? {
        // Generate filename with timestamp
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let tempFileName = "amity-uikit-recording_\(timestamp)"
        
        // Change current recording file to temp file by rename file
        AmityAudioRecorder.shared.updateFilename(to: tempFileName)
        
        // Return temp audio URL
        let tempAudioURL = AmityAudioRecorder.shared.getAudioFileURL(fileName: tempFileName + ".m4a")
        return tempAudioURL
    }
    
    private func deleteCacheAudioFile(fileName: String) {
        AmityFileCache.shared.deleteFile(for: .audioDirectory, fileName: fileName)
    }
}

