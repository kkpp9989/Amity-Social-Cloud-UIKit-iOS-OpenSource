//
//  AmityLocationTableViewCell.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 5/6/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import UIKit

class AmityLocationTableViewCell: AmityMessageTableViewCell {
    
    enum Constant {
        static let maximumLines: Int = 2
        static let textMessageFont = AmityFontSet.body
        static let spaceOfStackWithinContainerMessageView = 4.0
    }
    
    @IBOutlet weak var addressLabel: AmityExpandableLabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
//        messageImageView.image = AmityIconSet.defaultMessageImage
        messageImageView.contentMode = .scaleAspectFill
        addressLabel.text = nil
    }
    
    func setupView() {
        // Setup text caption view
        addressLabel.text = ""
        addressLabel.textAlignment = .left
        addressLabel.numberOfLines = Constant.maximumLines
        addressLabel.font = Constant.textMessageFont
        addressLabel.backgroundColor = .clear
        
        // Setup image view
        messageImageView.image = AmityIconSet.Chat.iconLocationPlaceholder
        messageImageView.contentMode = .scaleAspectFill
        messageImageView.layer.cornerRadius = 4
        let tapGesuter = UITapGestureRecognizer(target: self, action: #selector(imageViewTap))
        tapGesuter.numberOfTouchesRequired = 1
        messageImageView.isUserInteractionEnabled = true
        messageImageView.addGestureRecognizer(tapGesuter)
    }
    
    override func display(message: AmityMessageModel) {
        super.display(message: message)
        
        // Display text
        if let tableBoundingWidth = tableBoundingWidth {
            addressLabel.preferredMaxLayoutWidth = actualWidth(for: message, boundingWidth: tableBoundingWidth)
        }
        
        if let location  = message.data?["location"] as? [String: Any], let address = location["address"] as? String, !address.isEmpty {
            addressLabel.text = address
        }
    }
    
    override class func height(for message: AmityMessageModel, boundingWidth: CGFloat) -> CGFloat {
        if message.isDeleted {
            let displaynameHeight: CGFloat = message.isOwner ? 0 : 46
            return AmityMessageTableViewCell.deletedMessageCellHeight + displaynameHeight
        }
        
        var height: CGFloat = 0
        var actualWidth: CGFloat = 0
        
        // for cell layout and calculation, please go check this pull request https://github.com/EkoCommunications/EkoMessagingSDKUIKitIOS/pull/713
        if message.isOwner {
            let horizontalPadding: CGFloat = 112
            actualWidth = boundingWidth - horizontalPadding
            
            let verticalPadding: CGFloat = 64
            height += verticalPadding
        } else {
            let horizontalPadding: CGFloat = 164
            actualWidth = boundingWidth - horizontalPadding
            
            let verticalPadding: CGFloat = 98
            height += verticalPadding
        }
        
        if let location  = message.data?["location"] as? [String: Any], let text = location["address"] as? String, !text.isEmpty {
            let maximumLines = Constant.maximumLines
            let messageHeight = AmityExpandableLabel.height(for: text, font: Constant.textMessageFont, boundingWidth: actualWidth, maximumLines: maximumLines)
            height += messageHeight
        }
        
        height += actualWidth + 12 // height is equal actualwidth because must to set image ratio 1:1 | 12 is spacing between image and caption
        
        return height
    }
    
    private func actualWidth(for message: AmityMessageModel, boundingWidth: CGFloat) -> CGFloat {
        var actualWidth: CGFloat = 0
        
        // for cell layout and calculation, please go check this pull request https://github.com/EkoCommunications/EkoMessagingSDKUIKitIOS/pull/713
        if message.isOwner {
            let horizontalPadding: CGFloat = 112
            actualWidth = boundingWidth - horizontalPadding
        } else {
            let horizontalPadding: CGFloat = 164
            actualWidth = boundingWidth - horizontalPadding
        }
        
        return actualWidth
    }
}

private extension AmityLocationTableViewCell {
    @objc
    func imageViewTap() {
        if messageImageView.image != AmityIconSet.defaultMessageImage {
            screenViewModel.action.performCellEvent(for: .imageViewer(indexPath: indexPath, imageView: messageImageView))
        }
    }
}
