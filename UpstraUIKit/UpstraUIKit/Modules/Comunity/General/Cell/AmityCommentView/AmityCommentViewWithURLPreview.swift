//
//  AmityCommentViewWithURLPreview.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 7/12/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityCommentViewWithURLPreviewDelegate: AnyObject {
    func commentView(_ view: AmityCommentViewWithURLPreview, didTapAction action: AmityCommentViewAction)
}

class AmityCommentViewWithURLPreview: AmityView {
    
    // MARK: - IBOutlet Properties
    @IBOutlet private weak var avatarView: AmityAvatarView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet weak var contentLabel: AmityExpandableLabel!
    @IBOutlet private var labelContainerView: UIView!
    @IBOutlet private weak var actionStackView: UIStackView!
    @IBOutlet private weak var likeButton: AmityButton!
    @IBOutlet private weak var replyButton: AmityButton!
    @IBOutlet private weak var optionButton: UIButton!
    @IBOutlet private weak var viewReplyButton: AmityButton!
    @IBOutlet private weak var separatorLineView: UIView!
    @IBOutlet private weak var leadingAvatarImageViewConstraint: NSLayoutConstraint!
    @IBOutlet private weak var topAvatarImageViewConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bannedImageView: UIImageView!
    @IBOutlet private weak var bannedImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var reactionDetailContainerView: UIView!
    @IBOutlet private weak var reactionDetailLikeIcon: UIImageView!
    @IBOutlet private weak var reactionDetailLabel: UILabel!
    @IBOutlet private weak var reactionDetailButton: UIButton!
    @IBOutlet private weak var contentImageView: UIImageView!
    @IBOutlet private weak var contentContainerView: UIView!
    
    // MARK: - Properties
    weak var delegate: AmityCommentViewWithURLPreviewDelegate?
    private(set) var comment: AmityCommentModel?
    public var isModeratorUserInOfficialCommunity: Bool = false
    public var isOfficialCommunity: Bool = false
    public var shouldDidTapAction: Bool = true
    
    // MARK: - URLPreview IBOutlet Properties
    @IBOutlet var urlPreviewImage: UIImageView!
    @IBOutlet var urlPreviewDomain: UILabel!
    @IBOutlet var urlPreviewTitle: UILabel!
    @IBOutlet var urlPreviewView: UIView!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    
    private var fileURL: String? = ""

    // MARK: - URLPreview Properties
    private var urlToOpen: URL?
    
    override func initial() {
        loadNibContent()
        setupView()
        setupURLPreviewView()
    }
    
    private func setupView() {
        avatarView.placeholder = AmityIconSet.defaultAvatar
        avatarView.actionHandler = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.commentView(strongSelf, didTapAction: .avatar)
        }
        titleLabel.textColor = AmityColorSet.base
        titleLabel.font = AmityFontSet.bodyBold
        timeLabel.textColor = AmityColorSet.base.blend(.shade1)
        timeLabel.font = AmityFontSet.caption
        
        contentLabel.textColor = AmityColorSet.base
        contentLabel.font = AmityFontSet.body
        contentLabel.numberOfLines = 8
        separatorLineView.backgroundColor  = AmityColorSet.secondary.blend(.shade4)
        separatorLineView.isHidden = true
        
