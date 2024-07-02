//
//  AmityCommentWithURLPreviewTableViewCell.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 21/12/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

protocol AmityCommentWithURLPreviewTableViewCellDelegate: AnyObject {
    func commentCellDidTapReadMore(_ cell: AmityCommentWithURLPreviewTableViewCell)
    func commentCellDidTapLike(_ cell: AmityCommentWithURLPreviewTableViewCell)
    func commentCellDidTapReply(_ cell: AmityCommentWithURLPreviewTableViewCell)
    func commentCellDidTapOption(_ cell: AmityCommentWithURLPreviewTableViewCell)
    func commentCellDidTapAvatar(_ cell: AmityCommentWithURLPreviewTableViewCell, userId: String, communityId: String?)
    func commentCellDidTapReactionDetails(_ cell: AmityCommentWithURLPreviewTableViewCell)
    func commentCellDidTapCommentImage(_ cell: AmityCommentWithURLPreviewTableViewCell, imageView: UIImageView, fileURL: String?)
}

class AmityCommentWithURLPreviewTableViewCell: UITableViewCell, Nibbable {

    @IBOutlet private var commentView: AmityCommentViewWithURLPreview!
    
    public private(set) var post: AmityPostModel?
    public private(set) var comment: AmityCommentModel?
    public private(set) var indexPath: IndexPath?
    
    weak var actionDelegate: AmityCommentWithURLPreviewTableViewCellDelegate?
    
    var labelDelegate: AmityExpandableLabelDelegate? {
        get {
            return commentView.contentLabel.delegate
        }
        set {
            commentView.contentLabel.delegate = newValue
        }
    }
    
    func configure(with comment: AmityCommentModel, layout: AmityCommentViewWithURLPreview.Layout, indexPath: IndexPath, post: AmityPostModel? = nil) {
        self.post = post
        self.comment = comment
        self.indexPath = indexPath
        
        commentView.configure(with: comment, layout: layout, post: post)
        commentView.delegate = self
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        commentView.prepareForReuse()
    }
    
    open class func height(with comment: AmityCommentModel, layout: AmityCommentView.Layout, boundingWidth: CGFloat) -> CGFloat {
        AmityCommentView.height(with: comment, layout: layout, boundingWidth: boundingWidth)
    }
}

extension AmityCommentWithURLPreviewTableViewCell: AmityCommentViewWithURLPreviewDelegate {
    
    func commentView(_ view: AmityCommentViewWithURLPreview, didTapAction action: AmityCommentViewAction) {
        switch action {
        case .avatar:
            // Check moderator user in official community for prepare tap displayname or avatar action
            if let currentPost = post, view.isModeratorUserInOfficialCommunity && view.isOfficialCommunity  { // Case : Post is from official community and owner is moderator
                actionDelegate?.commentCellDidTapAvatar(self, userId: commentView.comment?.userId ?? "", communityId: currentPost.targetCommunity?.communityId)
            } else { // Case : Post isn't from official community or owner isn'y moderator
                actionDelegate?.commentCellDidTapAvatar(self, userId: commentView.comment?.userId ?? "", communityId: nil)
            }
        case .like:
            actionDelegate?.commentCellDidTapLike(self)
        case .option:
            actionDelegate?.commentCellDidTapOption(self)
        case .reply:
            actionDelegate?.commentCellDidTapReply(self)
        case .viewReply:
            actionDelegate?.commentCellDidTapReply(self)
        case .reactionDetails:
            actionDelegate?.commentCellDidTapReactionDetails(self)
        case .status:
            break
        case .commentImage(let imageView, let fileURL):
            actionDelegate?.commentCellDidTapCommentImage(self, imageView: imageView, fileURL: fileURL)
        }
    }
    
}
