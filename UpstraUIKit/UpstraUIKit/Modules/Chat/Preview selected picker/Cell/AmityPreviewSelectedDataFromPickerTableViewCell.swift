//
//  AmityPreviewSelectedDataFromPickerTableViewCell.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 1/2/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import UIKit

class AmityPreviewSelectedDataFromPickerTableViewCell: UITableViewCell, Nibbable {
    
    // MARK: - IBOutlet Properties
    @IBOutlet weak var avatarView: AmityAvatarView!
    @IBOutlet weak var displayNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
   
    override func prepareForReuse() {
        super.prepareForReuse()
        
        displayNameLabel.text = ""
        avatarView.image = nil
        avatarView.placeholder = AmityIconSet.defaultAvatar
    }
    
    private func setupView() {
        selectionStyle = .none
        avatarView.isUserInteractionEnabled = false
        displayNameLabel.text = ""
        displayNameLabel.textColor = AmityColorSet.base
        displayNameLabel.font = AmityFontSet.bodyBold
        
        isUserInteractionEnabled = false
    }
    
    func display(with user: AmitySelectMemberModel) {
        displayNameLabel.text = user.displayName ?? user.defaultDisplayName
        avatarView.setImage(withImageURL: user.avatarURL, placeholder: AmityIconSet.defaultAvatar)
    }
    
}
