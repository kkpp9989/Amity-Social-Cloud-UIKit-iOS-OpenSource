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
    @IBOutlet var heightDynamicCommentViewConstraint: NSLayoutConstraint!
    
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
    
    func configure(with comment: AmityCommentModel, layout: AmityCommentView.Layout, post: AmityPostModel? = nil, completion: ((_ isHaveURLPreview: Bool, _ cellHeight: CGFloat) -> Void)? = nil) {
        // [Custom for ONE Krungthai] Add properties for for check moderator user in official community for outputing
        self.post = post
        self.comment = comment
        
        // [Custom for ONE Krungthai] Modify function for use post model for check moderator user in official community for outputing
        commentView.configure(with: comment, layout: layout, post: post)
        
        /* [Custom for ONE Krungthai][URL Preview] Add check URL in text for show URL preview or not */
        if let urlString = AmityURLCustomManager.getURLInText(text: comment.text) { // Case : Have URL in text
            if let cachedMetadata = AmityURLPreviewCacheManager.shared.getCachedMetadata(forURL: urlString) { // Case : This url have current data -> Use cached for set display URL preview
                commentView.displayURLPreview(metadata: cachedMetadata)
                let latestHeight = updateCellHeight(layout: layout, isHaveURLPreview: true) // Update cell height here
                completion?(true, latestHeight)
//                print("[Post][URL Preview] Use cache data for show URL Preview | comment: \(comment.text)")
            } else { // Case : This url don't have current data -> Get new URL metadata for set display URL preview
                AmityURLCustomManager.fetchAmityURLMetadata(url: urlString) { metadata in
                    DispatchQueue.main.async {
                        if let urlMetadata: AmityURLMetadata = metadata { // Case : Can get new URL metadata -> set display URL preview
                            AmityURLPreviewCacheManager.shared.cacheMetadata(urlMetadata, forURL: urlString)
                            self.commentView.displayURLPreview(metadata: urlMetadata)
                            let latestHeight = self.updateCellHeight(layout: layout, isHaveURLPreview: true) // Update cell height here
                            completion?(true, latestHeight)
//                            print("[Post][URL Preview] Use new data for show URL Preview | comment: \(comment.text)")
                        } else { // Case : Can get new URL metadata -> hide URL preview
                            self.commentView.hideURLPreview()
                            let latestHeight = self.updateCellHeight(layout: layout, isHaveURLPreview: false) // Update cell height here
                            completion?(false, latestHeight)
//                            print("[Post][URL Preview] Hide URL Preview | comment: \(comment.text)")
                        }
                    }
                }
            }
        } else { // Case : Don't have URL in text
            commentView.hideURLPreview()
            let latestHeight = updateCellHeight(layout: layout, isHaveURLPreview: false) // Update cell height here
            completion?(false, latestHeight)
//            print("[Post][URL Preview] Hide URL Preview | comment: \(comment.text)")
        }
        
        commentView.delegate = self
    }
    
    // Function to update cell height
    private func updateCellHeight(layout: AmityCommentView.Layout, isHaveURLPreview: Bool = false) -> CGFloat {
        // Calculate the new cell height based on the content after URL preview is shown/hidden
        if let comment = self.comment {
            let newHeight = AmityCommentTableViewCell.height(with: comment, layout: layout, boundingWidth: self.contentView.bounds.width, isHaveURLPreview: isHaveURLPreview)
            heightDynamicCommentViewConstraint.constant = newHeight
            return newHeight
        } else {
            return 0.0
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        commentView.prepareForReuse()
    }
    
    open class func height(with comment: AmityCommentModel, layout: AmityCommentView.Layout, boundingWidth: CGFloat, isHaveURLPreview: Bool = false) -> CGFloat {
        AmityCommentView.height(with: comment, layout: layout, boundingWidth: boundingWidth, isHaveURLPreview: isHaveURLPreview)
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
