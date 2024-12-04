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
        
        var height: CGFloat = 0
        let maximumLines = 2
        if let fileInfo = message.object.getFileInfo() {
            let file = AmityFile(state: .downloadable(fileData: fileInfo))
            let messageHeight = AmityExpandableLabel.height(for: file.fileName, font: AmityFontSet.bodyBold, boundingWidth: boundingWidth, maximumLines: maximumLines)
            height += messageHeight
        }
        
        return 152 + displaynameHeight + height
    }
    
}
