//
//  AmityMessageTextFullEditorScreenViewModel.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 31/1/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import AmitySDK

class AmityMessageTextFullEditorScreenViewModel: AmityMessageTextFullEditorScreenViewModelType {
    
    private let messageRepository: AmityMessageRepository = AmityMessageRepository(client: AmityUIKitManagerInternal.shared.client)
    private var messageObjectToken: AmityNotificationToken?
    
    public weak var delegate: AmityMessageTextFullEditorScreenViewModelDelegate?
    private let actionTracker = DispatchGroup()
    
    // MARK: - Datasource
    func loadMessage(for postId: String) {
        // Don't use now
    }
    
    // MARK: - Action
    func createMessage(text: String, medias: [AmityMedia], files: [AmityFile], channelId: String?, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?) {
        AmityEventHandler.shared.showKTBLoading()
        // Any process
        // doCreateMessage()
    }
    
    private func doCreateMessage(text: String, medias: [AmityMedia], files: [AmityFile], channelId: String?, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?) {
        // create message by SDK
    }
    
    func updateMessage(oldMessage: AmityMessageModel, text: String, medias: [AmityMedia], files: [AmityFile], metadata: [String : Any]?, mentionees: AmityMentioneesBuilder?) {
       // Don't use now
    }
    
    private func doUpdateMessage(oldMessage: AmityMessageModel, text: String, medias: [AmityMedia], files: [AmityFile], metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?) {
        // Don't use now
    }
    
    // MARK: - Private Helpers
    private func getImagesData(from medias: [AmityMedia]) -> [AmityImageData] {
        var imagesData: [AmityImageData] = []
        for media in medias {
            switch media.state {
            case .uploadedImage(let imageData), .downloadableImage(let imageData, _):
                imagesData.append(imageData)
            default:
                continue
            }
        }
        return imagesData
    }
    
    private func getVideosData(from medias: [AmityMedia]) -> [AmityVideoData] {
        var videosData: [AmityVideoData] = []
        for media in medias {
            switch media.state {
            case .uploadedVideo(let videoData), .downloadableVideo(let videoData, _):
                videosData.append(videoData)
            default:
                continue
            }
        }
        return videosData
    }
    
    private func getFilesData(from files: [AmityFile]) -> [AmityFileData] {
        var filesData: [AmityFileData] = []
        for file in files {
            switch file.state {
            case .downloadable(fileData: let fileData), .uploaded(data: let fileData):
                filesData.append(fileData)
            default:
                continue
            }
        }
        return filesData
    }
    
    // MARK: - Response Helpers
    private func createMessageResponseHandler(forMessage message: AmityMessage?, error: Error?) {
        Log.add("File Message Created: \(message != nil) Error: \(String(describing: error))")
        delegate?.screenViewModelDidCreateMessage(self, message: message, error: error)
        if error == nil {
            NotificationCenter.default.post(name: NSNotification.Name.Message.didCreate, object: message?.messageId)
        }
    }
    
    private func updateMessageResponseHandler(forMessage message: AmityMessage?, error: Error?) {
        Log.add("File Message updated: \(message != nil) Error: \(String(describing: error))")
        delegate?.screenViewModelDidUpdateMessage(self, error: error)
        if error == nil {
            NotificationCenter.default.post(name: NSNotification.Name.Message.didUpdate, object: nil)
        }
    }
}
