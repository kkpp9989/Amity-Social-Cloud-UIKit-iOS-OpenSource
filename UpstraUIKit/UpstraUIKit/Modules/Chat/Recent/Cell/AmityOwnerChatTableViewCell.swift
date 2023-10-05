//
//  AmityOwnerChatTableViewCell.swift
//  AmityUIKit
//
//  Created by PrInCeInFiNiTy on 10/3/23.
//  Copyright © 2023 Amity. All rights reserved.
//

import UIKit
import AmitySDK

class AmityOwnerChatTableViewCell: UITableViewCell, Nibbable {
    
    @IBOutlet private var avatarView: AmityAvatarView!
    @IBOutlet private var badgeStatusIcon: AmityAvatarView!
    @IBOutlet private var statusLabel: UILabel!
    private var repository: AmityUserRepository?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    private func setupView() {
        repository = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
        avatarView.placeholder = AmityIconSet.defaultAvatar
        statusLabel.font = AmityFontSet.body
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
            return AmityIconSet.Chat.iconStatusAvailable ?? UIImage()
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
        let currentStatus = AmityUIKitManagerInternal.shared.userStatus
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
}
