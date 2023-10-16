//
//  AmitySelectChannelListTableViewCell.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 16/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

final class AmitySelectChannelListTableViewCell: UITableViewCell {

    // MARK: - IBOutlet Properties
    @IBOutlet var avatarView: AmityAvatarView!
    @IBOutlet var displayNameLabel: UILabel!
    @IBOutlet var radioImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
   
    override func prepareForReuse() {
        super.prepareForReuse()
        
        displayNameLabel.text = ""
        radioImageView.image = AmityIconSet.iconRadioOff
        radioImageView.isHidden = false
        avatarView.image = nil
        avatarView.placeholder = AmityIconSet.defaultAvatar
    }
    
    private func setupView() {
        
        selectionStyle = .none
        avatarView.isUserInteractionEnabled = false
        displayNameLabel.text = ""
        displayNameLabel.textColor = AmityColorSet.base
        displayNameLabel.font = AmityFontSet.bodyBold

        radioImageView.image = AmityIconSet.iconRadioOff
    }
    
    func display(with channel: AmitySelectChannelModel) {
        displayNameLabel.text = channel.displayName
        radioImageView.image = channel.isSelected ? AmityIconSet.iconRadioCheck : AmityIconSet.iconRadioCheckOff
        avatarView.setImage(withImageURL: channel.avatarURL, placeholder: AmityIconSet.defaultAvatar)
    }
    
}
