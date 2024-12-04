//
//  AmityEditMenuView.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 30/11/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

public struct AmityEditMenuItem {
    let icon: UIImage?
    let title: String
    let completion: (() -> Void)?
}

protocol AmityEditMessageListMenuViewDelegate {
    func didTapEditMenu(event: AmityMessageListScreenViewModel.CellEvents, indexPath: IndexPath)
}

public class AmityEditMenuView {
    
    var editMessageListActionDelegate: AmityEditMessageListMenuViewDelegate?
    
    init() {
    }
    
    static func present(options: [AmityEditMenuItem],
                       sourceViewController: UIPopoverPresentationControllerDelegate?,
                        sourceMessageView: UIView,
                        sourceTableViewCell: UITableViewCell,
                        selectedText: String?,
                        indexPath: IndexPath,
                       width: CGFloat? = nil,
                       height: CGFloat? = nil,
                       completion: (() -> Void)? = nil) {
        // Get source view controller
        guard let sourceViewController = sourceViewController as? AmityViewController else { return }
        
        // Get edit menu view
        let vc = AmityEditMenuViewController.make()
        
        // Set popover viewcontroller
        vc.modalPresentationStyle = .popover
        let popover = vc.popoverPresentationController
        popover?.delegate = (sourceViewController as! any UIPopoverPresentationControllerDelegate)
        popover?.sourceView = sourceMessageView
        
        // Set permittedArrowDirections based on the condition
        guard let window = UIScreen.main as? UICoordinateSpace else { return }
        let cellFrame = sourceTableViewCell.convert(sourceTableViewCell.bounds, to: window)
        let menuHeight: CGFloat = height ?? vc.currentDynamicTableViewHeight
        let navigationbarHeight: CGFloat = sourceViewController.navigationController?.navigationBar.frame.height ?? 0.0
        let yOffsetAbove = cellFrame.origin.y - menuHeight - navigationbarHeight
        let _ = cellFrame.origin.y + cellFrame.height
        popover?.permittedArrowDirections = []
        if yOffsetAbove > 0 {
            popover?.permittedArrowDirections = .down
        } else {
            popover?.permittedArrowDirections = .up
        }
        
        // Configure data
        vc.configure(items: options, selectedText: selectedText)
        
        // Present view
        sourceViewController.present(vc, animated: true, completion: completion)
        
        // Set size view
        vc.preferredContentSize = CGSize(width: width ?? vc.currentDynamicTableViewWidth, height: height ?? vc.currentDynamicTableViewHeight)
    }
    
    func generateMenuItems(message: AmityMessageModel, indexPath: IndexPath?, shouldShowTypingTab: Bool) -> [AmityEditMenuItem] {
        var items: [AmityEditMenuItem] = []
        
        /** Case : Error message **/
        // Set edit error message menu if message is message sent not successfully
        if message.syncState == .error {
            items = [AmityEditMenuItem(icon: AmityIconSet.EditMessesgeMenu.iconResend, title: "Resend", completion: { [weak self] in
                guard let weakSelf = self else { return }
                
                // Handle Edit message in message list viewcontroller action (editMessageActionDelegate)
                if let indexPath = indexPath {
                    weakSelf.editMessageListActionDelegate?.didTapEditMenu(event: .resend(indexPath: indexPath), indexPath: indexPath)
                }
            }), AmityEditMenuItem(icon: AmityIconSet.EditMessesgeMenu.iconDelete, title: "Delete", completion: { [weak self] in
                guard let weakSelf = self else { return }
                
                // Handle Edit message in message list viewcontroller action (editMessageActionDelegate)
                if let indexPath = indexPath {
                    weakSelf.editMessageListActionDelegate?.didTapEditMenu(event: .deleteErrorMessage(indexPath: indexPath), indexPath: indexPath)
                }
            }), AmityEditMenuItem(icon: AmityIconSet.EditMessesgeMenu.iconCancel, title: "Cancel", completion: {})]
            return items
        }
        
        /** Case : Message **/
        // Add reply button if should show typing tab view
        if shouldShowTypingTab {
            items.append(AmityEditMenuItem(icon: AmityIconSet.EditMessesgeMenu.iconReply, title: "Reply", completion: { [weak self] in
                guard let weakSelf = self else { return }
                
                // Handle Edit message in message list viewcontroller action (editMessageActionDelegate)
                if let indexPath = indexPath {
                    weakSelf.editMessageListActionDelegate?.didTapEditMenu(event: .reply(indexPath: indexPath), indexPath: indexPath)
                }
            }))
        }
        
        // Add edit button if message type is text and is owner
        if message.messageType == .text && message.isOwner {
            items.append(AmityEditMenuItem(icon: AmityIconSet.EditMessesgeMenu.iconEdit, title: "Edit", completion: { [weak self] in
                guard let weakSelf = self else { return }
                
                // Handle Edit message in message list viewcontroller action (editMessageActionDelegate)
                if let indexPath = indexPath {
                    weakSelf.editMessageListActionDelegate?.didTapEditMenu(event: .edit(indexPath: indexPath), indexPath: indexPath)
                }
            }))
        }
        
        // Add copy button if message type is text
        if message.messageType == .text || (message.messageType == .image && message.imageCaption != nil) {
            items.append(AmityEditMenuItem(icon: AmityIconSet.EditMessesgeMenu.iconCopy, title: "Copy", completion: {
                UIPasteboard.general.string = message.text ?? message.imageCaption // Add text to copy clipboard
            }))
        }
        
        // Add Forward function
        if message.messageType != .custom {
            items.append(AmityEditMenuItem(icon: AmityIconSet.EditMessesgeMenu.iconForward, title: "Forward", completion: { [weak self] in
                guard let weakSelf = self else { return }
                
                // Handle Edit message in message list viewcontroller action (editMessageActionDelegate)
                if let indexPath = indexPath {
                    weakSelf.editMessageListActionDelegate?.didTapEditMenu(event: .forward(indexPath: indexPath), indexPath: indexPath)
                }
            }))
        }
        
        // Add unsend button if message is owner | Add report button if message is other
        if message.isOwner {
            items.append(AmityEditMenuItem(icon: AmityIconSet.EditMessesgeMenu.iconUnsend, title: "Unsend", completion: { [weak self] in
                guard let weakSelf = self else { return }
                
                // Handle Edit message in message list viewcontroller action (editMessageActionDelegate)
                if let indexPath = indexPath {
                    weakSelf.editMessageListActionDelegate?.didTapEditMenu(event: .delete(indexPath: indexPath), indexPath: indexPath)
                }
            }))
        } else {
            items.append(AmityEditMenuItem(icon: AmityIconSet.EditMessesgeMenu.iconReport, title: message.isFlaggedByMe ? "Unreport" : "Report", completion: { [weak self] in
                guard let weakSelf = self else { return }
                
                // Handle Edit message in message list viewcontroller action (editMessageActionDelegate)
                if let indexPath = indexPath {
                    weakSelf.editMessageListActionDelegate?.didTapEditMenu(event: .report(indexPath: indexPath), indexPath: indexPath)
                }
            }))
        }
        
        return items
    }
}
