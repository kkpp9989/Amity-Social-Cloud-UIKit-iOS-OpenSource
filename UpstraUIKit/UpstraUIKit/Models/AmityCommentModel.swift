//
//  AmityCommentModel.swift
//  AmityUIKit
//
//  Created by Nontapat Siengsanor on 12/10/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import AmitySDK
/**
 Amity Comment model
 */
public struct AmityCommentModel {
    public let id: String
    public let displayName: String
    public let fileURL: String
    public let text: String
    public let isDeleted: Bool
    public let isEdited: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public let childrenNumber: Int
    public let childrenComment: [AmityCommentModel]
    public let parentId: String?
    public let userId: String
    public let isAuthorGlobalBanned: Bool
    public let myReactions: [String]
    public let metadata: [String: Any]?
    public let mentionees: [AmityMentionees]?
    public let reactions: [String: Int]
    public var isModerator: Bool = false
    public let syncState: AmitySyncState
    // Due to AmityChat 4.0.0 requires comment object for editing and deleting
    // So, this is a workaroud for passing the original object.
    public let comment: AmityComment
    
    public init(comment: AmityComment) {
        id = comment.commentId
        displayName = comment.user?.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString
        fileURL = comment.user?.getAvatarInfo()?.fileURL ?? ""
        text = comment.data?["text"] as? String ?? ""
        isDeleted = comment.isDeleted
        isEdited = comment.isEdited
        createdAt = comment.createdAt
        updatedAt = comment.updatedAt
        childrenNumber = Int(comment.childrenNumber)
        parentId = comment.parentId
        userId = comment.userId
        myReactions = comment.myReactions
        childrenComment = comment.childrenComments.map { AmityCommentModel(comment: $0) }
        self.comment = comment
        isAuthorGlobalBanned = comment.user?.isGlobalBanned ?? false
        metadata = comment.metadata
        mentionees = comment.mentionees
        reactions = comment.reactions as? [String: Int] ?? [:]
        syncState = comment.syncState
        switch comment.target {
        case .community(_, let communityMember):
            if let communityMember {
                isModerator = communityMember.hasModeratorRole
            }
        default:
            break
        }
    }
    
    public var isChildrenExisted: Bool {
        return comment.childrenNumber > 0
    }
    
    public var reactionsCount: Int {
        return Int(comment.reactionsCount)
    }
    
    public var isLiked: Bool {
        return myReactions.contains("like")
    }
    
    public var isOwner: Bool {
        return userId == AmityUIKitManagerInternal.shared.client.currentUserId
    }
    
    public var isParent: Bool {
        return parentId == nil
    }
    
}
