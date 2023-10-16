//
//  AmityMessageReplyTableViewCell.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 15/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

class AmityMessageReplyTableViewCell: AmityMessageTableViewCell {
    
    enum Constant {
        static let maximumLines: Int = 8
        static let textMessageFont = AmityFontSet.body
    }
    
    @IBOutlet private var textMessageView: AmityExpandableLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    private func setupView() {
        textMessageView.text = ""
        textMessageView.textAlignment = .left
        textMessageView.numberOfLines = Constant.maximumLines
        textMessageView.isExpanded = false
        textMessageView.font = Constant.textMessageFont
        textMessageView.backgroundColor = .clear
        textMessageView.delegate = self
    }
        
    override func display(message: AmityMessageModel) {
        super.display(message: message)
        var highlightColor = AmityColorSet.primary
        if message.isOwner {
            if AmityColorSet.messageBubble == (UIColor(hex: "B2EAFF", alpha: 1.0)) {
                // [Custom for ONE Krungthai] Change color style for color "B2EAFF" of message bubble
                textMessageView.textColor = AmityColorSet.base
                textMessageView.readMoreColor = AmityColorSet.highlight
                textMessageView.hyperLinkColor = AmityColorSet.highlight
            } else {
                // [Original]
                textMessageView.textColor = AmityColorSet.baseInverse
                textMessageView.readMoreColor = AmityColorSet.baseInverse
                textMessageView.hyperLinkColor = .white
            }
            highlightColor = .white
        } else {
            textMessageView.textColor = AmityColorSet.base
            textMessageView.readMoreColor = AmityColorSet.highlight
            textMessageView.hyperLinkColor = AmityColorSet.highlight
            highlightColor = AmityColorSet.primary
        }
        
        if let metadata = message.metadata,
           let mentionees = message.mentionees,
           let text = message.text {
            textMessageView.setText(
                text,
                withAttributes: AmityMentionManager.getAttributes(
                    fromText: text,
                    withMetadata: metadata,
                    mentionees: mentionees,
                    highlightColor: highlightColor
                )
            )
        } else {
            textMessageView.text = message.text
        }
        
        textMessageView.isExpanded = message.appearance.isExpanding
    }
    
    override class func height(for message: AmityMessageModel, boundingWidth: CGFloat) -> CGFloat {
        if message.isDeleted {
            let displaynameHeight: CGFloat = message.isOwner ? 0 : 22
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
        
        if let text = message.text {
            let maximumLines = message.appearance.isExpanding ? 0 : Constant.maximumLines
            let messageHeight = AmityExpandableLabel.height(for: text, font: Constant.textMessageFont, boundingWidth: actualWidth, maximumLines: maximumLines)
            height += messageHeight
        }
        
        return height
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        textMessageView.isExpanded = false
    }
}

extension AmityMessageReplyTableViewCell: AmityExpandableLabelDelegate {
    
    public func expandableLabeldidTap(_ label: AmityExpandableLabel) {
        delegate?.performEvent(self, labelEvents: .tapExpandableLabel(label: label))
    }
    
    public func willExpandLabel(_ label: AmityExpandableLabel) {
        delegate?.performEvent(self, labelEvents: .willExpandExpandableLabel(label: label))
    }
    
    public func didExpandLabel(_ label: AmityExpandableLabel) {
        delegate?.performEvent(self, labelEvents: .didExpandExpandableLabel(label: label))
    }
    
    public func willCollapseLabel(_ label: AmityExpandableLabel) {
        delegate?.performEvent(self, labelEvents: .willCollapseExpandableLabel(label: label))
    }
    
    public func didCollapseLabel(_ label: AmityExpandableLabel) {
        delegate?.performEvent(self, labelEvents: .didCollapseExpandableLabel(label: label))
    }
    
    func didTapOnMention(_ label: AmityExpandableLabel, withUserId userId: String) {
        delegate?.performEvent(self, labelEvents: .didTapOnMention(label: label, userId: userId))
    }
    
    func didTapOnHashtag(_ label: AmityExpandableLabel, withKeyword keyword: String, count: Int) {
    }
}