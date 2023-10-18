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
    @IBOutlet private var replyContainerView: UIView!
    @IBOutlet private var replyAvatarImageView: AmityAvatarView!
    @IBOutlet private var replyDisplayNameLabel: UILabel!
    @IBOutlet private var replyDescLabel: UILabel!
    @IBOutlet private var replyImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    private func setupView() {
        containerMessageView.backgroundColor = UIColor(hex: "#F0FBFF")
        containerMessageView.layer.cornerRadius = 12
        
        textMessageView.text = ""
        textMessageView.textAlignment = .left
        textMessageView.numberOfLines = Constant.maximumLines
        textMessageView.isExpanded = false
        textMessageView.font = Constant.textMessageFont
        textMessageView.backgroundColor = .clear
        textMessageView.delegate = self
        
        replyImageView.contentMode = .center
        replyImageView.layer.cornerRadius = 4
        
        replyDisplayNameLabel.font = AmityFontSet.body
        replyDisplayNameLabel.textColor = AmityColorSet.base.blend(.shade1)
        replyDescLabel.font = AmityFontSet.body
        replyDescLabel.textColor = AmityColorSet.base.blend(.shade2)

        replyImageView.isHidden = true
        
        let tapGesuter = UITapGestureRecognizer(target: self, action: #selector(replyContainerTap))
        tapGesuter.numberOfTouchesRequired = 1
        replyContainerView.isUserInteractionEnabled = true
        replyContainerView.addGestureRecognizer(tapGesuter)
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
        
        if let messageParent = message.parentMessageObjc {
            if !messageParent.isDeleted {
                switch messageParent.messageType {
                case .image:
                    let indexPath = self.indexPath
                    AmityUIKitManagerInternal.shared.messageMediaService.downloadImageForMessage(message: messageParent, size: .medium) { [weak self] in
                        self?.replyImageView.image = AmityIconSet.defaultMessageImage
                    } completion: { [weak self] result in
                        switch result {
                        case .success(let image):
                            // To check if the image going to assign has the correct index path.
                            if indexPath == self?.indexPath {
                                self?.replyImageView.image = image
                                self?.replyImageView.isHidden = false
                                self?.replyImageView.contentMode = .scaleAspectFill
                            }
                        case .failure:
                            self?.replyImageView.image = AmityIconSet.defaultMessageImage
                            self?.replyImageView.isHidden = false
                            self?.replyImageView.contentMode = .center
                        }
                    }
                    replyDescLabel.text = "Image"
                case .file:
                    if let fileInfo = messageParent.getFileInfo() {
                        let file = AmityFile(state: .downloadable(fileData: fileInfo))
                        if indexPath == self.indexPath {
                            // Set Icon
                            replyImageView.image = file.fileIcon
                            replyImageView.isHidden = false
                        }
                    }
                    replyDescLabel.text = "File"
                case .audio:
                    if message.isOwner {
                        if AmityColorSet.messageBubble == (UIColor(hex: "B2EAFF", alpha: 1.0)) {
                            // [Custom for ONE Krungthai] Change color style for color "B2EAFF" of message bubble
                            replyImageView.tintColor = AmityColorSet.base
                        } else {
                            // [Original]
                            replyImageView.tintColor = AmityColorSet.baseInverse
                        }
                    } else {
                        replyImageView.tintColor = AmityColorSet.base
                    }
                    
                    replyImageView.image = AmityIconSet.Chat.iconPlay
                    replyImageView.isHidden = false
                    replyDescLabel.text = "Voice message"
                case .video:
                    let indexPath = self.indexPath
                    if let thumbnailInfo = messageParent.getVideoThumbnailInfo() {
                        if indexPath == self.indexPath {
                            // Set video thumbnail
                            replyImageView.loadImage(with: thumbnailInfo.fileURL, size: .full, placeholder: AmityIconSet.videoThumbnailPlaceholder, optimisticLoad: true)
                            replyImageView.contentMode = .scaleAspectFill
                            replyImageView.isHidden = false

                            let imageView = UIImageView(image: UIImage(named: "play_livestream_button"))
                            imageView.frame = CGRect(x: self.replyImageView.bounds.midX, y: self.replyImageView.bounds.midY, width: 25, height: 25)
                            self.replyImageView.addSubview(imageView)
                        }
                    } else {
                        replyImageView.image = AmityIconSet.videoThumbnailPlaceholder
                        replyImageView.contentMode = .center
                        replyImageView.isHidden = false
                    }
                    replyDescLabel.text = "Video"
                case .text:
                    replyDescLabel.text = message.parentMessageObjc?.data?["text"] as? String
                default:
                    break
                }
            }
        }
        
        let url = message.parentMessageObjc?.user?.getAvatarInfo()?.fileURL
        replyAvatarImageView.setImage(withImageURL: url, placeholder: AmityIconSet.defaultAvatar)
        replyDisplayNameLabel.text = message.parentMessageObjc?.user?.displayName ?? "Anonymous"
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
            
            let replyHeight: CGFloat = 60
            height += replyHeight
        } else {
            let horizontalPadding: CGFloat = 164
            actualWidth = boundingWidth - horizontalPadding
            
            let verticalPadding: CGFloat = 98
            height += verticalPadding
            
            let replyHeight: CGFloat = 80
            height += replyHeight
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

extension AmityMessageReplyTableViewCell {
    @objc func replyContainerTap() {
        screenViewModel.action.performCellEvent(for: .reply(indexPath: indexPath))
    }
}
