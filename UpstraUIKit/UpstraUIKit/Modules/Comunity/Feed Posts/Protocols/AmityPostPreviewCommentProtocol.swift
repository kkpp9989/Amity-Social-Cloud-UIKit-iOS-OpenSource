//
//  AmityPostPreviewCommentProtocol.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 2/10/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit

public protocol AmityPostPreviewCommentProtocol: UITableViewCell, AmityCellIdentifiable {
    var delegate: AmityPostPreviewCommentDelegate? { get set }
    var post: AmityPostModel? { get }
    func display(post: AmityPostModel, comment: AmityCommentModel?, indexPath: IndexPath)
}

public protocol AmityPostPreviewCommentDelegate: AnyObject {
    func didPerformAction(_ cell: AmityPostPreviewCommentProtocol, action: AmityPostPreviewCommentAction)
}

public enum AmityPostPreviewCommentAction {
    case tapAvatar(comment: AmityCommentModel)
    case tapLike(comment: AmityCommentModel)
    case tapOption(comment: AmityCommentModel)
    case tapReply(comment: AmityCommentModel)
    case tapCommunityName(post: AmityPostModel) // [Custom for ONE Krungthai] Add tap to community for moderator user in official community action
    case tapExpandableLabel(label: AmityExpandableLabel)
    case willExpandExpandableLabel(label: AmityExpandableLabel)
    case didExpandExpandableLabel(label: AmityExpandableLabel)
    case willCollapseExpandableLabel(label: AmityExpandableLabel)
    case didCollapseExpandableLabel(label: AmityExpandableLabel)
    case tapOnMention(userId: String)
    case tapOnReactionDetail
    case tapOnHashtag(keyword: String, count: Int)
    case tapOnPostIdLink(postId: String)
}
