//
//  AmityReactionPickerCollectionViewCell.swift
//  AmityUIKit
//
//  Created by Teeraphan on 13/7/23.
//

import UIKit
import AmityUIKit

class AmityReactionPickerCollectionViewCell: UICollectionViewCell, Nibbable {

    @IBOutlet weak var reactionImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func display(_ type: AmityReactionType) {
        
        switch type {
        case .create:
            reactionImageView.image = AmityIconSet.iconDNASangsun
        case .honest:
            reactionImageView.image = AmityIconSet.iconDNASatsue
        case .harmony:
            reactionImageView.image = AmityIconSet.iconDNASamakki
        case .success:
            reactionImageView.image = AmityIconSet.iconDNASumrej
        case .society:
            reactionImageView.image = AmityIconSet.iconDNASangkom
        case .like:
            reactionImageView.image = AmityIconSet.iconDNALike
        case .love:
            reactionImageView.image = AmityIconSet.iconDNALove
        }
    }
}
