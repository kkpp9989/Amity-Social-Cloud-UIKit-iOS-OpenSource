//
//  AmityPostFooterTableViewCell.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 2/5/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit

/// `AmityPostFooterTableViewCell` for providing a footer of `Post`
public final class AmityPostFooterTableViewCell: UITableViewCell, Nibbable, AmityCellIdentifiable, AmityPostFooterProtocol {
    
    public weak var delegate: AmityPostFooterDelegate?

    // MARK: - IBOutlet Properties
    @IBOutlet private var topContainerView: UIView!
    @IBOutlet private var likeLabel: UILabel!
    @IBOutlet private var commentLabel: UILabel!
    @IBOutlet private var shareLabel: UILabel!
    @IBOutlet private var actionStackView: UIStackView!
    @IBOutlet private var likeButton: AmityButton!
    @IBOutlet private var commentButton: AmityButton!
    @IBOutlet private var shareButton: AmityButton!
    @IBOutlet private var separatorView: [UIView]!
    @IBOutlet private var likeLabelIcon: UIImageView!
    @IBOutlet private var warningLabel: UILabel!
    @IBOutlet private var likeDetailButton: UIButton!
    
    @IBOutlet private var twoReactionsView: UIView!
    @IBOutlet private var twoReactionsFirstIcon: UIImageView!
    @IBOutlet private var twoReactionsSecondIcon: UIImageView!
    
    @IBOutlet private var threeReactionsView: UIView!
    @IBOutlet private var threeReactionsFirstIcon: UIImageView!
    @IBOutlet private var threeReactionsSecondIcon: UIImageView!
    @IBOutlet private var threeReactionsThirdIcon: UIImageView!
    
