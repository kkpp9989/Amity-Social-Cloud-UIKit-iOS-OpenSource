//
//  AmityPostTextEditorDataSource.swift
//  AmityUIKit
//
//  Created by Nontapat Siengsanor on 26/8/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import AmitySDK

class AmityPostTextEditorScreenViewModel: AmityPostTextEditorScreenViewModelType {
    
    private let postrepository: AmityPostRepository = AmityPostRepository(client: AmityUIKitManagerInternal.shared.client)
    private var postObjectToken: AmityNotificationToken?
    
    public weak var delegate: AmityPostTextEditorScreenViewModelDelegate?
    private let actionTracker = DispatchGroup()
    
    // MARK: - Datasource
    
    func loadPost(for postId: String) {
        postObjectToken = postrepository.getPost(withId: postId).observe { [weak self] post, error in
            guard let strongSelf = self, let post = post.object else { return }
            strongSelf.delegate?.screenViewModelDidLoadPost(strongSelf, post: post)
            // observe once
            strongSelf.postObjectToken?.invalidate()
        }
    }
    
    // MARK: - Action
    func createPost(text: String, medias: [AmityMedia], files: [AmityFile], communityId: String?, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?, location: [String:Any]) {
        AmityEventHandler.shared.showKTBLoading()
        // [URL Preview] Add get URL metadata for cache in post metadata to show URL preview
        if let urlInString = AmityPreviewLinkWizard.shared.detectURLStringWithURLEncoding(text: text), let urlData = URL(string: urlInString) {
            // Get URL metadata
            Task { @MainActor in
                var updatedMetadata = metadata ?? [:]
                if let newURLMetadata = await AmityPreviewLinkWizard.shared.getMetadata(url: urlData) {
                    updatedMetadata["url_preview_cache_title"] = newURLMetadata.title
                    updatedMetadata["url_preview_cache_url"] = urlData.absoluteString
                    updatedMetadata["is_show_url_preview"] = true
                } else {
                    updatedMetadata["url_preview_cache_title"] = ""
                    updatedMetadata["url_preview_cache_url"] = ""
                    updatedMetadata["is_show_url_preview"] = false
                }
                if let updateLocation = location["location"] {
                    updatedMetadata["location"] = updateLocation
                }
                doCreatePost(text: text, medias: medias, files: files, communityId: communityId, metadata: updatedMetadata, mentionees: mentionees)
            }
        } else {
            var updatedMetadata = metadata ?? [:]
            updatedMetadata["url_preview_cache_title"] = ""
            updatedMetadata["url_preview_cache_url"] = ""
            updatedMetadata["is_show_url_preview"] = false
            
            if let updateLocation = location["location"] {
                updatedMetadata["location"] = updateLocation
            }
            doCreatePost(text: text, medias: medias, files: files, communityId: communityId, metadata: updatedMetadata, mentionees: mentionees)
        }
    }
    
    func doCreatePost(text: String, medias: [AmityMedia], files: [AmityFile], communityId: String?, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?) {
//        print("[Post][Create] text: \(text) | post metadata: \(metadata)")
        
        let targetType: AmityPostTargetType = communityId == nil ? .user : .community
        var postBuilder: AmityPostBuilder
        
        let imagesData = getImagesData(from: medias)
        let videosData = getVideosData(from: medias)
        let filesData = getFilesData(from: files)
        
        if !imagesData.isEmpty {
            // Image Post
            Log.add("Creating image post with \(imagesData.count) images")
            Log.add("FileIds: \(imagesData.map{ $0.fileId })")
            
            let imagePostBuilder = AmityImagePostBuilder()
            imagePostBuilder.setText(text)
            imagePostBuilder.setImages(imagesData)
            postBuilder = imagePostBuilder
        } else if !videosData.isEmpty {
            // Video Post
            Log.add("Creating video post with \(videosData.count) images")
            Log.add("FileIds: \(videosData.map{ $0.fileId })")
            
            let videoPostBuilder = AmityVideoPostBuilder()
            videoPostBuilder.setText(text)
            videoPostBuilder.setVideos(videosData)
            postBuilder = videoPostBuilder
        } else if !filesData.isEmpty {
            // File Post
            Log.add("Creating file post with \(filesData.count) files")
            Log.add("FileIds: \(filesData.map{ $0.fileId })")
            
            let fileBuilder = AmityFilePostBuilder()
            fileBuilder.setText(text)
            fileBuilder.setFiles(getFilesData(from: files))
            postBuilder = fileBuilder
        } else {
            // Text Post
            let textPostBuilder = AmityTextPostBuilder()
            textPostBuilder.setText(text)
            postBuilder = textPostBuilder
        }
        
        if let mentionees = mentionees {
            postrepository.createPost(postBuilder, targetId: communityId, targetType: targetType, metadata: metadata, mentionees: mentionees) { [weak self] (post, error) in
                AmityEventHandler.shared.hideKTBLoading()
                self?.createPostResponseHandler(forPost: post, error: error)
            }
        } else if let metadata = metadata {
            postrepository.createPost(postBuilder, targetId: communityId, targetType: targetType, metadata: metadata, mentionees: AmityMentioneesBuilder()) { [weak self] (post, error) in
                AmityEventHandler.shared.hideKTBLoading()
                self?.createPostResponseHandler(forPost: post, error: error)
            }
        } else {
            postrepository.createPost(postBuilder, targetId: communityId, targetType: targetType) { [weak self] (post, error) in
                AmityEventHandler.shared.hideKTBLoading()
                self?.createPostResponseHandler(forPost: post, error: error)
            }
        }
    }
    
