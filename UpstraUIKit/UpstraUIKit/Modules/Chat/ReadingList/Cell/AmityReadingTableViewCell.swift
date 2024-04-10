//
//  AmityReadingTableViewCell.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 8/12/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

class AmityReadingTableViewCell: UITableViewCell, Nibbable {
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var avatarView: AmityAvatarView!
    @IBOutlet private var displayNameLabel: UILabel!
    
    // MARK: - Properties
    
    private var indexPath: IndexPath!
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    func display(with model: AmityUserModel) {
        let displayName = model.displayName
        avatarView.setImage(withImageURL: model.avatarURL, placeholder: AmityIconSet.defaultAvatar)
        displayNameLabel.text = (displayName)
    }
}

private extension AmityReadingTableViewCell {
    func setupView() {
        selectionStyle = .none
        backgroundColor = AmityColorSet.backgroundColor
        contentView.backgroundColor = AmityColorSet.backgroundColor
        setupAvatarView()
        setupDisplayName()
    }
    
    func setupAvatarView() {
        avatarView.backgroundColor = AmityColorSet.secondary.blend(.shade4)
        avatarView.placeholder = AmityIconSet.defaultAvatar
    }
    
    func setupDisplayName() {
        displayNameLabel.text = ""
        displayNameLabel.font = AmityFontSet.bodyBold
        displayNameLabel.textColor = AmityColorSet.base
    }
    
}
