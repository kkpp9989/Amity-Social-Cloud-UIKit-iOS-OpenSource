//
//  AmityCommentEditorController.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 2/13/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityCommentEditorControllerProtocol {
    func delete(withCommentId commentId: String, completion: AmityRequestCompletion?)
    func edit(withComment comment: AmityCommentModel, text: String, metadata: [String : Any]?, mentionees: AmityMentioneesBuilder?, completion: AmityRequestCompletion?)
}

final class AmityCommentEditorController: AmityCommentEditorControllerProtocol {
    
    private var editor: AmityCommentEditor?
    private var commentRepository: AmityCommentRepository?
    func delete(withCommentId commentId: String, completion: AmityRequestCompletion?) {
        commentRepository = AmityCommentRepository(client: AmityUIKitManagerInternal.shared.client)
        commentRepository?.deleteComment(withId: commentId, hardDelete: false, completion: completion)
    }
        
    func edit(withComment comment: AmityCommentModel, text: String, metadata: [String : Any]?, mentionees: AmityMentioneesBuilder?, completion: AmityRequestCompletion?) {
        commentRepository = AmityCommentRepository(client: AmityUIKitManagerInternal.shared.client)
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
                doEdit(withComment: comment, text: text, metadata: updatedMetadata, mentionees: mentionees, completion: completion)
            }
        } else {
            var updatedMetadata = metadata ?? [:]
            updatedMetadata["url_preview_cache_title"] = ""
            updatedMetadata["url_preview_cache_url"] = ""
            updatedMetadata["is_show_url_preview"] = false
            doEdit(withComment: comment, text: text, metadata: updatedMetadata, mentionees: mentionees, completion: completion)
        }
    }
    
    private func doEdit(withComment comment: AmityCommentModel, text: String, metadata: [String : Any]?, mentionees: AmityMentioneesBuilder?, completion: AmityRequestCompletion?) {
//        print("[Comment][Update] text: \(text) | comment metadata: \(metadata)")
        let options = AmityCommentUpdateOptions(text: text, metadata: metadata, mentioneesBuilder: mentionees)
        
        // Map completion to AmityCommentRequestCompletion
        let mappedCompletion: (AmityComment?, Error?) -> Void = { comment, error in
            if let error {
                completion?(false, error)
            } else if comment != nil {
                completion?(true, nil)
            }
        }
        
        commentRepository?.updateComment(withId: comment.id, options: options, completion: mappedCompletion)
    }
}
