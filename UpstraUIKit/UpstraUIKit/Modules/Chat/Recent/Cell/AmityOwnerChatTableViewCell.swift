//
//  AmityOwnerChatTableViewCell.swift
//  AmityUIKit
//
//  Created by PrInCeInFiNiTy on 10/3/23.
//  Copyright © 2023 Amity. All rights reserved.
//

import UIKit
import AmitySDK

public protocol AmityOwnerChatTableViewCellDelegate: AnyObject {
    func didTapAvatar()
}

class AmityOwnerChatTableViewCell: UITableViewCell, Nibbable {
    
    @IBOutlet private var avatarView: AmityAvatarView!
    @IBOutlet private var badgeStatusIcon: UIImageView!
    @IBOutlet private var badgeStatusView: UIView!
    @IBOutlet private var statusLabel: UILabel!
    @IBOutlet private var chevonIcon: UIImageView!
    @IBOutlet private var avatarButton: UIButton!
    
    var delegate: AmityOwnerChatTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    
    private func setupView() {
        avatarView.placeholder = AmityIconSet.defaultAvatar
        statusLabel.font = AmityFontSet.body
        
        chevonIcon.image = AmityIconSet.iconChevonRight
        
        badgeStatusView.backgroundColor = .white
        badgeStatusView.layer.cornerRadius = badgeStatusView.frame.height / 2
        badgeStatusView.layer.borderColor = UIColor.white.cgColor
        badgeStatusView.layer.borderWidth = 2.0
        badgeStatusView.contentMode = .scaleAspectFit
        badgeStatusView.clipsToBounds = true
        
        avatarButton.setTitle("", for: .normal)
    }
    
    func setupDisplay() {
        avatarView.setImage(withImageURL:  AmityUIKitManagerInternal.shared.avatarURL, placeholder: AmityIconSet.defaultAvatar)
        statusLabel.text = setTextFromStatus()
        badgeStatusIcon.image = setImageFromStatus()
    }
    
    private func setImageFromStatus() -> UIImage {
        let userStatus = AmityUserStatus()
        let currentStatus = AmityUIKitManagerInternal.shared.currentStatus
        let status = userStatus.mapAmitySDKToType(currentStatus)
        AmityUIKitManagerInternal.shared.userStatus = status

        switch status {
        case .AVAILABLE:
            return AmityIconSet.Chat.iconOnlineIndicator ?? UIImage()
        case .DO_NOT_DISTURB:
            return AmityIconSet.Chat.iconStatusDoNotDisTurb ?? UIImage()
        case .IN_THE_OFFICE:
            return AmityIconSet.Chat.iconStatusInTheOffice ?? UIImage()
        case .WORK_FROM_HOME:
            return AmityIconSet.Chat.iconStatusWorkFromHome ?? UIImage()
        case .IN_A_MEETING:
            return AmityIconSet.Chat.iconStatusInAMeeting ?? UIImage()
        case .ON_LEAVE:
            return AmityIconSet.Chat.iconStatusOnLeave ?? UIImage()
        case .OUT_SICK:
            return AmityIconSet.Chat.iconStatusOutSick ?? UIImage()
        default:
            return UIImage()
        }
    }
    
    private func setTextFromStatus() -> String {
        let amityUserStatus = AmityUserStatus()
        let currentStatus = amityUserStatus.mapAmitySDKToType(AmityUIKitManagerInternal.shared.currentStatus)
        switch currentStatus {
        case .AVAILABLE:
            return "Available"
        case .DO_NOT_DISTURB:
            return "Do not disturb"
        case .IN_THE_OFFICE:
            return "In the office"
        case .WORK_FROM_HOME:
            return "Work from home"
        case .IN_A_MEETING:
            return "In a meeting"
        case .ON_LEAVE:
            return "On leave"
        case .OUT_SICK:
            return "Out sick"
        default:
            return ""
        }
    }
    
    @IBAction func avatarViewTap() {
        delegate?.didTapAvatar()
    }
}
