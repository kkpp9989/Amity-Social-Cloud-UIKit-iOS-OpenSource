//
//  AmityMessageTableViewCell.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 7/8/2563 BE.
//  Copyright © 2563 Amity Communication. All rights reserved.
//

import UIKit
import AmitySDK

class AmityMessageTableViewCell: UITableViewCell, AmityMessageCellProtocol {
    
    static let deletedMessageCellHeight: CGFloat = 52
    
    // MARK: - Delegate
    weak var delegate: AmityMessageCellDelegate?
    
    // MARK: - IBOutlet Properties
    @IBOutlet var avatarView: AmityAvatarView!
    @IBOutlet var containerView: AmityResponsiveView!
    @IBOutlet var displayNameLabel: UILabel!
    @IBOutlet var metadataLabel: UILabel!
    @IBOutlet var readCountLabel: UILabel!
    @IBOutlet var messageImageView: UIImageView!
    @IBOutlet var statusMetadataImageView: UIImageView!
    @IBOutlet var errorButton: UIButton!
    @IBOutlet var reportIconImageView: UIImageView!

    // MARK: Container
    @IBOutlet var containerMessageView: UIView!
    @IBOutlet var containerMetadataView: UIView!
    var editMessageMenuView: AmityEditMenuView = AmityEditMenuView()
    
    // MARK: - Properties
    var screenViewModel: AmityMessageListScreenViewModelType!
    var message: AmityMessageModel!
    var channelType: AmityChannelType?
    
