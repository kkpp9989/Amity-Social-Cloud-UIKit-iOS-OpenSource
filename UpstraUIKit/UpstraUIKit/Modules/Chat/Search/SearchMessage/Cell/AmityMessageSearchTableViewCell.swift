//
//  AmityMessageSearchTableViewCell.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 10/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

class AmityMessageSearchTableViewCell: UITableViewCell, Nibbable {
    
    @IBOutlet private var containerDisplayNameView: UIView!
    @IBOutlet private var containerMessageView: UIView!
    @IBOutlet private var avatarView: AmityAvatarView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var iconImageView: UIImageView!
    @IBOutlet private var statusImageView: UIImageView!
    @IBOutlet private var memberLabel: UILabel!
    @IBOutlet private var previewMessageLabel: UILabel!
    @IBOutlet private var dateTimeLabel: UILabel!
    @IBOutlet private var statusBadgeImageView: UIImageView!
    @IBOutlet private var badgeStatusView: UIView!

    private var token: AmityNotificationToken?
    private var repository: AmityUserRepository?
    
    public var searchData: MessageSearchModelData?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    private func setupView() {
        repository = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)

        containerDisplayNameView.backgroundColor = AmityColorSet.backgroundColor
        containerMessageView.backgroundColor = AmityColorSet.backgroundColor
        contentView.backgroundColor = AmityColorSet.backgroundColor
        selectionStyle = .none
        
        iconImageView.isHidden = true
        statusImageView.isHidden = true
        badgeStatusView.isHidden = true

        badgeStatusView.backgroundColor = .white
        badgeStatusView.layer.cornerRadius = badgeStatusView.frame.height / 2
        badgeStatusView.layer.borderColor = UIColor.white.cgColor
        badgeStatusView.layer.borderWidth = 2.0
        badgeStatusView.contentMode = .scaleAspectFit
        badgeStatusView.clipsToBounds = true
        
        titleLabel.font = AmityFontSet.body
        titleLabel.textColor = AmityColorSet.base
        memberLabel.font = AmityFontSet.caption
        memberLabel.textColor = AmityColorSet.base.blend(.shade1)
        
        previewMessageLabel.text = "No message"
        previewMessageLabel.numberOfLines = 2
        previewMessageLabel.font = AmityFontSet.body
        previewMessageLabel.textColor = AmityColorSet.base.blend(.shade2)
        previewMessageLabel.alpha = 1
        
        dateTimeLabel.font = AmityFontSet.caption
        dateTimeLabel.textColor = AmityColorSet.base.blend(.shade2)
    }
    
    func display(with data: MessageSearchModelData, keyword: String, isOnline: Bool) {
        searchData = data
        statusImageView.isHidden = false
        memberLabel.text = ""
        dateTimeLabel.text = AmityDateFormatter.Chat.getDate(from: data.messageObjc.createdAt ?? "")
        titleLabel.text = data.channelObjc.displayName
        badgeStatusView.isHidden = true
        badgeStatusView.backgroundColor = .clear
        
        let text = data.messageObjc.data?.text ?? "No message"
        let highlightText = highlightKeyword(in: text, keyword: keyword, highlightColor: AmityColorSet.primary)
        previewMessageLabel.attributedText = highlightText
        
        switch data.channelObjc.channelType {
        case .standard:
            avatarView.setImage(withImageURL: data.channelObjc.avatarURL, placeholder: AmityIconSet.defaultGroupChat)
            memberLabel.text = "(\(data.channelObjc.memberCount))"
            statusImageView.isHidden = true
            iconImageView.isHidden = true
            avatarView.placeholder = AmityIconSet.defaultAvatar
        case .conversation:
            avatarView.placeholder = AmityIconSet.defaultAvatar
            memberLabel.text = nil
            statusImageView.isHidden = false
            iconImageView.isHidden = true
            badgeStatusView.isHidden = false
            badgeStatusView.backgroundColor = .white
            
            getOtherUser(channel: data.channelObjc) { user in
                DispatchQueue.main.async { [self] in
                    if let otherMember = user {
                        // Set avatar
                        avatarView.setImage(withImageURL: otherMember.getAvatarInfo()?.fileURL, placeholder: AmityIconSet.defaultAvatar)
                        titleLabel.text = otherMember.displayName
                        let status = otherMember.metadata?["user_presence"] as? String ?? ""
                        if status != "available" {
                            statusBadgeImageView.image = setImageFromStatus(status)
                        } else {
                            if isOnline {
                                statusBadgeImageView.image = AmityIconSet.Chat.iconOnlineIndicator
                            } else {
                                statusBadgeImageView.image = AmityIconSet.Chat.iconOfflineIndicator
                            }
                        }
                    }
                }
            }
        case .community, .live:
            avatarView.placeholder = AmityIconSet.defaultGroupChat
            avatarView.setImage(withImageURL: data.channelObjc.avatarURL, placeholder: AmityIconSet.defaultGroupChat)
            memberLabel.text = "(\(data.channelObjc.memberCount))"
            statusImageView.isHidden = true
            statusBadgeImageView.isHidden = true
            badgeStatusView.isHidden = true
            badgeStatusView.backgroundColor = .clear
            
            iconImageView.isHidden = false
            var iconBadge = AmityIconSet.Chat.iconPublicBadge
            if data.channelObjc.channelType == .live {
                iconBadge = AmityIconSet.Chat.iconPrivateBadge
            }
            iconImageView.image = iconBadge
        case .private, .broadcast, .unknown:
            break
        @unknown default:
            break
        }
    }
    
    private func setImageFromStatus(_ status: String) -> UIImage {
        switch status {
        case "available":
            return AmityIconSet.Chat.iconOnlineIndicator ?? UIImage()
        case "do_not_disturb":
            return AmityIconSet.Chat.iconStatusDoNotDisTurb ?? UIImage()
        case "work_from_home":
            return AmityIconSet.Chat.iconStatusWorkFromHome ?? UIImage()
        case "in_a_meeting":
            return AmityIconSet.Chat.iconStatusInAMeeting ?? UIImage()
        case "on_leave":
            return AmityIconSet.Chat.iconStatusOnLeave ?? UIImage()
        case "out_sick":
            return AmityIconSet.Chat.iconStatusOutSick ?? UIImage()
        default:
            statusBadgeImageView.isHidden = true
            badgeStatusView.isHidden = true
            badgeStatusView.backgroundColor = .clear
            return UIImage()
        }
    }
    
    func highlightKeyword(in text: String, keyword: String, highlightColor: UIColor) -> NSAttributedString {
        // Create an attributed string with the original text
        let attributedText = NSMutableAttributedString(string: text)
        
        // Define the attributes for the keyword's appearance (e.g., text color)
        let keywordAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: highlightColor
        ]
        
        // Use a case-insensitive search to find all occurrences of the keyword in the text
        let range = (text as NSString).range(of: keyword, options: .caseInsensitive)
        
        // If the keyword is found, apply the keywordAttributes to the range
        if range.location != NSNotFound {
            attributedText.addAttributes(keywordAttributes, range: range)
        }
        
        return attributedText
    }
    
    func getOtherUser(channel: AmityChannelModel, completion: @escaping (_ user: AmityUser?) -> Void) {
        token?.invalidate()
        if !channel.getOtherUserId().isEmpty {
            token = repository?.getUser(channel.getOtherUserId()).observeOnce({ [weak self] user, error in
                guard let weakSelf = self else { return }
                let userObject = user.snapshot
                weakSelf.token?.invalidate()
                completion(userObject)
            })
        }
    }
}
