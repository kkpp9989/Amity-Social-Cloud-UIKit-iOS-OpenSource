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
    @IBOutlet private var locationLabel: UILabel!
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
        isModeratorUserInOfficialCommunity = false
        isOfficialCommunity = false
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
        
        var locationText = ""
        if let metadata = post.metadata, let location = metadata["location"] as? [String: Any] {
            let name = location["name"] as? String ?? ""
            let address = location["address"] as? String ?? ""
            let lat = location["lat"] as? Double ?? 0.0
            let long = location["lng"] as? Double ?? 0.0
            
            locationText = "\(name) \(address) "
            if name.isEmpty || address.isEmpty {
                locationText = "\(lat), \(long)"
            }
        }
        
        locationLabel.isHidden = locationText.isEmpty
        
        let attributedString = NSMutableAttributedString()
        if !locationText.isEmpty {
            // Append the post prefix locatio  with the desired font
            let prefixLocationAttributes: [NSAttributedString.Key: Any] = [.font: AmityFontSet.caption, .foregroundColor: AmityColorSet.base.blend(.shade1)]
            let prefixLocationAttributeString = NSAttributedString(string: "at ", attributes: prefixLocationAttributes)
            attributedString.append(prefixLocationAttributeString)
            
            // Append the post subtitle with the desired font
            let locationAttributes: [NSAttributedString.Key: Any] = [.font: AmityFontSet.caption, .foregroundColor: AmityColorSet.highlight]
            let locationAttributedString = NSAttributedString(string: locationText, attributes: locationAttributes)
            attributedString.append(locationAttributedString)
            
            locationLabel.attributedText = attributedString
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(locationLabelTapped))
        locationLabel.isUserInteractionEnabled = true
        locationLabel.addGestureRecognizer(tapGestureRecognizer)
    }
