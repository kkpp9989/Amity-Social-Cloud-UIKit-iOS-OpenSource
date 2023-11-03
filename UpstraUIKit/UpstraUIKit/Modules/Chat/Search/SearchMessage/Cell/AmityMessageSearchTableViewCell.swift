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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    private func setupView() {
        containerDisplayNameView.backgroundColor = AmityColorSet.backgroundColor
        containerMessageView.backgroundColor = AmityColorSet.backgroundColor
        contentView.backgroundColor = AmityColorSet.backgroundColor
        selectionStyle = .none
        
        iconImageView.isHidden = true
        statusImageView.isHidden = true
        
        titleLabel.font = AmityFontSet.title
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
    
    func display(with data: MessageSearchModelData, keyword: String) {
        statusImageView.isHidden = false
        memberLabel.text = ""
        dateTimeLabel.text = AmityDateFormatter.Chat.getDate(date: data.messageObjc.createdAt)
        titleLabel.text = data.channelObjc.displayName

        let text = data.messageObjc.data?["text"] as? String ?? "No message"
        let highlightText = highlightKeyword(in: text, keyword: keyword, highlightColor: AmityColorSet.primary)
        previewMessageLabel.attributedText = highlightText
        
        switch data.channelObjc.channelType {
        case .standard:
            avatarView.setImage(withImageURL: data.channelObjc.avatarURL, placeholder: AmityIconSet.defaultGroupChat)
            memberLabel.text = "(\(data.channelObjc.memberCount))"
            statusImageView.isHidden = true
            avatarView.placeholder = AmityIconSet.defaultAvatar
        case .conversation:
            avatarView.placeholder = AmityIconSet.defaultAvatar
            memberLabel.text = nil
            statusImageView.isHidden = false
            AmityMemberChatUtilities.Conversation.getOtherUserByMemberShip(channelId: data.channelObjc.channelId) { user in
                DispatchQueue.main.async { [self] in
                    if let otherMember = user {
                        // Set avatar
                        avatarView.setImage(withImageURL: otherMember.getAvatarInfo()?.fileURL, placeholder: AmityIconSet.defaultAvatar)
                        titleLabel.text = otherMember.displayName
                        let status = otherMember.metadata?["user_presence"] as? String ?? ""
                        if status != "available" {
                            statusBadgeImageView.image = setImageFromStatus(status)
                        } else {
                            if data.channelObjc.isOnline {
                                statusBadgeImageView.image = AmityIconSet.Chat.iconOnlineIndicator
                            } else {
                                statusBadgeImageView.image = AmityIconSet.Chat.iconOfflineIndicator
                            }
                        }
                    }
                }
            }
        case .community:
            avatarView.placeholder = AmityIconSet.defaultGroupChat
            avatarView.setImage(withImageURL: data.channelObjc.avatarURL, placeholder: AmityIconSet.defaultGroupChat)
            memberLabel.text = "(\(data.channelObjc.memberCount))"
            statusImageView.isHidden = true
        case .private, .live, .broadcast, .unknown:
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
}
