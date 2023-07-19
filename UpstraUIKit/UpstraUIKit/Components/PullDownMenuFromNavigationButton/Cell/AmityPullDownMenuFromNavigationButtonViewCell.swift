//
//  AmityPullDownMenuFromNavigationButtonViewCell.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 19/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

class AmityPullDownMenuFromNavigationButtonViewCell: UITableViewCell, Nibbable {
    
    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var itemName: UILabel!
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func display(item: AmityPullDownMenuItem) {
        /* Set text */
        itemName.text = item.name
        itemName.font = AmityFontSet.bodyBold
        
        /* Set image */
        itemImage.image = item.image
    }
}
