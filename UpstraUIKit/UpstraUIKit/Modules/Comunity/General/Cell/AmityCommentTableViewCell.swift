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
    public private(set) var indexPath: IndexPath?
    
    weak var actionDelegate: AmityCommentTableViewCellDelegate?
    
    var labelDelegate: AmityExpandableLabelDelegate? {
        get {
            return commentView.contentLabel.delegate
        }
        set {
            commentView.contentLabel.delegate = newValue
        }
    }
    
    func configure(with comment: AmityCommentModel, layout: AmityCommentView.Layout, indexPath: IndexPath, post: AmityPostModel? = nil) {
        // [Custom for ONE Krungthai] Add properties for for check moderator user in official community for outputing
        self.post = post
        self.comment = comment
        self.indexPath = indexPath
        
        // [Custom for ONE Krungthai] Modify function for use post model for check moderator user in official community for outputing
        commentView.configure(with: comment, layout: layout, post: post)
        
//        print("[Comment][Get] text: \(comment.text) | comment metadata: \(comment.metadata)")
        /* [Custom for ONE Krungthai][URL Preview] Add check URL in text for show URL preview or not */
        if let title = comment.metadata?["url_preview_cache_title"] as? String, title != "",
           let fullURLString = comment.metadata?["url_preview_cache_url"] as? String, fullURLString != "",
           let isShowURLPreview = comment.metadata?["is_show_url_preview"] as? Bool, isShowURLPreview,
           let urlData = URL(string: fullURLString), let domainURL = urlData.host?.replacingOccurrences(of: "www.", with: ""),
           let urlInText = AmityURLCustomManager.Utilities.getURLInText(text: comment.text), urlInText == fullURLString { // Case : Display URL preview
            
            if let cachedMetadata = AmityURLPreviewCacheManager.shared.getCachedMetadata(forURL: fullURLString) { // Case: [Display URL preview] Have URL metadata in local cache -> Display URL preview
                commentView.displayURLPreview(metadata: cachedMetadata, isLoadingImagePreview: false)
            } else { // Case: [Display URL preview] Don't Have URL metadata in local cache -> Set new url metadata cache in local from post metadata and display URL preview and waiting load image preview
                // Display URL Preview (without image preview)
                let urlMetadata = AmityURLMetadata(title: title, domainURL: domainURL, fullURL: fullURLString, urlData: urlData, imagePreview: nil)
                commentView.displayURLPreview(metadata: urlMetadata, isLoadingImagePreview: true)
                
                // Get URL metadata fot image preview
                AmityURLCustomManager.Metadata.fetchAmityURLMetadata(url: fullURLString) { [self] metadata in
                    DispatchQueue.main.async {
                        // Update image preview to current URL metadata cache
                        var currentURLMetadata: AmityURLMetadata = AmityURLMetadata(title: title, domainURL: domainURL, fullURL: fullURLString, urlData: urlData)
                        if let newURLMetadata: AmityURLMetadata = metadata {
                            currentURLMetadata = AmityURLMetadata(title: title, domainURL: domainURL, fullURL: fullURLString, urlData: urlData, imagePreview: newURLMetadata.imagePreview)
                        } else {
                            currentURLMetadata = AmityURLMetadata(title: title, domainURL: domainURL, fullURL: fullURLString, urlData: urlData)
                        }
                        
                        AmityURLPreviewCacheManager.shared.cacheMetadata(currentURLMetadata, forURL: fullURLString)
                        
                        // Display URL Preview (with image preview)
                        self.commentView.displayURLPreview(metadata: currentURLMetadata, isLoadingImagePreview: false)
                    }
                }
            }
        } else { // Case : Hide URL preview
            commentView.hideURLPreview()
        }
        
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