    var indexPath: IndexPath!
    let editMenuItem = UIMenuItem(title: AmityLocalizedStringSet.General.edit.localizedString, action: #selector(editTap))
    let deleteMenuItem = UIMenuItem(title: AmityLocalizedStringSet.General.unsend.localizedString, action: #selector(deleteTap))
    let reportMenuItem = UIMenuItem(title: AmityLocalizedStringSet.General.report.localizedString, action: #selector(reportTap))
    let forwardMenuItem = UIMenuItem(title: AmityLocalizedStringSet.General.forward.localizedString, action: #selector(forwardTap))
    let replyMenuItem = UIMenuItem(title: AmityLocalizedStringSet.General.reply.localizedString, action: #selector(replyTap))
    let copyMenuItem = UIMenuItem(title: AmityLocalizedStringSet.General.copy.localizedString, action: #selector(copyTap))
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if message.isOwner {
            switch message.messageType {
            case .text:
                return action == #selector(editTap) || action == #selector(deleteTap) || action == #selector(forwardTap) || action == #selector(replyTap) || action == #selector(copyTap)
            default:
                return action == #selector(deleteTap) || action == #selector(forwardTap) || action == #selector(replyTap)
            }
        } else {
            switch message.messageType {
            case .text:
                return action == #selector(replyTap) || action == #selector(forwardTap) || action == #selector(copyTap) || action == #selector(reportTap)
            default:
                return action == #selector(forwardTap) || action == #selector(replyTap) || action == #selector(reportTap)
            }
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = .clear
        selectedBackgroundView = backgroundView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        statusMetadataImageView?.isHidden = true
        containerMessageView?.isHidden = false
        metadataLabel?.isHidden = false
        errorButton?.isHidden = true
        avatarView?.image = nil
        readCountLabel?.isHidden = false
        reportIconImageView?.isHidden = true
    }
    
    class func height(for message: AmityMessageModel, boundingWidth: CGFloat) -> CGFloat {
        fatalError("This function need to be implemented.")
    }
    
    func setViewModel(with viewModel: AmityMessageListScreenViewModelType) {
        screenViewModel = viewModel
    }
    
    func setIndexPath(with _indexPath: IndexPath) {
        indexPath = _indexPath
    }
    
    func setRoundCorner(isOwner: Bool) -> CACornerMask {
        if isOwner {
            return [.layerMinXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        } else {
            return [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        }
    }
    
    func display(message: AmityMessageModel) {
        
        self.message = message
        
        reportIconImageView?.isHidden = message.flagCount > 0 ? false : true

        if message.isOwner {
            
            containerView.layer.maskedCorners = setRoundCorner(isOwner: message.isOwner)
            
            switch message.messageType {
            case .text, .audio, .file:
                containerView.backgroundColor = AmityColorSet.messageBubble
            case .image:
                containerView.backgroundColor = AmityColorSet.messageBubbleInverse
            default:
                containerView.backgroundColor = AmityColorSet.backgroundColor
            }
            
            setReadmoreText()
        } else {
            avatarView.placeholder = AmityIconSet.defaultAvatar
            setAvatarImage(message)
            containerView.layer.maskedCorners = setRoundCorner(isOwner: message.isOwner)
            
            switch message.messageType {
            case .text, .audio, .file:
                containerView.backgroundColor = AmityColorSet.messageBubbleInverse
            default:
                containerView.backgroundColor = AmityColorSet.backgroundColor
            }
            
            displayNameLabel.font = AmityFontSet.body
            displayNameLabel.textColor = AmityColorSet.base.blend(.shade1)
            
            setDisplayName(for: message)
            
            readCountLabel?.isHidden = true
        }
        
        containerView.menuItems = editMessageMenuView.generateMenuItems(messageType: message.messageType, indexPath: indexPath, text: message.text, isOwner: message.isOwner, isErrorMessage: false, isReported: message.flagCount > 0)
        
        setMetadata(message: message)
    }
    
    func displaySelected(isSelected: Bool) {
        self.isSelected = isSelected
    }
    
    func setMetadata(message: AmityMessageModel) {
        let fullString = NSMutableAttributedString()
        let style: [NSAttributedString.Key : Any]? = [.foregroundColor: AmityColorSet.base.blend(.shade2),
                                                      .font: AmityFontSet.caption]
        if message.isDeleted {
            readCountLabel?.isHidden = true
            containerMessageView.isHidden = true
            statusMetadataImageView.isHidden = false
            
            // Add your image to the attributed string
            let attachment = NSTextAttachment()
            attachment.bounds = CGRect(x: -3, y: -3, width: 15, height: 15)
            attachment.image = AmityIconSet.Chat.iconMessageUnsent
            let imageString = NSAttributedString(attachment: attachment)
            fullString.append(imageString)
            
            let deleteMessage =  String.localizedStringWithFormat(AmityLocalizedStringSet.MessageList.unsentMessage.localizedString, message.time)
            fullString.append(NSAttributedString(string: deleteMessage, attributes: style))
            statusMetadataImageView.image = AmityIconSet.iconDeleteMessage
        } else if message.isEdited {
            let editMessage = String.localizedStringWithFormat(AmityLocalizedStringSet.MessageList.editMessage.localizedString, message.time)
            fullString.append(NSAttributedString(string: editMessage, attributes: style))
        } else {
            if message.isOwner {
                switch message.syncState {
                case .error:
                    errorButton.isHidden = false
                    readCountLabel?.isHidden = true
                    fullString.append(NSAttributedString(string: message.time, attributes: style))
                    containerView.menuItems = editMessageMenuView.generateMenuItems(messageType: message.messageType, indexPath: indexPath, text: message.text, isOwner: message.isOwner, isErrorMessage: true, isReported: message.flagCount > 0)
                case .syncing:
                    fullString.append(NSAttributedString(string: AmityLocalizedStringSet.MessageList.sending.localizedString, attributes: style))
                    readCountLabel?.isHidden = true
                case .synced:
                    fullString.append(NSAttributedString(string: message.time, attributes: style))
                    readCountLabel?.isHidden = false
                default:
                    break
                }
            } else {
                fullString.append(NSAttributedString(string: message.time, attributes: style))
            }
        }
        metadataLabel?.attributedText = fullString
    }
    
    func setChannelType(channelType: AmityChannelType) {
        self.channelType = channelType
    }
    
    // MARK: - Setup View
    private func setupView() {
        selectionStyle = .default
        tintColor = AmityColorSet.primary
        
        statusMetadataImageView?.isHidden = true
        containerView?.backgroundColor = UIColor.gray.withAlphaComponent(0.25)
        containerView?.layer.cornerRadius = 4
//        containerView?.menuItems = [replyMenuItem, editMenuItem, copyMenuItem, forwardMenuItem, deleteMenuItem, reportMenuItem]
        editMessageMenuView.editMessageListActionDelegate = self
        containerView.delegate = self
        errorButton?.isHidden = true
        
        readCountLabel.font =  AmityFontSet.caption
        readCountLabel.textColor = AmityColorSet.base.blend(.shade2)
        
        contentView.backgroundColor = AmityColorSet.backgroundColor
        
        reportIconImageView?.image = AmityIconSet.Chat.iconReport
        isSelected = false
    }
    
    private func setDisplayName(for message: AmityMessageModel) {
        setDisplayName(message.displayName)
    }
    
    private func setDisplayName(_ name: String?) {
        displayNameLabel.text = name
    }
    
    private func setAvatarImage(_ messageModel: AmityMessageModel) {
        let url = messageModel.object.user?.getAvatarInfo()?.fileURL
        avatarView.setImage(withImageURL: url, placeholder: AmityIconSet.defaultAvatar)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarTap))
        avatarView.addGestureRecognizer(tapGesture)
    }
    
    private func setReadmoreText() {
        if let channelType = self.channelType {
            switch channelType {
            case .conversation:
                readCountLabel?.text = message.object.readCount > 0 ? "• Read" : "• Sent"
            default:
                readCountLabel?.text = message.object.readCount > 0 ? "• Read \(message.object.readCount)" : "• Sent"
            }
        } else {
            readCountLabel?.text = message.object.readCount > 0 ? "• Read" : "• Sent"
        }
    }
}

// MARK: - Action (Deprecated because use AmityEditMenuView instead)
private extension AmityMessageTableViewCell {
    @objc
    func editTap() {
        screenViewModel.action.performCellEvent(for: .edit(indexPath: indexPath))
    }
    
    @objc
    func deleteTap() {
        switch message.syncState {
        case .error:
            screenViewModel.action.performCellEvent(for: .deleteErrorMessage(indexPath: indexPath))
        default:
            screenViewModel.action.performCellEvent(for: .delete(indexPath: indexPath))
        }
        
    }
    
    @objc
    func reportTap() {
        screenViewModel.action.performCellEvent(for: .report(indexPath: indexPath))
    }
    
    @objc
    func forwardTap() {
        screenViewModel.action.performCellEvent(for: .forward(indexPath: indexPath))
    }
    
    @IBAction func errorTap() {
        containerView.showOverlayView()
        screenViewModel.action.performCellEvent(for: .openEditMenu(indexPath: indexPath, sourceView: containerView, sourceTableViewCell: self, options: containerView.menuItems))
    }
    
    @objc
    func copyTap() {
        screenViewModel.action.performCellEvent(for: .copy(indexPath: indexPath))
    }
    
    @objc
    func replyTap() {
        screenViewModel.action.performCellEvent(for: .reply(indexPath: indexPath))
    }
            
    @objc func avatarTap() {
        screenViewModel.action.performCellEvent(for: .avatar(indexPath: indexPath))
    }
}

extension AmityMessageTableViewCell: AmityResponsiveViewDelegate {
    
    func didLongtapPressed(sourceView: UIView) {
        screenViewModel.action.performCellEvent(for: .openEditMenu(indexPath: indexPath, sourceView: sourceView, sourceTableViewCell: self, options: containerView.menuItems))
    }
    
}

extension AmityMessageTableViewCell: AmityEditMessageListMenuViewDelegate {
    func didTapEditMenu(event: AmityMessageListScreenViewModel.CellEvents, indexPath: IndexPath) {
        screenViewModel.action.performCellEvent(for: event)
    }
}
