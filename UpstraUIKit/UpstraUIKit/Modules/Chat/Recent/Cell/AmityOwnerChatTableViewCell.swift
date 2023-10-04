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
    private var repository: AmityUserRepository?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    private func setupView() {
        repository = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
        avatarView.placeholder = AmityIconSet.defaultAvatar
    }
    
    func setupDisplay() {
        avatarView.setImage(withImageURL:  AmityUIKitManagerInternal.shared.avatarURL, placeholder: AmityIconSet.defaultAvatar)
    }
    
}
