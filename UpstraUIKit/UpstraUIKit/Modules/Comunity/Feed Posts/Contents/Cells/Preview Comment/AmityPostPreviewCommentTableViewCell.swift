//
//  AmityPostPreviewCommentTableViewCell.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 2/9/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit

public final class AmityPostPreviewCommentTableViewCell: UITableViewCell, Nibbable, AmityPostPreviewCommentProtocol {
    
    public weak var delegate: AmityPostPreviewCommentDelegate?
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var commentView: AmityCommentView!
    @IBOutlet private var separatorView: UIView!
    
    // MARK: - Properties
    public private(set) var post: AmityPostModel?
    public private(set) var comment: AmityCommentModel?
    public private(set) var isExpanded: Bool = false
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    public func display(post: AmityPostModel, comment: AmityCommentModel?, indexPath: IndexPath, completion: ((_ isMustToReloadCell: Bool, _ indexPath: IndexPath) -> Void)?) {
        self.comment = comment
        self.post = post
        guard let comment = comment else { return }
        let layout = AmityCommentView.Layout(
            type: .commentPreview,
            isExpanded: isExpanded,
            shouldShowActions: post.isCommentable,
            shouldLineShow: false
        )
        
        // [Custom for ONE Krungthai] Modify function for use post model for check moderator user in official community for outputing
        commentView.configure(with: comment, layout: layout, post: post)
        
        /* [Custom for ONE Krungthai][URL Preview] Add check URL in text for show URL preview or not */
        if let urlString = AmityURLCustomManager.Utilities.getURLInText(text: comment.text) { // Case : Have URL in text
            if let cachedMetadata = AmityURLPreviewCacheManager.shared.getCachedMetadata(forURL: urlString) { // Case : This url have current data -> Use cached for set display URL preview
                // Display URL Preview from cache URL metadata
                commentView.displayURLPreview(metadata: cachedMetadata)
                // Handle cell after display URL Preview
                completion?(false, indexPath)
            } else { // Case : This url don't have current data -> Get new URL metadata for set display URL preview
                // Get new URL metadata
                AmityURLCustomManager.Metadata.fetchAmityURLMetadata(url: urlString) { metadata in
                    DispatchQueue.main.async {
                        if let urlMetadata: AmityURLMetadata = metadata { // Case : Can get new URL metadata -> set display URL preview
                            // Save new URL metadata to cache
                            AmityURLPreviewCacheManager.shared.cacheMetadata(urlMetadata, forURL: urlString)
                            // Display URL Preview from new URL metadata
                            self.commentView.displayURLPreview(metadata: urlMetadata)
                            // Handle cell after display URL Preview
                            completion?(true, indexPath)
                        } else { // Case : Can get new URL metadata -> hide URL preview
                            // Hide URL Preview
                            self.commentView.hideURLPreview()
                            // Handle cell after Hide URL Preview
                            if indexPath.section <= 1 { // Case : indexPath section is 0-1 because must to reload row for fix cell in these section show other URL preview
                                completion?(true, indexPath)
                            } else { // Case : indexPath is more than 1 -> don't reload row
                                completion?(false, indexPath)
                            }
                        }
                    }
                }
            }
        } else { // Case : Don't have URL in text
            // Hide URL Preview
            commentView.hideURLPreview()
            // Handle cell after Hide URL Preview
            if indexPath.section <= 1 { // Case : indexPath section is 0-1 because must to reload row for fix cell in these section show other URL preview
                completion?(true, indexPath)
            } else { // Case : indexPath is more than 1 -> don't reload row
                completion?(false, indexPath)
            }
        }
        print("[Post] comment: \(comment.text) | indexPath: \(indexPath)")
        
        commentView.delegate = self
        commentView.contentLabel.delegate = self
    }
    
    func setIsExpanded(_ isExpanded: Bool) {
        self.isExpanded = isExpanded
    }

    private func setupView() {
        selectionStyle = .none
        backgroundColor = AmityColorSet.backgroundColor
        contentView.backgroundColor = AmityColorSet.backgroundColor
        separatorView.backgroundColor = AmityColorSet.secondary.blend(.shade4)
        commentView.backgroundColor = AmityColorSet.backgroundColor
    }
    
    // MARK: - Perform Action
    
    func performAction(action: AmityPostPreviewCommentAction) {
        delegate?.didPerformAction(self, action: action)
    }
    
}

// MARK: AmityExpandableLabelDelegate
extension AmityPostPreviewCommentTableViewCell: AmityExpandableLabelDelegate {
    public func didTapOnHashtag(_ label: AmityExpandableLabel, withKeyword keyword: String, count: Int) {
        performAction(action: .tapOnHashtag(keyword: keyword, count: count))
    }
    
    public func willExpandLabel(_ label: AmityExpandableLabel) {
        performAction(action: .willExpandExpandableLabel(label: label))
    }
    
    public func didExpandLabel(_ label: AmityExpandableLabel) {
        performAction(action: .didExpandExpandableLabel(label: label))
    }
    
    public func willCollapseLabel(_ label: AmityExpandableLabel) {
        performAction(action: .willCollapseExpandableLabel(label: label))
    }
    
    public func didCollapseLabel(_ label: AmityExpandableLabel) {
        performAction(action: .didCollapseExpandableLabel(label: label))
    }
    
    public func expandableLabeldidTap(_ label: AmityExpandableLabel) {
        performAction(action: .tapExpandableLabel(label: label))
    }
    
    public func didTapOnMention(_ label: AmityExpandableLabel, withUserId userId: String) {
        performAction(action: .tapOnMention(userId: userId))
    }
}

// MARK: AmityCommentViewDelegate
extension AmityPostPreviewCommentTableViewCell: AmityCommentViewDelegate {
    
    func commentView(_ view: AmityCommentView, didTapAction action: AmityCommentViewAction) {
        guard let comment = view.comment else { return }
        switch action {
        case .avatar:
            // [Custom for ONE Krungthai] Add check moderator user in official community for prepare tap action
            if view.isModeratorUserInOfficialCommunity && view.isOfficialCommunity { // Case : Post is from official community and owner is moderator
                if let currentPost = post, view.shouldDidTapAction { // Post must to output from newsfeed only
                    performAction(action: .tapCommunityName(post: currentPost)) // Send post model for get community model
                }
            } else { // Case : Post isn't from official community or owner isn't moderator
                performAction(action: .tapAvatar(comment: comment))
            }
        case .like:
            performAction(action: .tapLike(comment: comment))
        case .option:
            performAction(action: .tapOption(comment: comment))
        case .reply, .viewReply:
            performAction(action: .tapReply(comment: comment))
        case .reactionDetails:
            performAction(action: .tapOnReactionDetail)
        }
    }
    
}
