//
//  AmityPostPreviewCommentWithURLPreviewTableViewCell.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 7/12/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

public final class AmityPostPreviewCommentWithURLPreviewTableViewCell: UITableViewCell, Nibbable, AmityPostPreviewCommentProtocol {
    
    public weak var delegate: AmityPostPreviewCommentDelegate?
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var commentView: AmityCommentViewWithURLPreview!
    @IBOutlet private var separatorView: UIView!
    
    // MARK: - Properties
    public private(set) var post: AmityPostModel?
    public private(set) var comment: AmityCommentModel?
    public private(set) var isExpanded: Bool = false
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    public func display(post: AmityPostModel, comment: AmityCommentModel?, indexPath: IndexPath) {
        self.comment = comment
        self.post = post
        guard let comment = comment else { return }
        let layout = AmityCommentViewWithURLPreview.Layout(
            type: .commentPreview,
            isExpanded: isExpanded,
            shouldShowActions: post.isCommentable,
            shouldLineShow: false
        )
        
        commentView.configure(with: comment, layout: layout, post: post)
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
extension AmityPostPreviewCommentWithURLPreviewTableViewCell: AmityExpandableLabelDelegate {
    public func didTapOnPostIdLink(_ label: AmityExpandableLabel, withPostId postId: String) {
        performAction(action: .tapOnPostIdLink(postId: postId))
    }
    
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
extension AmityPostPreviewCommentWithURLPreviewTableViewCell: AmityCommentViewWithURLPreviewDelegate {
    
    func commentView(_ view: AmityCommentViewWithURLPreview, didTapAction action: AmityCommentViewAction) {
        guard let comment = view.comment else { return }
        switch action {
        case .avatar:
            // Check moderator user in official community for prepare tap action
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
        case .status:
            break
        }
    }
    
}
