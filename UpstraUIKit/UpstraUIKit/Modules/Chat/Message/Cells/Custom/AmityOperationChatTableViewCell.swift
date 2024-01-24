//
//  AmityOperationChatTableViewCell.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 10/11/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

final class AmityOperationChatTableViewCell: UITableViewCell, AmityMessageCellProtocol {
    // MARK: - Constant
    enum Constant {
        static let maximumLines: Int = 0
    }
    
    // MARK: - Component
    @IBOutlet var textMessageView: UILabel!
    @IBOutlet var containerView: UIView!
    @IBOutlet var stackView: UIStackView!
    
    // MARK: - Properties
    var message: AmityMessageModel?
    var channelType: AmityChannelType?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override func prepareForReuse() {
        textMessageView.text = ""
        containerView.layer.cornerRadius = 0
        containerView.layer.masksToBounds = true
    }
    
    func setupView() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        containerView.backgroundColor = AmityColorSet.secondary.blend(.shade4)
        containerView.layer.cornerRadius = 0
        containerView.layer.masksToBounds = true
        isUserInteractionEnabled = false
        
        textMessageView.textColor = AmityColorSet.base
        textMessageView.font = AmityFontSet.caption
        textMessageView.numberOfLines = Constant.maximumLines
        textMessageView.lineBreakMode = .byWordWrapping
        textMessageView.textAlignment = .center
        textMessageView.backgroundColor = .clear
        containerView.sizeToFit()
    }
    
    func display(message: AmityMessageModel) {
        self.message = message
        guard let text = message.text else { return }
        textMessageView.text = text
        containerView.layer.cornerRadius = contentView.frame.height / 3
        containerView.layer.masksToBounds = true
    }
    
    func displaySelected(isSelected: Bool) {
        // Not use in custom message
    }
    
    func setChannelType(channelType: AmitySDK.AmityChannelType) {
        self.channelType = channelType
    }
    
    static func height(for message: AmityMessageModel, boundingWidth: CGFloat) -> CGFloat {
        guard let text = message.text else { return UITableView.automaticDimension }
        let boundingWidthWithMargin = boundingWidth - 24 - 24 // Delete left & right margin
        let numberOfLines = text.numberOfLines(withConstrainedWidth: boundingWidthWithMargin, font: AmityFontSet.caption)

        if numberOfLines > 1 {
            return UITableView.automaticDimension
        } else {
            let textHeight = text.height(withConstrainedWidth: boundingWidthWithMargin, font: AmityFontSet.caption)
            return textHeight + 8 // Adjust as needed for additional spacing
        }
    }
}
