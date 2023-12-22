//
//  AmityCommentCreateController.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 2/15/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityCommentCreateControllerProtocol {
    func createComment(withReferenceId postId: String, referenceType: AmityCommentReferenceType, parentId: String?, text: String, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?, completion: ((AmityComment?, Error?) -> Void)?)
}

final class AmityCommentCreateController: AmityCommentCreateControllerProtocol {
    
    private let repository = AmityCommentRepository(client: AmityUIKitManagerInternal.shared.client)
    
    func createComment(withReferenceId postId: String, referenceType: AmityCommentReferenceType, parentId: String?, text: String, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?, completion: ((AmityComment?, Error?) -> Void)?) {
        // [URL Preview] Add get URL metadata for cache in comment metadata to show URL preview
        var updatedMetadata = metadata ?? [:]
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
                doCreateComment(withReferenceId: postId, referenceType: referenceType, parentId: parentId, text: text, metadata: updatedMetadata, mentionees: mentionees, completion: completion)
            }
        } else {
            var updatedMetadata = metadata ?? [:]
            updatedMetadata["url_preview_cache_title"] = ""
            updatedMetadata["url_preview_cache_url"] = ""
            updatedMetadata["is_show_url_preview"] = false
            doCreateComment(withReferenceId: postId, referenceType: referenceType, parentId: parentId, text: text, metadata: updatedMetadata, mentionees: mentionees, completion: completion)
        }
    }
    
    func doCreateComment(withReferenceId postId: String, referenceType: AmityCommentReferenceType, parentId: String?, text: String, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?, completion: ((AmityComment?, Error?) -> Void)?) {
//        print("[Comment][Create] text: \(text) | comment metadata: \(metadata)")
        let createOptions: AmityCommentCreateOptions
        if let mentionees = mentionees {
            createOptions = AmityCommentCreateOptions(referenceId: postId, referenceType: referenceType, text: text, parentId: parentId, metadata: metadata, mentioneeBuilder: mentionees)
        } else if let metadata = metadata {
            createOptions = AmityCommentCreateOptions(referenceId: postId, referenceType: referenceType, text: text, parentId: parentId, metadata: metadata, mentioneeBuilder: AmityMentioneesBuilder())
        } else {
            createOptions = AmityCommentCreateOptions(referenceId: postId, referenceType: referenceType, text: text, parentId: parentId)
        }
        
        repository.createComment(with: createOptions) { comment, error in
            completion?(comment, error)
        }
    }
}
