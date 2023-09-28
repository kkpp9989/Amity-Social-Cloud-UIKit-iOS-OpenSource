//
//  AmityMessageListHeaderView.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 1/11/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit
import AmitySDK

final class AmityMessageListHeaderView: AmityView {
    
    // MARK: - Properties
    @IBOutlet private var avatarView: AmityAvatarView!
    @IBOutlet private var displayNameLabel: UILabel!
    @IBOutlet private var backButton: UIButton!
    
    // MARK: - Custom For ONE Krungthai Properties
    @IBOutlet var memberCount: UILabel!
    @IBOutlet var statusView: UIStackView!
    @IBOutlet var statusImageView: UIImageView!
    @IBOutlet var statusNameLabel: UILabel!
    
    // MARK: - Collections
    private var repository: AmityUserRepository?
    private var token: AmityNotificationToken?
    
    // MARK: - Properties
    private var screenViewModel: AmityMessageListScreenViewModelType?

    convenience init(viewModel: AmityMessageListScreenViewModelType) {
        self.init(frame: .zero)
        loadNibContent()
        screenViewModel = viewModel
        setupView()
    }
}

// MARK: - Action
private extension AmityMessageListHeaderView {
    @IBAction func backTap() {
        screenViewModel?.action.route(for: .pop)
    }
}

private extension AmityMessageListHeaderView {
    func setupView() {
        repository = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
        
        /* [Custom for ONE Krungthai] Change background color of view to clear for use background of navigation bar */
        // [Original]
//        contentView.backgroundColor = AmityColorSet.backgroundColor
        contentView.backgroundColor = .clear
        
        backButton.tintColor = AmityColorSet.base
        backButton.setImage(AmityIconSet.iconBackNavigationBar, for: .normal)
        
        displayNameLabel.textColor = AmityColorSet.base
        displayNameLabel.font = AmityFontSet.bodyBold
        displayNameLabel.text = nil
        
        avatarView.image = nil
        avatarView.placeholder = AmityIconSet.defaultAvatar
        
        /* [Custom for ONE Krungthai] Setup custom properties */
        // Member count
        memberCount.textColor = UIColor(hex: "636878")
        memberCount.font = AmityFontSet.caption
        memberCount.text = nil
        memberCount.isHidden = true
        
        // Status View
        statusView.isHidden = true
        statusImageView.image = nil
        statusNameLabel.textColor = UIColor(hex: "636878")
        statusNameLabel.font = AmityFontSet.caption
        statusNameLabel.text = nil
    }
    
}

extension AmityMessageListHeaderView {
    
    func updateViews(channel: AmityChannelModel) {
        displayNameLabel.text = channel.displayName
        switch channel.channelType {
        case .standard:
            avatarView.setImage(withImageURL: channel.avatarURL, placeholder: AmityIconSet.defaultGroupChat)
            
            /* [Custom for ONE Krungthai] Show member count and hide status view for group chat */
            memberCount.text = "\(channel.memberCount) \(channel.memberCount > 1 ? "members" : "member")"
            memberCount.isHidden = false
            statusView.isHidden = true
        case .conversation:
            // [Original]
//            avatarView.setImage(withImageURL: channel.avatarURL, placeholder: AmityIconSet.defaultAvatar)
//            if !channel.getOtherUserId().isEmpty {
//                token?.invalidate()
//                token = repository?.getUser(channel.getOtherUserId()).observeOnce { [weak self] user, error in
//                    guard let weakSelf = self else { return }
//                    if let userObject = user.object {
//                        weakSelf.displayNameLabel.text = userObject.displayName
//                    }
//                }
//            }
            /* [Custom for ONE Krungthai] Get other user by membership in SDK */
            AmityMemberChatUtilities.Conversation.getOtherUserByMemberShip(channelId: channel.channelId) { user in
                DispatchQueue.main.async { [self] in
                    if let otherMember = user {
                        // Set avatar
                        avatarView.setImage(withImageURL: otherMember.getAvatarInfo()?.fileURL, placeholder: AmityIconSet.defaultAvatar)
                        // Set displayName
                        displayNameLabel.text = otherMember.displayName
                        // Set user status and show its | [Temp] Mock to Available
                        updateUserStatus(user: otherMember)
                        // Hide member count because it's 1:1 Chat
                        memberCount.isHidden = true
                    }
                }
            }

        case .community:
            avatarView.setImage(withImageURL: channel.avatarURL, placeholder: AmityIconSet.defaultGroupChat)
            
            /* [Custom for ONE Krungthai] Show member count and hide status view for group chat */
            memberCount.text = "\(channel.memberCount) \(channel.memberCount > 1 ? "members" : "member")"
            memberCount.isHidden = false
            statusView.isHidden = true
        default:
            break
        }
    }
    
    func updateUserStatus(user: AmityUser) {
        // Show status view
        statusView.isHidden = false
        // [Temp] Mock status
        let status: AmityMemberChatStatus = .available
        switch status {
        case .available:
            statusImageView.image = AmityIconSet.Chat.iconStatusAvailable
            statusNameLabel.text = AmityLocalizedStringSet.ChatStatus.available.localizedString
        case .offline:
            statusImageView.image = AmityIconSet.Chat.iconStatusOffline
            statusNameLabel.text = AmityLocalizedStringSet.ChatStatus.offline.localizedString
        case .doNotDisturb:
            statusImageView.image = AmityIconSet.Chat.iconStatusDoNotDisTurb
            statusNameLabel.text = AmityLocalizedStringSet.ChatStatus.doNotDisturb.localizedString
        case .inTheOffice:
            statusImageView.image = AmityIconSet.Chat.iconStatusInTheOffice
            statusNameLabel.text = AmityLocalizedStringSet.ChatStatus.inTheOffice.localizedString
        case .workFromHome:
            statusImageView.image = AmityIconSet.Chat.iconStatusWorkFromHome
            statusNameLabel.text = AmityLocalizedStringSet.ChatStatus.workFromHome.localizedString
        case .inAMeeting:
            statusImageView.image = AmityIconSet.Chat.iconStatusInAMeeting
            statusNameLabel.text = AmityLocalizedStringSet.ChatStatus.inAMeeting.localizedString
        case .onLeave:
            statusImageView.image = AmityIconSet.Chat.iconStatusOnLeave
            statusNameLabel.text = AmityLocalizedStringSet.ChatStatus.onLeave.localizedString
        case .outSick:
            statusImageView.image = AmityIconSet.Chat.iconStatusOutSick
            statusNameLabel.text = AmityLocalizedStringSet.ChatStatus.outSick.localizedString
        }
        
    }
}
