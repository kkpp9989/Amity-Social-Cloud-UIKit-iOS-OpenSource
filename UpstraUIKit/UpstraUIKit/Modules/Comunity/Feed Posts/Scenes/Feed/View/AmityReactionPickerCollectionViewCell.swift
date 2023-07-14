//
//  AmityReactionPickerCollectionViewCell.swift
//  AmityUIKit
//
//  Created by Teeraphan on 13/7/23.
//

import UIKit

class AmityReactionPickerCollectionViewCell: UICollectionViewCell, Nibbable {

    @IBOutlet weak var reactionImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func display(_ type: AmityReactionType) {
        
        switch type {
        case .sangsun:
            reactionImageView.image = AmityIconSet.iconDNASangsun
        case .satsue:
            reactionImageView.image = AmityIconSet.iconDNASatsue
        case .samakki:
            reactionImageView.image = AmityIconSet.iconDNASamakki
        case .sumrej:
            reactionImageView.image = AmityIconSet.iconDNASumrej
        case .sangkom:
            reactionImageView.image = AmityIconSet.iconDNASangkom
        case .like:
            reactionImageView.image = AmityIconSet.iconDNALike
        case .love:
            reactionImageView.image = AmityIconSet.iconDNALove
        }
    }
}
