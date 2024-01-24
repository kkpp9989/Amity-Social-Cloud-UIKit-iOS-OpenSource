//
//  AmityMessageListTableViewController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 30/10/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit
import AmitySDK

final class AmityMessageListTableViewController: UITableViewController {
    
    // MARK: - Properties
    private var screenViewModel: AmityMessageListScreenViewModelType!
    private var expandedMessageIdList: [String] = []
    
    var oldIndexPath: IndexPath?
    
    // MARK: - View lifecycle
    private convenience init(viewModel: AmityMessageListScreenViewModelType) {
        self.init(style: .plain)
        self.screenViewModel = viewModel
    }
    
    private override init(style: UITableView.Style) {
        super.init(style: style)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        screenViewModel.action.getMessage()
    }
    
    static func make(viewModel: AmityMessageListScreenViewModelType) -> AmityMessageListTableViewController {
        return AmityMessageListTableViewController(viewModel: viewModel)
    }
    
}

extension AmityMessageListTableViewController: AmityMessageAudioTableViewCellDelegate {
    
    func reloadDataAudioCell(indexPath: IndexPath) {
        if oldIndexPath == nil {
            oldIndexPath = indexPath
        } else {
            tableView.reloadRows(at: [oldIndexPath ?? IndexPath()], with: .none)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.oldIndexPath = indexPath
            }
        }
    }
    
}

// MARK: - Setup View
extension AmityMessageListTableViewController {
    func setupView() {
        /* [Custom for ONE Krungthai] Delete separator line refer to ONE KTB figma */
//        tableView.separatorInset.left = UIScreen.main.bounds.width // [Original]
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .onDrag
        tableView.estimatedRowHeight = 0
        tableView.backgroundColor = AmityColorSet.chatBackgroundColor
        screenViewModel.dataSource.allCellNibs.forEach {
            tableView.register($0.value, forCellReuseIdentifier: $0.key)
        }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsMultipleSelectionDuringEditing = true
    }
}

// MARK: - Update Views
extension AmityMessageListTableViewController {
    func showBottomIndicator() {
        tableView.showHeaderLoadingIndicator()
    }
    
    func hideBottomIndicator() {
        tableView.tableHeaderView = UIView()
    }
    
    func scrollToBottom(indexPath: IndexPath) {
        tableView.layoutIfNeeded()
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
    }
    
    func updateScrollPosition(to indexPath: IndexPath) {
        
        let contentHeight = tableView.contentSize.height
        let contentYOffset = tableView.contentOffset.y
        let viewHeight = tableView.bounds.height
        
        Log.add("Content Height: \(contentHeight), Content Offset: \(contentYOffset), ViewHeight: \(viewHeight)")
        
        // We update scroll position based on the view state. User can be in multiple view state.
        //
        // State 1:
        // All message fits inside the visible part of the view. We don't need to scoll
        if viewHeight >= contentHeight {
            return
        }
        
        tableView.layoutIfNeeded()
        
        let pageThreshold = 2.25 // It means user scroll up more than 2 and a quarter of pages.
        if contentHeight - contentYOffset <= (viewHeight * pageThreshold) {
            // State 2:
            //
            // User is at the bottom-most page. So we just scroll to the bottom when new message appears.
            Log.add("Scrolling tableview to show latest message")
            if indexPath.section < tableView.numberOfSections && indexPath.row < tableView.numberOfRows(inSection: indexPath.section) {
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
            }
        } else {
            // State 3:
            //
            // User is looking at older messages. Prevent bringing user to the bottom.
        }
        
    }
    
    func updateEditMode(isEdit: Bool, indexPath: IndexPath? = nil) {
        if !isEdit { // Clear current selected row if set editing to false before
            clearSelectedRow()
        }
        
        // Enable | Disable edit mode for the table view
        tableView.setEditing(isEdit, animated: true)
        
        if let selectedIndexPath = indexPath, isEdit { // Add this message to forward list at first if set editing to true after
            // Get message
            guard let message = screenViewModel.dataSource.message(at: selectedIndexPath) else { return }
            // Add message to forward message in list
            screenViewModel.action.updateForwardMessageInList(with: message)
            // Select this message row at first
            tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
        }
    }
    
    private func clearSelectedRow() {
        guard let selectedRows = tableView.indexPathsForSelectedRows else { return }
        for indexPath in selectedRows { tableView.deselectRow(at: indexPath, animated: true) }
    }
}

// MARK: - Delegate
extension AmityMessageListTableViewController {
    
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        screenViewModel.action.loadMoreScrollUp(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let message = screenViewModel.dataSource.message(at: indexPath) else { return 0 }
        
        if expandedMessageIdList.contains(where: { $0 == message.messageId }) {
            message.appearance.isExpanding = true
        }
        
        return cellType(for: message)?
            .height(for: message, boundingWidth: tableView.bounds.width) ?? 0.0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let message = screenViewModel.dataSource.message(at: IndexPath(row: 0, section: section)) else { return nil }
        let dateView = AmityMessageDateView()
        dateView.text = message.date
        return dateView
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            guard let message = screenViewModel.dataSource.message(at: indexPath) else { return }
            screenViewModel.action.updateForwardMessageInList(with: message)
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            guard let message = screenViewModel.dataSource.message(at: indexPath) else { return }
            screenViewModel.action.updateForwardMessageInList(with: message)
        }
    }
}

