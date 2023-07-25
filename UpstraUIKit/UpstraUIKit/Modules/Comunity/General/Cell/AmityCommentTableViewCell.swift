//
//  AmityCommentTableViewCell.swift
//  AmityUIKit
//
//  Created by Nontapat Siengsanor on 14/8/2563 BE.
//  Copyright © 2563 Amity Communication. All rights reserved.
//

import UIKit

protocol AmityCommentTableViewCellDelegate: AnyObject {
    func commentCellDidTapReadMore(_ cell: AmityCommentTableViewCell)
    func commentCellDidTapLike(_ cell: AmityCommentTableViewCell)
    func commentCellDidTapReply(_ cell: AmityCommentTableViewCell)
    func commentCellDidTapOption(_ cell: AmityCommentTableViewCell)
    func commentCellDidTapAvatar(_ cell: AmityCommentTableViewCell, userId: String, communityId: String?) // [Custom for ONE Krungthai] Modify delegate function for open community for moderator user in official community action
    func commentCellDidTapReactionDetails(_ cell: AmityCommentTableViewCell)
}

class AmityCommentTableViewCell: UITableViewCell, Nibbable {

    @IBOutlet private var commentView: AmityCommentView!
    
    // [Custom for ONE Krungthai] Add properties for for check moderator user in official community for outputing
    public private(set) var post: AmityPostModel?
    public private(set) var comment: AmityCommentModel?
    
    weak var actionDelegate: AmityCommentTableViewCellDelegate?
    
    var labelDelegate: AmityExpandableLabelDelegate? {
        get {
            return commentView.contentLabel.delegate
        }
        set {
            commentView.contentLabel.delegate = newValue
        }
    }
    
    func configure(with comment: AmityCommentModel, layout: AmityCommentView.Layout, post: AmityPostModel? = nil) {
        // [Custom for ONE Krungthai] Add properties for for check moderator user in official community for outputing
        self.post = post
        self.comment = comment
        
        // [Custom for ONE Krungthai] Modify function for use post model for check moderator user in official community for outputing
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

extension AmityCommentTableViewCell: AmityCommentViewDelegate {
    
    func commentView(_ view: AmityCommentView, didTapAction action: AmityCommentViewAction) {
        switch action {
        case .avatar:
            // [Custom for ONE Krungthai] Add check moderator user in official community for prepare tap displayname or avatar action
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
        }
    }
    
}
