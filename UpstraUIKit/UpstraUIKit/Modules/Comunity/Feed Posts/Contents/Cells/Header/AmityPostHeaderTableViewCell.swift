//
//  AmityPostHeaderTableViewCell.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 2/5/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit

/// `AmityPostHeaderTableViewCell` for providing a header of `Post`
public final class AmityPostHeaderTableViewCell: UITableViewCell, Nibbable, AmityPostHeaderProtocol {
    public weak var delegate: AmityPostHeaderDelegate?
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var avatarView: AmityAvatarView!
    @IBOutlet private var displayNameLabel: AmityFeedDisplayNameLabel!
    @IBOutlet private var badgeStackView: UIStackView!
    @IBOutlet private var badgeIconImageView: UIImageView!
    @IBOutlet private var badgeLabel: UILabel!
    @IBOutlet private var datetimeLabel: UILabel!
    @IBOutlet private var optionButton: UIButton!
    @IBOutlet private var pinPostIconImageView: UIImageView!
    @IBOutlet private var topPaddingConstraint: NSLayoutConstraint!
    
    private(set) public var post: AmityPostModel?
    
    // [Custom for ONE Krungthai] Add these properties for check condition of moderator user in official community for outputing
    private var isModeratorUserInOfficialCommunity: Bool = false
    private var isOfficialCommunity: Bool = false
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.placeholder = AmityIconSet.defaultAvatar
        topPaddingConstraint.constant = 8
    }
    
    public func disableTopPadding() {
        topPaddingConstraint.constant = 0
    }
    
    public func display(post: AmityPostModel) {
        self.post = post
        
        pinPostIconImageView.isHidden = !post.isPinPost
        
        // [Custom for ONE Krungthai] Add condition of moderator user in official community for set avatar view and displayname interaction
        if let community = post.targetCommunity { // Case : Post from community
            isModeratorUserInOfficialCommunity = AmityMemberCommunityUtilities.isModeratorUserInCommunity(withUserId: post.postedUserId, communityId: community.communityId)
            isOfficialCommunity = community.isOfficial
            if isModeratorUserInOfficialCommunity && isOfficialCommunity { // Case : Owner post is moderator and community is official
                avatarView.setImage(withImageURL: community.avatar?.fileURL, placeholder: AmityIconSet.defaultCommunity)
                avatarView.actionHandler = { [weak self] in
                    // Check source of post
                    switch post.appearance.amitySocialPostDisplayStyle {
                    case .feed: // Case : Post output from news feed
                        self?.communityTap()
                    default: // Case : Post output from community profile feed -> Nothing happened
                        break
                    }
                }
            } else { // Case : Owner post is normal user or not official community
                avatarView.setImage(withImageURL: post.postedUser?.avatarURL, placeholder: AmityIconSet.defaultAvatar)
                avatarView.actionHandler = { [weak self] in
                    self?.avatarTap()
                }
            }
        } else { // Case : Post from user profile
            // Original
            avatarView.setImage(withImageURL: post.postedUser?.avatarURL, placeholder: AmityIconSet.defaultAvatar)
            avatarView.actionHandler = { [weak self] in
                self?.avatarTap()
            }
        }
        
        // [Custom for ONE Krungthai] Modify function for moderator user permission (add argument/parameter isModeratorUser: Bool)
        displayNameLabel.configure(displayName: post.displayName,
                                   communityName: post.targetCommunity?.displayName,
                                   isOfficial: post.targetCommunity?.isOfficial ?? false,
                                   shouldShowCommunityName: post.appearance.shouldShowCommunityName, shouldShowBannedSymbol: post.postedUser?.isGlobalBan ?? false, isModeratorUserInOfficialCommunity: isModeratorUserInOfficialCommunity)
        displayNameLabel.delegate = self

        switch post.feedType {
        case .reviewing:
            optionButton.isHidden = !post.isOwner
        default:
            optionButton.isHidden = !(post.appearance.shouldShowOption && post.isCommentable)
        }
        
        if post.isModerator {
            badgeStackView.isHidden = post.postAsModerator
        } else {
            badgeStackView.isHidden = true
        }
        
        displayNameLabel.delegate = self
        datetimeLabel.text = post.subtitle
    }

    // MARK: - Setup views
    private func setupView() {
        // ktb kk set conner radius
        self.containerView.layer.cornerRadius = 10
        self.containerView.layer.masksToBounds = true
        self.containerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        containerView.backgroundColor = AmityColorSet.backgroundColor
        
        topPaddingConstraint.constant = 8
        
        // [Custom for ONE Krungthai] Modify function for moderator user permission (add argument/parameter isModeratorUser: Bool)
        displayNameLabel.configure(displayName: AmityLocalizedStringSet.General.anonymous.localizedString, communityName: nil, isOfficial: false, shouldShowCommunityName: false, shouldShowBannedSymbol: false, isModeratorUserInOfficialCommunity: false)
        
        // badge
        badgeLabel.text = AmityLocalizedStringSet.General.moderator.localizedString + " • "
        badgeLabel.font = AmityFontSet.captionBold
        badgeLabel.textColor = AmityColorSet.base.blend(.shade1)
        badgeIconImageView.image = AmityIconSet.iconBadgeModerator
        
        // date time
        datetimeLabel.font = AmityFontSet.caption
        datetimeLabel.textColor = AmityColorSet.base.blend(.shade1)
        datetimeLabel.text = "45 mins"
        
        // option
        optionButton.tintColor = AmityColorSet.base
        optionButton.setImage(AmityIconSet.iconOption, for: .normal)
        
        // pin post
        pinPostIconImageView.image = AmityIconSet.iconPinpost
    }
    
    // MARK: - Perform Action
    private func performAction(action: AmityPostHeaderAction) {
        delegate?.didPerformAction(self, action: action)
    }
    
}

// MARK: - Action
private extension AmityPostHeaderTableViewCell {
    
    func avatarTap() {
        performAction(action: .tapAvatar)
    }
    
    @IBAction func optionTap() {
        performAction(action: .tapOption)
    }
    
    func communityTap() {
        performAction(action: .tapCommunityName)
    }
}

extension AmityPostHeaderTableViewCell: AmityFeedDisplayNameLabelDelegate {
    func labelDidTapUserDisplayName(_ label: AmityFeedDisplayNameLabel) {
        // [Custom for ONE Krungthai] Add check moderator user in official community for prepare tap displayname button action
        if isModeratorUserInOfficialCommunity && isOfficialCommunity { // Case : Post is from official community and owner is moderator
            // Check source of post
            switch post?.appearance.amitySocialPostDisplayStyle {
            case .feed: // Case : Post output from news feed
                performAction(action: .tapCommunityName)
            case .community: // Case : Post output from community -> Nothing happened
                break
            default: // Case : Other case
                performAction(action: .tapDisplayName)
            }
        } else { // Case : Post isn't from official community or owner isn't moderator
            performAction(action: .tapDisplayName)
        }
    }
    
    func labelDidTapCommunityName(_ label: AmityFeedDisplayNameLabel) {
        performAction(action: .tapCommunityName)
    }
}
