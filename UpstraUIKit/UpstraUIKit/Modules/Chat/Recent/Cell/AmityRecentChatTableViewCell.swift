//
//  AmityRecentChatTableViewCell.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 7/7/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit
import AmitySDK

final class AmityRecentChatTableViewCell: UITableViewCell, Nibbable {
    
    @IBOutlet private var containerDisplayNameView: UIView!
    @IBOutlet private var containerMessageView: UIView!
    @IBOutlet private var avatarView: AmityAvatarView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var iconImageView: UIImageView!
    @IBOutlet private var statusImageView: UIImageView!
    @IBOutlet private var memberLabel: UILabel!
    @IBOutlet private var badgeView: AmityBadgeView!
    @IBOutlet private var mentionBadgeImageView: UIImageView!
    @IBOutlet private var previewMessageLabel: UILabel!
    @IBOutlet private var dateTimeLabel: UILabel!
    @IBOutlet private var statusBadgeImageView: UIImageView!

    private var token: AmityNotificationToken?
    private var repository: AmityUserRepository?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
        dateTimeLabel.text = ""
        badgeView.badge = 0
        avatarView.image = nil
    }
    
    private func setupView() {
        repository = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
        
        containerDisplayNameView.backgroundColor = AmityColorSet.backgroundColor
        containerMessageView.backgroundColor = AmityColorSet.backgroundColor
        contentView.backgroundColor = AmityColorSet.backgroundColor
        selectionStyle = .none
        
        iconImageView.isHidden = true
        statusImageView.isHidden = true
        badgeView.isHidden = true
        
        titleLabel.font = AmityFontSet.title
        titleLabel.textColor = AmityColorSet.base
        memberLabel.font = AmityFontSet.caption
        memberLabel.textColor = AmityColorSet.base.blend(.shade1)
        
        previewMessageLabel.text = "No message yet"
        previewMessageLabel.numberOfLines = 2
        previewMessageLabel.font = AmityFontSet.body
        previewMessageLabel.textColor = AmityColorSet.base.blend(.shade2)
        previewMessageLabel.alpha = 1
        
        dateTimeLabel.font = AmityFontSet.caption
        dateTimeLabel.textColor = AmityColorSet.base.blend(.shade2)
        
        mentionBadgeImageView.image = AmityIconSet.Chat.iconMentionBadges
        mentionBadgeImageView.isHidden = true
    }
    
    func display(with channel: AmityChannelModel) {
        badgeView.badge = channel.unreadCount
        memberLabel.text = ""
        dateTimeLabel.text = AmityDateFormatter.Chat.getDate(date: channel.lastActivity)
        titleLabel.text = channel.displayName
        avatarView.placeholder = AmityIconSet.defaultAvatar
        mentionBadgeImageView.isHidden = !channel.object.hasMentioned
        badgeView.isHidden = channel.unreadCount < 1
        
        if let previewMessage = channel.previewMessage {
            //  You can access data of preview message in same way as AmityMessage
            let text = previewMessage.data?["text"] as? String ?? "No message yet"
            let type = previewMessage.dataType
            
            previewMessageLabel.text = text
        }

        switch channel.channelType {
        case .standard:
            avatarView.setImage(withImageURL: channel.avatarURL, placeholder: AmityIconSet.defaultGroupChat)
            memberLabel.text = "(\(channel.memberCount))"
        case .conversation:
            memberLabel.text = nil
            statusImageView.isHidden = false
            AmityMemberChatUtilities.Conversation.getOtherUserByMemberShip(channelId: channel.channelId) { user in
                DispatchQueue.main.async { [self] in
                    if let otherMember = user {
                        // Set avatar
                        avatarView.setImage(withImageURL: otherMember.getAvatarInfo()?.fileURL, placeholder: AmityIconSet.defaultAvatar)
                        titleLabel.text = otherMember.displayName
                        let status = otherMember.metadata?["user_presence"] as? String ?? ""
                        if status != "available" {
                            statusBadgeImageView.image = setImageFromStatus(status)
                        } else {
                            if channel.isOnline {
                                statusBadgeImageView.image = AmityIconSet.Chat.iconOnlineIndicator
                            } else {
                                statusBadgeImageView.image = AmityIconSet.Chat.iconOfflineIndicator
                            }
                        }
                    }
                }
            }
        case .community:
            avatarView.setImage(withImageURL: channel.avatarURL, placeholder: AmityIconSet.defaultGroupChat)
            memberLabel.text = "(\(channel.memberCount))"
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
            return AmityIconSet.Chat.iconStatusAvailable ?? UIImage()
        }
    }
}