    // MARK: - Properties
    private(set) public var post: AmityPostModel?
    public var indexPath: IndexPath?
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
        setupWarningLabel()
        setupLikeButton()
        setupCommentButton()
        setupShareButton()
    }
    
    public func display(post: AmityPostModel) {
        self.post = post
        
        if let reactionType = post.reacted {
            setLikedButton(reactionType: reactionType)
            likeButton.isSelected = true
        } else {
            likeButton.isSelected = false
        }
        
        likeLabel.isHidden = post.reactionsCount == 0
//        likeLabelIcon.isHidden = post.reactionsCount == 0
        
        likeLabelIcon.isHidden = true
        twoReactionsView.isHidden = true
        threeReactionsView.isHidden = true
        setReactions(reactions: post.reactions)
        
        likeDetailButton.isEnabled = post.reactionsCount != 0
//        let reactionsPrefix = post.reactionsCount == 1 ? AmityLocalizedStringSet.Unit.likeSingular.localizedString : AmityLocalizedStringSet.Unit.likePlural.localizedString
//        likeLabel.text = String.localizedStringWithFormat(reactionsPrefix,
//                                                          post.reactionsCount.formatUsingAbbrevation())
        likeLabel.text = post.reactionsCount.formatUsingAbbrevation()
        commentLabel.isHidden = post.allCommentCount == 0
        let commentPrefix = post.allCommentCount == 1 ? AmityLocalizedStringSet.Unit.commentSingular.localizedString : AmityLocalizedStringSet.Unit.commentPlural.localizedString
        commentLabel.text = String.localizedStringWithFormat(commentPrefix,
                                                             post.allCommentCount.formatUsingAbbrevation())
        
        let isReactionExisted = post.reactionsCount == 0 && post.allCommentCount == 0
        actionStackView.isHidden = !post.isCommentable
        warningLabel.isHidden = post.isCommentable
        topContainerView.isHidden = isReactionExisted
        
        // [Custom for ONE Krungthai] Disable default setting share button for ONE Krungthai
//        shareButton.isHidden = !AmityPostSharePermission.canSharePost(post: post)
//        shareLabel.isHidden = post.sharedCount == 0
//        let sharePrefix = post.sharedCount > 1 ? AmityLocalizedStringSet.Unit.sharesPlural.localizedString :
//            AmityLocalizedStringSet.Unit.sharesSingular.localizedString
//        shareLabel.text = String.localizedStringWithFormat(sharePrefix, post.sharedCount)
        
        // [Custom for ONE Krungthai] Hide share button for ONE Krungthai
        shareButton.isHidden = true
        shareLabel.isHidden = true
    }
    
    // MARK: - Setup views
    private func setupView() {
        selectionStyle = .none
        backgroundColor = AmityColorSet.backgroundColor
        contentView.backgroundColor = AmityColorSet.backgroundColor
        // separator
        separatorView.forEach { $0.backgroundColor = AmityColorSet.secondary.blend(.shade4) }
    }
    
    private func setupWarningLabel() {
        // warning
        warningLabel.isHidden = true
        warningLabel.text = AmityLocalizedStringSet.PostDetail.joinCommunityMessage.localizedString
        warningLabel.font = AmityFontSet.body
        warningLabel.textColor = AmityColorSet.base.blend(.shade2)
    }
    
    private func setupLikeButton() {
        // like button
        likeButton.setTitle(AmityLocalizedStringSet.General.liked.localizedString, for: .selected)
        likeButton.setTitle(AmityLocalizedStringSet.General.like.localizedString, for: .normal)
        likeButton.setTitleColor(AmityColorSet.primary, for: .selected)
        likeButton.setTitleColor(AmityColorSet.base.blend(.shade2), for: .normal)
        likeButton.setImage(AmityIconSet.iconLike, for: .normal)
        likeButton.setImage(AmityIconSet.iconLikeFill, for: .selected)
        likeButton.setTintColor(AmityColorSet.primary, for: .selected)
        likeButton.setTintColor(AmityColorSet.base.blend(.shade2), for: .normal)
        likeButton.setTitleFont(AmityFontSet.bodyBold)
        likeButton.setInsets(forContentPadding: .zero, imageTitlePadding: 4)
        
        // like badge
        likeLabel.textColor = AmityColorSet.base.blend(.shade2)
        likeLabel.font = AmityFontSet.caption
    }
    private func setupCommentButton() {
        // comment button
        commentButton.tintColor = AmityColorSet.base.blend(.shade2)
        commentButton.setTitleColor(AmityColorSet.base.blend(.shade2), for: .normal)
        commentButton.setImage(AmityIconSet.iconComment, for: .normal)
        commentButton.setTintColor(AmityColorSet.base.blend(.shade2), for: .normal)
        commentButton.setTitleFont(AmityFontSet.bodyBold)
        commentButton.setInsets(forContentPadding: .zero, imageTitlePadding: 4)
        
        // comment badge
        commentLabel.textColor = AmityColorSet.base.blend(.shade2)
        commentLabel.font = AmityFontSet.caption
    }
    
    private func setupShareButton() {
        // share button
        shareButton.setInsets(forContentPadding: .zero, imageTitlePadding: 4)
        shareButton.setTitleFont(AmityFontSet.bodyBold)
        
        // share
        shareLabel.textColor = AmityColorSet.base.blend(.shade2)
        shareLabel.font = AmityFontSet.caption
    }
    
    private func setLikedButton(reactionType: AmityReactionType) {
        
        switch reactionType {
        case .create:
            likeButton.setTitle(AmityLocalizedStringSet.General.sangsun.localizedString, for: .selected)
            likeButton.setTitleColor(AmityColorSet.dnaSangsun, for: .selected)
            likeButton.setImage(AmityIconSet.iconBadgeDNASangsun, for: .selected)
            likeButton.setTintColor(AmityColorSet.dnaSangsun, for: .selected)
        case .honest:
            likeButton.setTitle(AmityLocalizedStringSet.General.satsue.localizedString, for: .selected)
            likeButton.setTitleColor(AmityColorSet.dnaSatsue, for: .selected)
            likeButton.setImage(AmityIconSet.iconBadgeDNASatsue, for: .selected)
            likeButton.setTintColor(AmityColorSet.dnaSatsue, for: .selected)
        case .harmony:
            likeButton.setTitle(AmityLocalizedStringSet.General.samakki.localizedString, for: .selected)
            likeButton.setTitleColor(AmityColorSet.dnaSamakki, for: .selected)
            likeButton.setImage(AmityIconSet.iconBadgeDNASamakki, for: .selected)
            likeButton.setTintColor(AmityColorSet.dnaSamakki, for: .selected)
        case .success:
            likeButton.setTitle(AmityLocalizedStringSet.General.sumrej.localizedString, for: .selected)
            likeButton.setTitleColor(AmityColorSet.dnaSumrej, for: .selected)
            likeButton.setImage(AmityIconSet.iconBadgeDNASumrej, for: .selected)
            likeButton.setTintColor(AmityColorSet.dnaSumrej, for: .selected)
        case .society:
            likeButton.setTitle(AmityLocalizedStringSet.General.sangkom.localizedString, for: .selected)
            likeButton.setTitleColor(AmityColorSet.dnaSangkom, for: .selected)
            likeButton.setImage(AmityIconSet.iconBadgeDNASangkom, for: .selected)
            likeButton.setTintColor(AmityColorSet.dnaSangkom, for: .selected)
        case .like:
            likeButton.setTitle(AmityLocalizedStringSet.General.liked.localizedString, for: .selected)
            likeButton.setTitleColor(AmityColorSet.dnaLike, for: .selected)
            likeButton.setImage(AmityIconSet.iconLikeFill, for: .selected)
            likeButton.setTintColor(AmityColorSet.dnaLike, for: .selected)
        case .love:
            likeButton.setTitle(AmityLocalizedStringSet.General.love.localizedString, for: .selected)
            likeButton.setTitleColor(AmityColorSet.dnaLove, for: .selected)
            likeButton.setImage(AmityIconSet.iconBadgeDNALove, for: .selected)
            likeButton.setTintColor(AmityColorSet.dnaLove, for: .selected)
        }
    }
    
    private func setReactions(reactions: [String: Int]) {
        let filteredReactions = reactions.filter { $1 != 0 }
        let reactionKeys = Array(filteredReactions.keys)
        if reactionKeys.count <= 0 {
            likeLabelIcon.isHidden = true
            twoReactionsView.isHidden = true
            threeReactionsView.isHidden = true
        }
        else if reactionKeys.count == 1 {
            likeLabelIcon.isHidden = false
            twoReactionsView.isHidden = true
            threeReactionsView.isHidden = true
            
            let reaction: String = reactionKeys[0]
            likeLabelIcon.image = dnaLabelIcon(reactionType: AmityReactionType(rawValue: reaction) ?? .like)
        }
        else if reactionKeys.count == 2 {
            likeLabelIcon.isHidden = true
            twoReactionsView.isHidden = false
            threeReactionsView.isHidden = true
            
            let firstReaction: String = reactionKeys[0]
            twoReactionsFirstIcon.image = dnaLabelIcon(reactionType: AmityReactionType(rawValue: firstReaction) ?? .like)
            
            let secondReaction: String = reactionKeys[1]
            twoReactionsSecondIcon.image = dnaLabelIcon(reactionType: AmityReactionType(rawValue: secondReaction) ?? .like)
        }
        else {
            likeLabelIcon.isHidden = true
            twoReactionsView.isHidden = true
            threeReactionsView.isHidden = false
            
            let firstReaction: String = reactionKeys[0]
            threeReactionsFirstIcon.image = dnaLabelIcon(reactionType: AmityReactionType(rawValue: firstReaction) ?? .like)
            
            let secondReaction: String = reactionKeys[1]
            threeReactionsSecondIcon.image = dnaLabelIcon(reactionType: AmityReactionType(rawValue: secondReaction) ?? .like)
            
            let thirdReaction: String = reactionKeys[2]
            threeReactionsThirdIcon.image = dnaLabelIcon(reactionType: AmityReactionType(rawValue: thirdReaction) ?? .like)
        }
    }
    
    private func dnaLabelIcon(reactionType: AmityReactionType) -> UIImage? {
        switch reactionType {
        case .create:
            return AmityIconSet.iconBadgeDNASangsun
        case .honest:
            return AmityIconSet.iconBadgeDNASatsue
        case .harmony:
            return AmityIconSet.iconBadgeDNASamakki
        case .success:
            return AmityIconSet.iconBadgeDNASumrej
        case .society:
            return AmityIconSet.iconBadgeDNASangkom
        case .like:
            return AmityIconSet.iconBadgeDNALike
        case .love:
            return AmityIconSet.iconBadgeDNALove
        }
    }
 
    // MARK: - Perform Action
    private func performAction(action: AmityPostFooterAction) {
        delegate?.didPerformAction(self, action: action)
    }
    
    private func performAction(action: AmityPostFooterAction, view: UIView) {
        delegate?.didPerformView(self, view: view)
        delegate?.didPerformAction(self, action: action)
    }
}

private extension AmityPostFooterTableViewCell {
    
    @IBAction func likeTap() {
        performAction(action: .tapLike, view: likeButton)
    }
    
    @IBAction func commentTap() {
        performAction(action: .tapComment)
    }
    
    @IBAction func shareTap() {
        performAction(action: .tapShare)
    }
    
    @IBAction func panelTap() {
        performAction(action: .tapComment)
    }
    
    @IBAction func didTapReactionDetails() {
        performAction(action: .tapReactionDetails)
    }
}
