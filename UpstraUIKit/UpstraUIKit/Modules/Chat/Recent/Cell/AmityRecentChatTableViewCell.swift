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
    @IBOutlet private var badgeStatusView: UIView!

    private var token: AmityNotificationToken?
    private var repository: AmityUserRepository?
    
    public var channel: AmityChannelModel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset any cell-specific properties here
        statusBadgeImageView.image = nil
        statusBadgeImageView.isHidden = true
        badgeStatusView.isHidden = true
        previewMessageLabel.text = "No message"
        avatarView.image = nil
        channel = nil
    }
    
    private func setupView() {
        repository = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
        
        containerDisplayNameView.backgroundColor = AmityColorSet.backgroundColor
        containerMessageView.backgroundColor = AmityColorSet.backgroundColor
        contentView.backgroundColor = AmityColorSet.backgroundColor
        selectionStyle = .none
        
        iconImageView.isHidden = true
        badgeView.isHidden = true
        statusImageView.isHidden = true
        statusBadgeImageView.isHidden = true
        badgeStatusView.isHidden = true
        
        badgeStatusView.backgroundColor = .white
        badgeStatusView.layer.cornerRadius = badgeStatusView.frame.height / 2
        badgeStatusView.layer.borderColor = UIColor.white.cgColor
        badgeStatusView.layer.borderWidth = 2.0
        badgeStatusView.contentMode = .scaleAspectFit
        badgeStatusView.clipsToBounds = true
        
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
                
        mentionBadgeImageView.image = AmityIconSet.Chat.iconMentionBadges
        mentionBadgeImageView.isHidden = true
    }
    
    func display(with channel: AmityChannelModel, isOnline: Bool) {
        self.channel = channel
        
        statusImageView.isHidden = true
        badgeView.badge = channel.unreadCount
        memberLabel.text = ""
        dateTimeLabel.text = AmityDateFormatter.Chat.getDate(date: channel.lastActivity)
        titleLabel.text = channel.displayName
//        avatarView.placeholder = AmityIconSet.defaultAvatar
        mentionBadgeImageView.isHidden = !channel.object.hasMentioned
        badgeView.isHidden = channel.unreadCount < 1

        switch channel.channelType {
        case .standard:
            avatarView.setImage(withImageURL: channel.avatarURL)
            avatarView.placeholder = AmityIconSet.defaultGroupChat
            memberLabel.text = "(\(channel.memberCount))"
            statusBadgeImageView.isHidden = true
            badgeStatusView.isHidden = true
            badgeStatusView.backgroundColor = .clear
        case .conversation:
            memberLabel.text = nil
            statusBadgeImageView.isHidden = false
            badgeStatusView.isHidden = false
            badgeStatusView.backgroundColor = .white
            iconImageView.isHidden = true
            avatarView.placeholder = AmityIconSet.defaultAvatar

            // Set avatar
            avatarView.setImage(withImageURL: channel.userInfo?.getAvatarInfo()?.fileURL)
            titleLabel.text = channel.userInfo?.displayName
            let status = channel.userInfo?.metadata?["user_presence"] as? String ?? "available"
            if status != "available" {
                statusBadgeImageView.image = setImageFromStatus(status)
            } else {
                if isOnline {
                    statusBadgeImageView.image = AmityIconSet.Chat.iconOnlineIndicator
                } else {
                    statusBadgeImageView.image = AmityIconSet.Chat.iconOfflineIndicator
                }
            }
        case .community, .live:
            avatarView.setImage(withImageURL: channel.avatarURL)
            avatarView.placeholder = AmityIconSet.defaultGroupChat
            memberLabel.text = "(\(channel.memberCount))"
            statusBadgeImageView.isHidden = true
            badgeStatusView.isHidden = true
            badgeStatusView.backgroundColor = .clear
            iconImageView.isHidden = false
            var iconBadge = AmityIconSet.Chat.iconPublicBadge
            if !channel.object.isPublic {
                iconBadge = AmityIconSet.Chat.iconPrivateBadge
            }
            iconImageView.image = iconBadge
        case .private, .broadcast, .unknown:
            break
        @unknown default:
            break
        }
        
        if let previewMessage = channel.previewMessage {
            //  You can access data of preview message in same way as AmityMessage
            let text = previewMessage.data?["text"] as? String ?? "No message yet"
            let type = previewMessage.dataType

            var displayName: String = ""
            if let previewUserID = previewMessage.user?.userId, previewUserID == AmityUIKitManager.client.currentUserId, type != .custom {
                displayName = "You: "
            }
            
            switch type {
            case .text:
                displayName += text
            case .custom:
                displayName += text
            case .file:
                displayName += "Sent a file"
            case .video:
                displayName += "Sent a video"
            case .image:
                displayName += "Sent an image"
            case .audio:
                displayName += "Sent a voice message"
            default:
                displayName += "No message yet"
            }
            
            previewMessageLabel.text = displayName
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
        case "in_the_office":
            return AmityIconSet.Chat.iconStatusInTheOffice ?? UIImage()
        default:
            return AmityIconSet.Chat.iconOfflineIndicator ?? UIImage()
        }
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
