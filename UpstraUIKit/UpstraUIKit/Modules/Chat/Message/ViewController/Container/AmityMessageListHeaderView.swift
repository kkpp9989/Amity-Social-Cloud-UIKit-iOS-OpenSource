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
    
    func updateViews(channel: AmityChannelModel, isOnline: Bool) {
        switch channel.channelType {
        case .standard:
            avatarView.setImage(withImageURL: channel.avatarURL, placeholder: AmityIconSet.defaultGroupChat)
            
            displayNameLabel.text = channel.displayName
            
            /* [Custom for ONE Krungthai] Show member count and hide status view for group chat */
            memberCount.text = "\(channel.memberCount) \(channel.memberCount > 1 ? "members" : "member")"
            memberCount.isHidden = false
            statusView.isHidden = true
        case .conversation:
            getOtherUser(channel: channel) { user in
                DispatchQueue.main.async { [self] in
                    if let otherMember = user {
                        // Set avatar
                        avatarView.setImage(withImageURL: otherMember.getAvatarInfo()?.fileURL, placeholder: AmityIconSet.defaultAvatar)
                        // Set displayName
                        displayNameLabel.text = otherMember.displayName
                        // Set user status and show its | [Temp] Mock to Available
                        updateUserStatus(user: otherMember, isOnline: isOnline)
                        // Hide member count because it's 1:1 Chat
                        memberCount.isHidden = true
                    }
                }
            }
        case .community, .live:
            displayNameLabel.text = channel.displayName

            avatarView.setImage(withImageURL: channel.avatarURL, placeholder: AmityIconSet.defaultGroupChat)
            
            /* [Custom for ONE Krungthai] Show member count and hide status view for group chat */
            memberCount.text = "\(channel.memberCount) \(channel.memberCount > 1 ? "members" : "member")"
            memberCount.isHidden = false
            statusView.isHidden = true
        default:
            break
        }
    }
    
    func updateUserStatus(user: AmityUser, isOnline: Bool) {
        let status = user.metadata?["user_presence"] as? String ?? "available"
        switch status {
        case "available":
            if isOnline {
                statusImageView.image = AmityIconSet.Chat.iconStatusAvailable
                statusNameLabel.text = AmityLocalizedStringSet.ChatStatus.available.localizedString
            } else {
                statusImageView.image = AmityIconSet.Chat.iconOfflineIndicator
                statusNameLabel.text = AmityLocalizedStringSet.ChatStatus.offline.localizedString
            }
        case "do_not_disturb":
            statusImageView.image = AmityIconSet.Chat.iconStatusDoNotDisTurb
            statusNameLabel.text = AmityLocalizedStringSet.ChatStatus.doNotDisturb.localizedString
        case "in_the_office":
            statusImageView.image = AmityIconSet.Chat.iconStatusInTheOffice
            statusNameLabel.text = AmityLocalizedStringSet.ChatStatus.inTheOffice.localizedString
        case "work_from_home":
            statusImageView.image = AmityIconSet.Chat.iconStatusWorkFromHome
            statusNameLabel.text = AmityLocalizedStringSet.ChatStatus.workFromHome.localizedString
        case "in_a_meeting":
            statusImageView.image = AmityIconSet.Chat.iconStatusInAMeeting
            statusNameLabel.text = AmityLocalizedStringSet.ChatStatus.inAMeeting.localizedString
        case "on_leave":
            statusImageView.image = AmityIconSet.Chat.iconStatusOnLeave
            statusNameLabel.text = AmityLocalizedStringSet.ChatStatus.onLeave.localizedString
        case "out_sick":
            statusImageView.image = AmityIconSet.Chat.iconStatusOutSick
            statusNameLabel.text = AmityLocalizedStringSet.ChatStatus.outSick.localizedString
        default:
            statusImageView.image = AmityIconSet.Chat.iconOfflineIndicator
            statusNameLabel.text = AmityLocalizedStringSet.ChatStatus.offline.localizedString
        }
        // Show status view
        statusView.isHidden = false
    }
    
    func getOtherUser(channel: AmityChannelModel, completion: @escaping (_ user: AmityUser?) -> Void) {
        token?.invalidate()
        if !channel.getOtherUserId().isEmpty {
            token = repository?.getUser(channel.getOtherUserId()).observe({ [weak self] user, error in
                guard let weakSelf = self else { return }
                let userObject = user.snapshot
                weakSelf.token?.invalidate()
                completion(userObject)
            })
        }
    }
}
