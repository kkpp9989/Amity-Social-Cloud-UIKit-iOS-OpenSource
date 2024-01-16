//
//  AmityMessageImageWithCaptionTableViewCell.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 16/1/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import UIKit

class AmityMessageImageWithCaptionTableViewCell: AmityMessageTableViewCell {
    
    enum Constant {
        static let maximumLines: Int = 8
        static let textMessageFont = AmityFontSet.bodyBold
        static let spaceOfStackWithinContainerMessageView = 4.0
    }
    
    @IBOutlet private var textCaptionView: AmityExpandableLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        messageImageView.image = AmityIconSet.defaultMessageImage
        messageImageView.contentMode = .center
        textCaptionView.text = nil
        textCaptionView.isExpanded = false
    }

    func setupView() {
        // Setup text caption view
        textCaptionView.text = ""
        textCaptionView.textAlignment = .left
        textCaptionView.numberOfLines = Constant.maximumLines
        textCaptionView.isExpanded = false
        textCaptionView.font = Constant.textMessageFont
        textCaptionView.backgroundColor = .clear
        textCaptionView.delegate = self
        
        // Setup image view
        messageImageView.contentMode = .center
        messageImageView.layer.cornerRadius = 4
        let tapGesuter = UITapGestureRecognizer(target: self, action: #selector(imageViewTap))
        tapGesuter.numberOfTouchesRequired = 1
        messageImageView.isUserInteractionEnabled = true
        messageImageView.addGestureRecognizer(tapGesuter)
    }
    
    override func display(message: AmityMessageModel) {
        super.display(message: message)
        // Display text
        var highlightColor = AmityColorSet.primary
        if message.isOwner {
            if AmityColorSet.messageBubble == (UIColor(hex: "B2EAFF", alpha: 1.0)) {
                // [Custom for ONE Krungthai] Change color style for color "B2EAFF" of message bubble
                textCaptionView.textColor = AmityColorSet.base
                textCaptionView.readMoreColor = AmityColorSet.highlight
                textCaptionView.hyperLinkColor = AmityColorSet.highlight
            } else {
                // [Original]
                textCaptionView.textColor = AmityColorSet.baseInverse
                textCaptionView.readMoreColor = AmityColorSet.baseInverse
                textCaptionView.hyperLinkColor = AmityColorSet.highlight
            }
            highlightColor = AmityColorSet.highlight
        } else {
            textCaptionView.textColor = AmityColorSet.base
            textCaptionView.readMoreColor = AmityColorSet.highlight
            textCaptionView.hyperLinkColor = AmityColorSet.highlight
            highlightColor = AmityColorSet.primary
        }
        
        // Set boardcast message bubble style if channel type is boardcast
        if channelType == .broadcast {
            containerView.backgroundColor = AmityColorSet.messageBubbleBoardcast
            // Change text color
            textCaptionView.textColor = AmityColorSet.baseInverse
            textCaptionView.readMoreColor = AmityColorSet.highlightMessageBoardcast
            textCaptionView.hyperLinkColor = AmityColorSet.highlightMessageBoardcast
            highlightColor = AmityColorSet.highlightMessageBoardcast
        }
        
        let mentionees = message.mentionees ?? []
        let text = message.imageCaption ?? ""
        if let metadata = message.metadata {
            if let tableBoundingWidth = tableBoundingWidth {
                textCaptionView.preferredMaxLayoutWidth = actualWidth(for: message, boundingWidth: tableBoundingWidth)
            }
            textCaptionView.setText(
                text,
                withAttributes: AmityMentionManager.getAttributes(
                    fromText: text,
                    withMetadata: metadata,
                    mentionees: mentionees,
                    highlightColor: highlightColor
                )
            )
        } else {
            if let tableBoundingWidth = tableBoundingWidth {
                textCaptionView.preferredMaxLayoutWidth = actualWidth(for: message, boundingWidth: tableBoundingWidth)
            }
            textCaptionView.text = text
        }

        textCaptionView.isExpanded = message.appearance.isExpanding
        
        // Display image
        if !message.isDeleted {
            let indexPath = self.indexPath
            AmityUIKitManagerInternal.shared.messageMediaService.downloadImageForMessage(message: message.object, size: .medium) { [weak self] in
                self?.messageImageView.image = AmityIconSet.defaultMessageImage
            } completion: { [weak self] result in
                switch result {
                case .success(let image):
                    // To check if the image going to assign has the correct index path.
                    if indexPath == self?.indexPath {
                        self?.messageImageView.image = image
                        self?.messageImageView.contentMode = .scaleAspectFill
                    }
                case .failure:
                    self?.messageImageView.image = AmityIconSet.defaultMessageImage
                    self?.metadataLabel.isHidden = false
                    self?.messageImageView.contentMode = .center
                }
            }
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
            let horizontalPadding: CGFloat = 132
            actualWidth = boundingWidth - horizontalPadding
            
            let verticalPadding: CGFloat = 84
            height += verticalPadding
        } else {
            let horizontalPadding: CGFloat = 164
            actualWidth = boundingWidth - horizontalPadding
            
            let verticalPadding: CGFloat = 98
            height += verticalPadding
        }
        
        if let text = message.imageCaption {
            let maximumLines = message.appearance.isExpanding ? 0 : Constant.maximumLines
            let messageHeight = AmityExpandableLabel.height(for: text, font: Constant.textMessageFont, boundingWidth: actualWidth, maximumLines: maximumLines)
            height += messageHeight
        }
        
        height += 132 // Add height of image view with padding (120 + 12)
        
        return height
        
    }
    
    private func actualWidth(for message: AmityMessageModel, boundingWidth: CGFloat) -> CGFloat {
        var actualWidth: CGFloat = 0
        
        // for cell layout and calculation, please go check this pull request https://github.com/EkoCommunications/EkoMessagingSDKUIKitIOS/pull/713
        if message.isOwner {
            let horizontalPadding: CGFloat = 132
            actualWidth = boundingWidth - horizontalPadding
        } else {
            let horizontalPadding: CGFloat = 164
            actualWidth = boundingWidth - horizontalPadding
        }
        
        return actualWidth
    }
}

extension AmityMessageImageWithCaptionTableViewCell: AmityExpandableLabelDelegate {
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

private extension AmityMessageImageWithCaptionTableViewCell {
    @objc
    func imageViewTap() {
        if messageImageView.image != AmityIconSet.defaultMessageImage {
            screenViewModel.action.performCellEvent(for: .imageViewer(indexPath: indexPath, imageView: messageImageView))
        }
    }
}
