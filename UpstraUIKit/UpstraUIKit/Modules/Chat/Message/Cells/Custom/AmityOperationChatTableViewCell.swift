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
        static let maximumLines: Int = 1
        static let height: CGFloat = 25
    }
    
    // MARK: - Component
    @IBOutlet var textMessageView: UILabel!
    @IBOutlet var containerView: UIView!
    
    // MARK: - Properties
    var message: AmityMessageModel?
    var channelType: AmityChannelType?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override func prepareForReuse() {
        textMessageView.text = ""
    }
    
    func setupView() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        containerView.backgroundColor = AmityColorSet.secondary.blend(.shade4)
        containerView.layer.cornerRadius = containerView.frame.height / 2
        isUserInteractionEnabled = false
        
        textMessageView.textColor = AmityColorSet.base
        textMessageView.font = AmityFontSet.caption
    }
    
    func display(message: AmityMessageModel) {
        guard let text = message.text else { return }
        self.message = message
        
        textMessageView.text = text
    }
    
    func setChannelType(channelType: AmitySDK.AmityChannelType) {
        self.channelType = channelType
    }
    
    static func height(for message: AmityMessageModel, boundingWidth: CGFloat) -> CGFloat {
        return Constant.height
    }
    
}