//    {
//        self.post = post
//
//        pinPostIconImageView.isHidden = !post.isPinPost
//
//        // [Custom for ONE Krungthai] Add condition of moderator user in official community for set avatar view and displayname interaction
//        if let community = post.targetCommunity { // Case : Post from community
//            isModeratorUserInOfficialCommunity = AmityMemberCommunityUtilities.isModeratorUserInCommunity(withUserId: post.postedUserId, communityId: community.communityId)
//            isOfficialCommunity = community.isOfficial
//            if isModeratorUserInOfficialCommunity && isOfficialCommunity { // Case : Owner post is moderator and community is official
//                avatarView.setImage(withImageURL: community.avatar?.fileURL, placeholder: AmityIconSet.defaultCommunity)
//                avatarView.actionHandler = { [weak self] in
//                    // Check source of post
//                    switch post.appearance.amitySocialPostDisplayStyle {
//                    case .feed: // Case : Post output from news feed
//                        self?.communityTap()
//                    default: // Case : Post output from community profile feed -> Nothing happened
//                        break
//                    }
//                }
//            } else { // Case : Owner post is normal user or not official community
//                avatarView.setImage(withImageURL: post.postedUser?.avatarURL, placeholder: AmityIconSet.defaultAvatar)
//                avatarView.actionHandler = { [weak self] in
//                    self?.avatarTap()
//                }
//            }
//        } else { // Case : Post from user profile
//            // Original
//            avatarView.setImage(withImageURL: post.postedUser?.avatarURL, placeholder: AmityIconSet.defaultAvatar)
//            avatarView.actionHandler = { [weak self] in
//                self?.avatarTap()
//            }
//        }
//
//        // [Custom for ONE Krungthai] Modify function for moderator user permission (add argument/parameter isModeratorUser: Bool)
//        displayNameLabel.configure(displayName: post.displayName,
//                                   communityName: post.targetCommunity?.displayName,
//                                   isOfficial: post.targetCommunity?.isOfficial ?? false,
//                                   shouldShowCommunityName: post.appearance.shouldShowCommunityName, shouldShowBannedSymbol: post.postedUser?.isGlobalBan ?? false, isModeratorUserInOfficialCommunity: isModeratorUserInOfficialCommunity)
//        displayNameLabel.delegate = self
//
//        switch post.feedType {
//        case .reviewing:
//            optionButton.isHidden = !post.isOwner
//        default:
//            optionButton.isHidden = !(post.appearance.shouldShowOption && post.isCommentable)
//        }
//
//        if post.isModerator {
//            badgeStackView.isHidden = post.postAsModerator
//            badgeIconImageView.isHidden = post.postAsModerator
//        } else {
//            badgeStackView.isHidden = true
//        }
//
//        datetimeLabel.text = post.subtitle
//        badgeLabel.text = AmityLocalizedStringSet.General.moderator.localizedString + " • "
//
//        var locationText = ""
//        if let metadata = post.metadata, let location = metadata["location"] as? [String: Any] {
//            let name = location["name"] as? String ?? ""
//            let address = location["address"] as? String ?? ""
//            let lat = location["lat"] as? Double ?? 0.0
//            let long = location["lng"] as? Double ?? 0.0
//
//            locationText = "\(name) \(address) "
//            if name.isEmpty || address.isEmpty {
//                locationText = "\(lat), \(long)"
//            }
//        }
//
//        locationLabel.isHidden = locationText.isEmpty
//
//        let attributedString = NSMutableAttributedString()
//        if !locationText.isEmpty {
//            // Append the post prefix locatio  with the desired font
//            let prefixLocationAttributes: [NSAttributedString.Key: Any] = [.font: AmityFontSet.caption, .foregroundColor: AmityColorSet.base.blend(.shade1)]
//            let prefixLocationAttributeString = NSAttributedString(string: "at ", attributes: prefixLocationAttributes)
//            attributedString.append(prefixLocationAttributeString)
//
//            // Append the post subtitle with the desired font
//            let locationAttributes: [NSAttributedString.Key: Any] = [.font: AmityFontSet.caption, .foregroundColor: AmityColorSet.highlight]
//            let locationAttributedString = NSAttributedString(string: locationText, attributes: locationAttributes)
//            attributedString.append(locationAttributedString)
//
//            locationLabel.attributedText = attributedString
//        }
//
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(badgeLabelTapped))
//        locationLabel.isUserInteractionEnabled = true
//        locationLabel.addGestureRecognizer(tapGestureRecognizer)
//    }

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
        
        topPaddingConstraint.constant = 16
        
        // [Custom for ONE Krungthai] Modify function for moderator user permission (add argument/parameter isModeratorUser: Bool)
        displayNameLabel.configure(displayName: AmityLocalizedStringSet.General.anonymous.localizedString, communityName: nil, isOfficial: false, shouldShowCommunityName: false, shouldShowBannedSymbol: false, isModeratorUserInOfficialCommunity: false)
        
        // badge
        badgeLabel.text = AmityLocalizedStringSet.General.moderator.localizedString + " • "
        badgeLabel.font = AmityFontSet.captionBold
        badgeLabel.textColor = AmityColorSet.base.blend(.shade1)
        badgeLabel.numberOfLines = 1
        badgeIconImageView.image = AmityIconSet.iconBadgeModerator
        
        // location
        locationLabel.text = ""
        locationLabel.font = AmityFontSet.captionBold
        locationLabel.textColor = AmityColorSet.highlight
        locationLabel.numberOfLines = 2
        locationLabel.isHidden = true
        
        // date time
        datetimeLabel.font = AmityFontSet.caption
        datetimeLabel.textColor = AmityColorSet.base.blend(.shade1)
        datetimeLabel.text = "45 mins"
        datetimeLabel.numberOfLines = 1

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
    
    func showToast() {
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
            let message = "Unable to Open Google Maps"
            ToastView.shared.showToast(message: message, in: window)
        }
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
    
    @objc func locationLabelTapped() {
        if let location = post?.metadata?["location"] as? [String:Any] {
            let latitude = location["lat"] as? Double
            let longitude = location["lng"] as? Double
            let placeId = location["googlemap_place_id"] as? String

            var urlString: String
            if let latitude = latitude, let longitude = longitude {
                // Use the coordinates to open Google Maps
                if let placeId = placeId  {
                    urlString = "comgooglemaps://?q=\(latitude),\(longitude)&q=place_id:\(placeId)"
                } else {
                    urlString = "comgooglemaps://?q=\(latitude),\(longitude)"
                }
            } else {
                showToast()
                return
            }
            
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                // Fallback to Google Maps web if the app is not installed
                if let latitude = latitude, let longitude = longitude {
                    if let placeId = placeId {
                        urlString = "https://www.google.com/maps/search/?api=1&query=\(latitude),\(longitude)&query_place_id=\(placeId)"
                    } else {
                        urlString = "https://www.google.com/maps/search/?api=1&query=\(latitude),\(longitude)"
                    }
                } else {
                    showToast()
                    return
                }
                
                if let url = URL(string: urlString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
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
