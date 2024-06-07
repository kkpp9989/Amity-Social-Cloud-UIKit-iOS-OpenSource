//
//  AmityMessageFileIncomingTableViewCell.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 11/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

final class AmityMessageFileIncomingTableViewCell: AmityMessageFileTableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func display(message: AmityMessageModel) {
        super.display(message: message)
    }
    
    override class func height(for message: AmityMessageModel, boundingWidth: CGFloat) -> CGFloat {
        let displaynameHeight: CGFloat = message.isOwner ? 0 : 10
        if message.isDeleted {
            return AmityMessageTableViewCell.deletedMessageCellHeight + displaynameHeight + 36
        }
        return 152 + displaynameHeight
    }
    
}