        labelContainerView.backgroundColor = AmityColorSet.base.blend(.shade4)
        labelContainerView.layer.cornerRadius = 12
        labelContainerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        
        reactionDetailLabel.text = ""
        reactionDetailLabel.font = AmityFontSet.caption
        reactionDetailLabel.textColor = AmityColorSet.base.blend(.shade2)
        reactionDetailButton.addTarget(self, action: #selector(onReactionDetailButtonTap), for: .touchUpInside)
        
        likeButton.setTitle(AmityLocalizedStringSet.General.like.localizedString, for: .normal)
        likeButton.setTitleFont(AmityFontSet.captionBold)
        likeButton.setImage(AmityIconSet.iconLike, for: .normal)
        likeButton.setImage(AmityIconSet.iconLikeFill, for: .selected)
        likeButton.setTitleColor(AmityColorSet.primary, for: .selected)
        likeButton.setTitleColor(AmityColorSet.base.blend(.shade2), for: .normal)
        likeButton.setTintColor(AmityColorSet.primary, for: .selected)
        likeButton.setTintColor(AmityColorSet.base.blend(.shade2), for: .normal)
        likeButton.addTarget(self, action: #selector(likeButtonTap), for: .touchUpInside)
        likeButton.setInsets(forContentPadding: .zero, imageTitlePadding: 4)
        
        replyButton.setTitle(AmityLocalizedStringSet.General.reply.localizedString, for: .normal)
        replyButton.setTitleFont(AmityFontSet.captionBold)
        replyButton.setImage(AmityIconSet.iconReply, for: .normal)
        replyButton.tintColor = AmityColorSet.base.blend(.shade2)
        replyButton.setTitleColor(AmityColorSet.primary, for: .selected)
        replyButton.setTitleColor(AmityColorSet.base.blend(.shade2), for: .normal)
        replyButton.addTarget(self, action: #selector(replyButtonTap), for: .touchUpInside)
        replyButton.setInsets(forContentPadding: .zero, imageTitlePadding: 4)
        
        optionButton.addTarget(self, action: #selector(optionButtonTap), for: .touchUpInside)
        optionButton.tintColor = AmityColorSet.base.blend(.shade2)
        
        viewReplyButton.setTitle(AmityLocalizedStringSet.General.viewReply.localizedString, for: .normal)
        viewReplyButton.setTitleFont(AmityFontSet.captionBold)
        viewReplyButton.setTitleColor(AmityColorSet.base.blend(.shade1), for: .normal)
        viewReplyButton.setTintColor(AmityColorSet.base.blend(.shade1), for: .normal)
        viewReplyButton.setImage(AmityIconSet.iconReplyInverse, for: .normal)
        viewReplyButton.backgroundColor = AmityColorSet.secondary.blend(.shade4)
        viewReplyButton.clipsToBounds = true
        viewReplyButton.layer.cornerRadius = 4
        viewReplyButton.setInsets(forContentPadding: UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 16), imageTitlePadding: 8)
        viewReplyButton.addTarget(self, action: #selector(viewReplyButtonTap), for: .touchUpInside)
        
        contentContainerView.backgroundColor = .clear
        contentContainerView.isHidden = true
        contentImageView.isHidden = true
        contentImageView.contentMode = .scaleAspectFill
        contentImageView.image = AmityIconSet.videoThumbnailPlaceholder
        
        // Setup tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(commentImageViewTap(_:)))
        contentImageView.addGestureRecognizer(tapGesture)
    }
    
    // [Custom for ONE Krungthai] Modify function for use post model for check moderator user in official community for outputing
    func configure(with comment: AmityCommentModel, layout: AmityCommentViewWithURLPreview.Layout, post: AmityPostModel? = nil) {
        self.comment = comment
        if comment.isEdited {
            timeLabel.text = String.localizedStringWithFormat(AmityLocalizedStringSet.PostDetail.postDetailCommentEdit.localizedString, comment.createdAt.relativeTime)
        } else {
            timeLabel.text = comment.createdAt.relativeTime
        }
        
        // [Custom for ONE Krungthai] Add check moderator user in official community for outputing
        if let community = post?.targetCommunity { // Case : Comment from post community
            isModeratorUserInOfficialCommunity = AmityMemberCommunityUtilities.isModeratorUserInCommunity(withUserId: comment.userId, communityId: community.communityId)
            isOfficialCommunity = community.isOfficial
            if let currentPost = post, isModeratorUserInOfficialCommunity, isOfficialCommunity { // Case : Comment owner is moderator in official community
                switch post?.appearance.amitySocialPostDisplayStyle {
                case .community:
                    shouldDidTapAction = false
                default:
                    break
                }
                
                avatarView.setImage(withImageURL: currentPost.targetCommunity?.avatar?.fileURL, placeholder: AmityIconSet.defaultCommunity)
                titleLabel.text = currentPost.targetCommunity?.displayName ?? comment.displayName
                titleLabel.setImageWithText(position: .right(image: AmityIconSet.iconBadgeCheckmark), size: CGSize(width: 18, height: 18), tintColor: AmityColorSet.highlight) // Badge
            } else { // Case : Comment owner isn't moderator or not official community
                // Original
                avatarView.setImage(withImageURL: comment.fileURL, placeholder: AmityIconSet.defaultAvatar)
                titleLabel.text = comment.displayName
            }
        } else { // Case : Comment from user profile post
            // Original
            avatarView.setImage(withImageURL: comment.fileURL, placeholder: AmityIconSet.defaultAvatar)
            titleLabel.text = comment.displayName
        }
        
        if comment.isAuthorGlobalBanned {
            bannedImageView.isHidden = false
            bannedImageViewWidthConstraint.constant = 16
            bannedImageView.image = AmityIconSet.CommunitySettings.iconCommunitySettingBanned
        }
        
        if let metadata = comment.metadata, let mentionees = comment.mentionees {
            let attributes = AmityMentionManager.getAttributes(fromText: comment.text, withMetadata: metadata, mentionees: mentionees)
            contentLabel.setText(comment.text, withAttributes: attributes)
        } else {
            contentLabel.text = comment.text
        }
        
        likeButton.isSelected = comment.isLiked
        let likeButtonTitle = comment.isLiked ? AmityLocalizedStringSet.General.liked.localizedString : AmityLocalizedStringSet.General.like.localizedString
        likeButton.setTitle(likeButtonTitle, for: .normal)
        
        replyButton.isHidden = layout.type == .reply
        
        separatorLineView.isHidden = true
        
        if comment.reactionsCount > 0 {
            reactionDetailContainerView.isHidden = false
            reactionDetailButton.isEnabled = true
            reactionDetailLabel.text = comment.reactionsCount.formatUsingAbbrevation()
        } else {
            reactionDetailButton.isEnabled = false
            reactionDetailContainerView.isHidden = true
        }
        
        // Image comment data
        if !comment.isDeleted {
            if !comment.comment.attachments.isEmpty {
                for attachment in comment.comment.attachments {
                    self.contentContainerView.isHidden = false
                    self.contentImageView.isHidden = false
                    switch attachment {
                    case .image(fileId: let fileId, data: _):
                        AmityUIKitManagerInternal.shared.fileService.getImageURLByFileId(fileId: fileId) { resultImageURL in
                            switch resultImageURL {
                            case .success(let imageURL):
                                DispatchQueue.main.async {
                                    self.fileURL = imageURL
                                    self.contentImageView.loadImage(with: imageURL, size: .full, placeholder: AmityIconSet.videoThumbnailPlaceholder)
                                    self.contentImageView.isUserInteractionEnabled = true
                                }
                            case .failure(_):
                                DispatchQueue.main.async {
                                    self.contentContainerView.isHidden = true
                                }
                            }
                        }
                    @unknown default:
                        print("Unknown attachment")
                        self.contentContainerView.isHidden = true
                    }
                }
            } else {
                // Handle case when attachments are empty
                self.contentContainerView.isHidden = true
            }
        } else {
            self.contentContainerView.isHidden = true
        }
        
        contentLabel.isExpanded = layout.isExpanded
        
        toggleActionVisibility(comment: comment, layout: layout)
        
        viewReplyButton.isHidden = !layout.shouldShowViewReplyButton(for: comment)
        leadingAvatarImageViewConstraint.constant = layout.space.avatarLeading
        topAvatarImageViewConstraint.constant = layout.space.aboveAvatar
        
        displayURLPreview(comment: comment)
    }
    
    func toggleActionVisibility(comment: AmityCommentModel, layout: AmityCommentViewWithURLPreview.Layout) {
        var actionButtons = [likeButton, replyButton, optionButton]
        
        // [Custom for ONE Krungthai] Hide reply button if comment is reply comment
        if layout.type == .reply {
            actionButtons = [likeButton, optionButton]
        }
        
        if layout.shouldShowActions {
            actionButtons.forEach { $0?.isHidden = false }
            actionStackView.isHidden = false
        } else {
            // Only show reactions count label if present
            if comment.reactionsCount > 0 {
                actionStackView.isHidden = false
                actionButtons.forEach { $0?.isHidden = true }
            } else {
                actionStackView.isHidden = true
            }
        }
    }
    
    @IBAction func displaynameTap(_ sender: Any) {
        delegate?.commentView(self, didTapAction: .avatar)
    }
    
    @objc private func replyButtonTap() {
        delegate?.commentView(self, didTapAction: .reply)
    }

    @objc private func likeButtonTap() {
        delegate?.commentView(self, didTapAction: .like)
    }

    @objc private func optionButtonTap() {
        delegate?.commentView(self, didTapAction: .option)
    }
    
    @objc private func viewReplyButtonTap() {
        delegate?.commentView(self, didTapAction: .viewReply)
    }
    
    @objc private func onReactionDetailButtonTap() {
        delegate?.commentView(self, didTapAction: .reactionDetails)
    }
    
    @objc private func commentImageViewTap(_ sender: UITapGestureRecognizer) {
        delegate?.commentView(self, didTapAction: .commentImage(imageView: contentImageView, fileURL: fileURL))
    }
    
    func prepareForReuse() {
        bannedImageView.image = nil
        comment = nil
        contentContainerView.isHidden = true
        contentImageView.image = AmityIconSet.videoThumbnailPlaceholder
        contentImageView.isUserInteractionEnabled = false
        clearURLPreviewView()
    }
    
    open class func height(with comment: AmityCommentModel, layout: AmityCommentView.Layout, boundingWidth: CGFloat) -> CGFloat {
        
        let topSpace: CGFloat = 65 + layout.space.aboveAvatar
        
        let contentHeight: CGFloat = {
            let maximumLines = layout.isExpanded ? 0 : 8
            let leftSpace: CGFloat = layout.space.avatarLeading + layout.space.avatarViewWidth + 8 + 12
            let rightSpace: CGFloat = 12 + 16
            let labelBoundingWidth = boundingWidth - leftSpace - rightSpace
            let height = AmityExpandableLabel.height(
                for: comment.text,
                font: AmityFontSet.body,
                boundingWidth: labelBoundingWidth,
                maximumLines: maximumLines
            )
            return height + 100
        } ()
        
        
        let bottomStackHeight: CGFloat = {
            var bottomStackViews: [CGFloat] = []
            // If actions should be shown OR actions should not be shown but comment reaction detail label should be shown.
            if layout.shouldShowActions || (!layout.shouldShowActions && comment.reactionsCount > 0) {
                let actionButtonHeight: CGFloat = 22
                bottomStackViews += [actionButtonHeight]
            }
            if layout.shouldShowViewReplyButton(for: comment) {
                let viewReplyHeight: CGFloat = 28
                bottomStackViews += [viewReplyHeight]
            }
            let spaceBetweenElement: CGFloat = 12
            let numberOfSpaceBetweenElements: CGFloat = CGFloat(max(bottomStackViews.count - 1, 0))
            let bottomStackViewHeight = bottomStackViews.reduce(0, +) + (spaceBetweenElement * numberOfSpaceBetweenElements)
            return bottomStackViewHeight
        } ()
        
        let contentImageHeight: CGFloat = {
            let contentHeight: CGFloat = !comment.comment.attachments.isEmpty ? 150 : 0
            return contentHeight
        }()
        
        return topSpace
        + contentHeight
        + layout.space.belowContent
        + layout.space.aboveStack
        + bottomStackHeight
        + layout.space.belowStack
        + contentImageHeight

    }
    
}

// MARK: URL Preview
extension AmityCommentViewWithURLPreview {
    // MARK: - Setup URL Preview
    func setupURLPreviewView() {
        // Setup image
        urlPreviewImage.image = nil
        urlPreviewImage.contentMode = .scaleAspectFill
        loadingIndicator.hidesWhenStopped = true

        // Setup domain
        urlPreviewDomain.text = " "
        urlPreviewDomain.font = AmityFontSet.caption
        urlPreviewDomain.textColor = AmityColorSet.disableTextField
        urlPreviewDomain.numberOfLines = 1

        // Setup title
        urlPreviewTitle.text = " "
        urlPreviewTitle.font = AmityFontSet.captionBold
        urlPreviewTitle.textColor = AmityColorSet.base
        urlPreviewTitle.numberOfLines = 2

        // Setup ishidden status of view & constant for URL preview
        urlPreviewView.isHidden = false

        // Setup tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openURLTapAction(_:)))
        urlPreviewView.addGestureRecognizer(tapGesture)
        urlToOpen = nil
    }

    // MARK: - Display URL Preview
    func displayURLPreview(comment: AmityCommentModel) {
        if let title = comment.metadata?["url_preview_cache_title"] as? String,
           let fullURL = comment.metadata?["url_preview_cache_url"] as? String,
           let urlData = URL(string: fullURL),
           let domainURL = urlData.host?.replacingOccurrences(of: "www.", with: ""),
           let urlDetected = AmityPreviewLinkWizard.shared.detectURLStringWithURLEncoding(text: comment.text), urlDetected == fullURL
        {
            // Set URL data to open
            urlToOpen = urlData
            
            // Set domain and title text
            urlPreviewTitle.text = title
            urlPreviewDomain.text = domainURL
            
            // Show URL preview view
            urlPreviewView.isHidden = false
            
            // Show loading indicator
            self.loadingIndicator.startAnimating()
            
            // Get URL Metadata for loading image preview
            Task { @MainActor in
                if let metadata = await AmityPreviewLinkWizard.shared.getMetadata(url: urlData), let imageProvider = metadata.imageProvider {
                    // Loading image preview
                    imageProvider.loadObject(ofClass: UIImage.self, completionHandler: { [weak self] image, error in
                        guard let self else { return }
                        // Set image preview if have or default image URL preview
                        DispatchQueue.main.async {
                            if let image = image as? UIImage {
                                self.urlPreviewImage.image = image
                            } else {
                                self.urlPreviewImage.image = AmityIconSet.defaultImageURLPreview
                            }
                            // Stop loading indicator
                            self.loadingIndicator.stopAnimating()
                        }
                    })
                } else {
                    self.urlPreviewImage.image = AmityIconSet.defaultImageURLPreview
                    self.loadingIndicator.stopAnimating()
                }
            }
        }
    }

    // MARK: - Clear URL Preview
    private func clearURLPreviewView() {
        urlPreviewView.isHidden = false
        urlPreviewTitle.text = " "
        urlPreviewDomain.text = " "
        urlPreviewImage.image = nil
        urlToOpen = nil
    }

    // MARK: - Perform open URL Action
    @objc func openURLTapAction(_ sender: UITapGestureRecognizer) {
        if let currentURLData = urlToOpen {
            UIApplication.shared.open(currentURLData, options: [:], completionHandler: nil)
        }
    }
}