// MARK: - DataSource
extension AmityMessageListTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return screenViewModel.dataSource.numberOfSection()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return screenViewModel.dataSource.numberOfMessage(in: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let message = screenViewModel.dataSource.message(at: indexPath),
            let cellIdentifier = cellIdentifier(for: message) else {
                return UITableViewCell()
        }
        if message.messageType == .audio {
            if message.isOwner {
                let cell:AmityMessageAudioTableViewCell = tableView.dequeueReusableCell(withIdentifier: AmityMessageTypes.audioOutgoing.identifier, for: indexPath) as! AmityMessageAudioTableViewCell
                cell.display(message: message)
                cell.setViewModel(with: screenViewModel)
                cell.setIndexPath(with: indexPath)
                let channelType = screenViewModel.dataSource.getChannelType()
                cell.setChannelType(channelType: channelType)
                cell.delegate = self
                cell.delegateCell = self
                cell.celliIndexPath = indexPath
                return cell
            } else {
                let cell:AmityMessageAudioTableViewCell = tableView.dequeueReusableCell(withIdentifier: AmityMessageTypes.audioIncoming.identifier, for: indexPath) as! AmityMessageAudioTableViewCell
                cell.display(message: message)
                cell.setViewModel(with: screenViewModel)
                cell.setIndexPath(with: indexPath)
                let channelType = screenViewModel.dataSource.getChannelType()
                cell.setChannelType(channelType: channelType)
                cell.delegate = self
                cell.delegateCell = self
                cell.celliIndexPath = indexPath
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
            configure(for: cell, at: indexPath)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let message = screenViewModel.dataSource.message(at: indexPath) else { return }
        let isForwardMessageSelected = screenViewModel.dataSource.isMessageInForwardMessageList(messageId: message.messageId)
        if !cell.isSelected && isForwardMessageSelected { // Select row again if tableview cell selected status is false but is forward message selected in list
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
    }
}

extension AmityMessageListTableViewController: AmityMessageCellDelegate {
    
    func performEvent(_ cell: AmityMessageTableViewCell, labelEvents: AmityMessageLabelEvents) {
        guard let message = cell.message else { return }
        
        switch labelEvents {
        case .tapExpandableLabel:
            break
        case .willExpandExpandableLabel, .willCollapseExpandableLabel:
            tableView.beginUpdates()
        case .didExpandExpandableLabel(let label):
            message.appearance.isExpanding = true
            tableView.endUpdates()
            let point = label.convert(CGPoint.zero, to: tableView)
            if let indexPath = tableView.indexPathForRow(at: point) as IndexPath? {
                DispatchQueue.main.async { [weak self] in
                    self?.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                }
                expandedMessageIdList.append(message.messageId)
            }
        case .didCollapseExpandableLabel:
            message.appearance.isExpanding = false
            tableView.endUpdates()
		case .didTapOnMention(_, let userId):
			screenViewModel.action.tapOnMention(withUserId: userId)
        }
    }
    
    func performEvent(_ cell: AmityMessageTableViewCell, events: AmityMessageCellEvents) {
        
        switch cell.message.messageType {
        case .audio:
            switch events {
            case .audioPlaying:
                tableView.reloadData()
            case .audioFinishPlaying:
                tableView.reloadRows(at: [cell.indexPath], with: .none)
            default:
                break
            }
        default:
            break
        }
    }
}

// MARK: - Private functions
extension AmityMessageListTableViewController {
    
    private func configure(for cell: UITableViewCell, at indexPath: IndexPath) {
        guard let message = screenViewModel.dataSource.message(at: indexPath) else { return }
        if let cell = cell as? AmityMessageTableViewCell {
            cell.delegate = self
            cell.setViewModel(with: screenViewModel)
            cell.setIndexPath(with: indexPath)
        }
        if let _ = cell as? AmityMessageTextTableViewCell, expandedMessageIdList.contains(where: { $0 == message.messageId } ) {
            message.appearance.isExpanding = true
        }
        
        let channelType = screenViewModel.dataSource.getChannelType()
        (cell as? AmityMessageCellProtocol)?.display(message: message)
        (cell as? AmityMessageCellProtocol)?.setChannelType(channelType: channelType)
       
    }
    
    private func cellIdentifier(for message: AmityMessageModel) -> String? {
        if message.parentId == nil {
            switch message.messageType {
            case .text:
                return message.isOwner ? AmityMessageTypes.textOutgoing.identifier : AmityMessageTypes.textIncoming.identifier
            case .image :
                return message.isOwner ? AmityMessageTypes.imageOutgoing.identifier : AmityMessageTypes.imageIncoming.identifier
            case .audio:
                return message.isOwner ? AmityMessageTypes.audioOutgoing.identifier : AmityMessageTypes.audioIncoming.identifier
            case .video:
                return message.isOwner ? AmityMessageTypes.videoOutgoing.identifier : AmityMessageTypes.videoIncoming.identifier
            case .file:
                return message.isOwner ? AmityMessageTypes.fileOutgoing.identifier : AmityMessageTypes.fileIncoming.identifier
            case .custom:
                return AmityMessageTypes.operation.identifier
            default:
                return nil
            }
        } else {
            return message.isOwner ? AmityMessageTypes.replyOutgoing.identifier : AmityMessageTypes.replyIncoming.identifier
        }
    }
    
    private func cellType(for message: AmityMessageModel) -> AmityMessageCellProtocol.Type? {
        guard let identifier = cellIdentifier(for: message) else { return nil }
        return screenViewModel.allCellClasses[identifier]
    }
    
}