    /*
     Rules for editing the post:
     - You can delete file/image from the post.
     - You can delete the whole post along with all images & files
     - You cannot update post type. i.e Text - image post or text - file or image to file
     - You cannot add extra images/files or replace images/files in image/file post
     */
    
    func updatePost(oldPost: AmityPostModel, text: String, medias: [AmityMedia], files: [AmityFile], metadata: [String : Any]?, mentionees: AmityMentioneesBuilder?) {
        AmityEventHandler.shared.showKTBLoading()
        
        // [URL Preview] Add get URL metadata for cache in post metadata to show URL preview
        if let urlInString = AmityPreviewLinkWizard.shared.detectURLStringWithURLEncoding(text: text), let urlData = URL(string: urlInString) {
            // Get URL metadata
            Task { @MainActor in
                var updatedMetadata = metadata ?? [:]
                if let newURLMetadata = await AmityPreviewLinkWizard.shared.getMetadata(url: urlData) {
                    updatedMetadata["url_preview_cache_title"] = newURLMetadata.title
                    updatedMetadata["url_preview_cache_url"] = urlData.absoluteString
                    updatedMetadata["is_show_url_preview"] = true
                } else {
                    updatedMetadata["url_preview_cache_title"] = ""
                    updatedMetadata["url_preview_cache_url"] = ""
                    updatedMetadata["is_show_url_preview"] = false
                }
                doUpdatePost(oldPost: oldPost, text: text, medias: medias, files: files, metadata: updatedMetadata, mentionees: mentionees)
            }
        } else {
            var updatedMetadata = metadata ?? [:]
            updatedMetadata["url_preview_cache_title"] = ""
            updatedMetadata["url_preview_cache_url"] = ""
            updatedMetadata["is_show_url_preview"] = false
            doUpdatePost(oldPost: oldPost, text: text, medias: medias, files: files, metadata: updatedMetadata, mentionees: mentionees)
        }
    }
    
    func doUpdatePost(oldPost: AmityPostModel, text: String, medias: [AmityMedia], files: [AmityFile], metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?) {
//        print("[Post][Update] text: \(text) | post metadata: \(metadata)")
        
        var postBuilder: AmityPostBuilder
        
        let isMediaChanged = oldPost.medias != medias
        let isFileChanged = oldPost.files != files
        
        if oldPost.medias.isEmpty && isMediaChanged {
            // Image Post
            let imagePostBuilder = AmityImagePostBuilder()
            imagePostBuilder.setText(text)
            imagePostBuilder.setImages(getImagesData(from: medias))
            postBuilder = imagePostBuilder
        } else if oldPost.files.isEmpty && isFileChanged {
            // File Post
            let fileBuilder = AmityFilePostBuilder()
            fileBuilder.setText(text)
            fileBuilder.setFiles(getFilesData(from: files))
            postBuilder = fileBuilder
        } else if oldPost.dataTypeInternal == .image && isMediaChanged {
            // Image Post
            let imagePostBuilder = AmityImagePostBuilder()
            imagePostBuilder.setText(text)
            imagePostBuilder.setImages(getImagesData(from: medias))
            postBuilder = imagePostBuilder
        } else if oldPost.dataTypeInternal == .video && isMediaChanged {
            // Video Post
            let videoPostBuilder = AmityVideoPostBuilder()
            videoPostBuilder.setText(text)
            videoPostBuilder.setVideos(getVideosData(from: medias))
            postBuilder = videoPostBuilder
        } else if oldPost.dataTypeInternal == .file && isFileChanged {
            // File Post
            let fileBuilder = AmityFilePostBuilder()
            fileBuilder.setText(text)
            fileBuilder.setFiles(getFilesData(from: files))
            postBuilder = fileBuilder
        } else {
            // Text Post
            let textPostBuilder = AmityTextPostBuilder()
            textPostBuilder.setText(text)
            postBuilder = textPostBuilder
        }
        
        if let mentionees = mentionees {
            postrepository.updatePost(withId: oldPost.postId, builder: postBuilder, metadata: metadata, mentionees: mentionees) { [weak self] (post, error) in
                guard let strongSelf = self else { return }
                AmityEventHandler.shared.hideKTBLoading()
                strongSelf.updatePostResponseHandler(forPost: post, error: error)
            }
        } else if let metadata = metadata {
            postrepository.updatePost(withId: oldPost.postId, builder: postBuilder, metadata: metadata, mentionees: AmityMentioneesBuilder()) { [weak self] (post, error) in
                guard let strongSelf = self else { return }
                AmityEventHandler.shared.hideKTBLoading()
                strongSelf.updatePostResponseHandler(forPost: post, error: error)
            }
        } else {
            postrepository.updatePost(withId: oldPost.postId, builder: postBuilder) { [weak self] (post, error) in
                guard let strongSelf = self else { return }
                AmityEventHandler.shared.hideKTBLoading()
                strongSelf.updatePostResponseHandler(forPost: post, error: error)
            }
        }
    }
    
    // MARK:- Private Helpers
    
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
    
    // MARK:- Response Helpers
    
    private func createPostResponseHandler(forPost post: AmityPost?, error: Error?) {
        Log.add("File Post Created: \(post != nil) Error: \(String(describing: error))")
        delegate?.screenViewModelDidCreatePost(self, post: post, error: error)
        if error == nil {
            NotificationCenter.default.post(name: NSNotification.Name.Post.didCreate, object: post?.postId)
        }
    }
    
    private func updatePostResponseHandler(forPost post: AmityPost?, error: Error?) {
        Log.add("File Post updated: \(post != nil) Error: \(String(describing: error))")
        delegate?.screenViewModelDidUpdatePost(self, error: error)
        if error == nil {
            NotificationCenter.default.post(name: NSNotification.Name.Post.didUpdate, object: nil)
        }
    }
}
