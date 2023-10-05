//
//  AmityPostHeaderProtocolHandler.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 2/15/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

enum AmityPostProtocolHeaderHandlerAction {
    case tapOption
    case tapDelete
    case tapReport
    case tapUnreport
    case tapClosePoll
    case TapPinpost
}

protocol AmityPostHeaderProtocolHandlerDelegate: AnyObject {
    func headerProtocolHandlerDidPerformAction(_ handler: AmityPostHeaderProtocolHandler, action: AmityPostProtocolHeaderHandlerAction, withPost post: AmityPostModel)
}

final class AmityPostHeaderProtocolHandler: AmityPostHeaderDelegate {
    weak var delegate: AmityPostHeaderProtocolHandlerDelegate?
    
    private weak var viewController: AmityViewController?
    private var isReported: Bool = false
    private var post: AmityPostModel?
    
    init(viewController: AmityViewController) {
        self.viewController = viewController
    }
    
    func showOptions(withReportStatus isReported: Bool) {
        self.isReported = isReported
        handlePostOption()
    }
    
    func didPerformAction(_ cell: AmityPostHeaderProtocol, action: AmityPostHeaderAction) {
        guard let viewController = viewController, let post = cell.post else { return }
        self.post = post
        switch action {
        case .tapAvatar, .tapDisplayName:
            AmityEventHandler.shared.userDidTap(from: viewController, userId: post.postedUserId)
        case .tapCommunityName:
            AmityEventHandler.shared.communityDidTap(from: viewController, communityId: post.targetCommunity?.communityId ?? "")
        case .tapOption:
            delegate?.headerProtocolHandlerDidPerformAction(self, action: .tapOption, withPost: post)
        }
    }
    
    private func handlePostOption() {
        guard let viewController = viewController, let post = self.post else { return }
        let bottomSheet = BottomSheetViewController()
        let contentView = ItemOptionView<TextItemOption>()
        bottomSheet.isTitleHidden = true
        bottomSheet.sheetContentView = contentView
        bottomSheet.modalPresentationStyle = .overFullScreen
        
        let deleteOption = TextItemOption(title: AmityLocalizedStringSet.PostDetail.deletePost.localizedString) { [weak self] in
            guard let strongSelf = self else { return }
            // delete option
            let alert = UIAlertController(title: AmityLocalizedStringSet.PostDetail.deletePostTitle.localizedString, message: AmityLocalizedStringSet.PostDetail.deletePostMessage.localizedString, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: AmityLocalizedStringSet.General.delete.localizedString, style: .destructive, handler: { _ in
                strongSelf.delegate?.headerProtocolHandlerDidPerformAction(strongSelf, action: .tapDelete, withPost: post)
            }))
            viewController.present(alert, animated: true, completion: nil)
        }
        
        let editOption = TextItemOption(title: AmityLocalizedStringSet.PostDetail.editPost.localizedString) {
            AmityEventHandler.shared.editPostDidTap(from: viewController, postId: post.postId)
        }
        
        let unreportOption = TextItemOption(title: AmityLocalizedStringSet.General.undoReport.localizedString) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.headerProtocolHandlerDidPerformAction(strongSelf, action: .tapUnreport, withPost: post)
        }
        
        let reportOption = TextItemOption(title: AmityLocalizedStringSet.General.report.localizedString) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.headerProtocolHandlerDidPerformAction(strongSelf, action: .tapReport, withPost: post)
        }
        
        let pinpostOption = TextItemOption(title: post.isPinPost ? AmityLocalizedStringSet.General.unPinpost.localizedString : AmityLocalizedStringSet.General.pinpost.localizedString) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.headerProtocolHandlerDidPerformAction(strongSelf, action: .TapPinpost, withPost: post)
        }
        
        let role = AmityUIKitManagerInternal.shared.client.user?.snapshot?.roles
        let isModerator = role?.contains("moderator") ?? false

        if post.isOwner {
            switch post.dataTypeInternal {
            case .poll:
                let closePoll = TextItemOption(title: AmityLocalizedStringSet.Poll.Option.closeTitle.localizedString) { [weak self] in
                    guard let strongSelf = self else { return }
                    let cancel = AmityAlertController.Action.cancel(style: .default, handler: nil)
                    let close = AmityAlertController.Action.custom(title: AmityLocalizedStringSet.Poll.Option.closeTitle.localizedString, style: .destructive) {
                        strongSelf.delegate?.headerProtocolHandlerDidPerformAction(strongSelf, action: .tapClosePoll, withPost: post)
                    }
                    AmityAlertController.present(title: AmityLocalizedStringSet.Poll.Option.alertCloseTitle.localizedString, message: AmityLocalizedStringSet.Poll.Option.alertCloseDesc.localizedString, actions: [cancel, close], from: viewController)
                    
                }
                let deletePoll = TextItemOption(title: AmityLocalizedStringSet.Poll.Option.deleteTitle.localizedString) { [weak self] in
                    guard let strongSelf = self else { return }
                    let cancel = AmityAlertController.Action.cancel(style: .default, handler: nil)
                    let delete = AmityAlertController.Action.custom(title: AmityLocalizedStringSet.General.delete.localizedString, style: .destructive, handler: {
                        strongSelf.delegate?.headerProtocolHandlerDidPerformAction(strongSelf, action: .tapDelete, withPost: post)
                    })
                    AmityAlertController.present(title: AmityLocalizedStringSet.Poll.Option.alertDeleteTitle.localizedString, message: AmityLocalizedStringSet.Poll.Option.alertDeleteDesc.localizedString, actions: [cancel, delete], from: viewController)
                }
                
                var items = (post.poll?.isClosed ?? false) ? [deletePoll] : [closePoll, deletePoll]
                
                // check permission pinpost
                switch post.appearance.amitySocialPostDisplayStyle  {
                case .community, .postDetailFromCommunityProfile:
                    if post.isModerator {
                        items.insert(pinpostOption, at: 0)
                    }
                default:
                    if isModerator {
                        items.insert(pinpostOption, at: 0)
                    }
                }
                
                contentView.configure(items: items, selectedItem: nil)
            case .file, .image, .text, .video, .unknown:
                var items = [editOption, deleteOption]
                // check permission pinpost
                switch post.appearance.amitySocialPostDisplayStyle  {
                case .community, .postDetailFromCommunityProfile:
                    if post.isModerator {
                        items.insert(pinpostOption, at: 0)
                    }
                default:
                    if isModerator {
                        items.insert(pinpostOption, at: 0)
                    }
                }
                contentView.configure(items: items, selectedItem: nil)
            case .liveStream:
                var items = [deleteOption]
                // check permission pinpost
                switch post.appearance.amitySocialPostDisplayStyle  {
                case .community, .postDetailFromCommunityProfile:
                    if post.isModerator {
                        items.insert(pinpostOption, at: 0)
                    }
                default:
                    if isModerator {
                        items.insert(pinpostOption, at: 0)
                    }
                }
                
                // Currently we don't support edit live stream post.
                contentView.configure(items: items, selectedItem: nil)
            }
            viewController.present(bottomSheet, animated: false, completion: nil)
        } else {
            // if it is in community feed, check permission before options
            if let communityId = post.targetCommunity?.communityId {
                var items: [TextItemOption] = isReported ? [unreportOption] : [reportOption]
                
                AmityUIKitManagerInternal.shared.client.hasPermission(.editCommunity, forCommunity: communityId) { [weak self] (hasPermission) in
                    if hasPermission {
                        items.insert(deleteOption, at: 0)
                    }
                    
                    // check permission pinpost
                    switch post.appearance.amitySocialPostDisplayStyle  {
                    case .community, .postDetailFromCommunityProfile:
                        if let communityId = post.targetCommunity?.communityId {
                            let participation = AmityCommunityMembership(client: AmityUIKitManagerInternal.shared.client, andCommunityId: communityId)
                            let isModerator = participation.getMember(withId: AmityUIKitManagerInternal.shared.currentUserId)?.hasModeratorRole ?? false
                            
                            if isModerator {
                                items.insert(pinpostOption, at: 0)
                            }
                        }
                    default:
                        if isModerator {
                            items.insert(pinpostOption, at: 0)
                        }
                    }
                    contentView.configure(items: items, selectedItem: nil)
                    self?.viewController?.present(bottomSheet, animated: false, completion: nil)
                }
            } else {
                var items: [TextItemOption] = isReported ? [unreportOption] : [reportOption]
                
                // check permission pinpost
                switch post.appearance.amitySocialPostDisplayStyle  {
                case .community, .postDetailFromCommunityProfile:
                    if let communityId = post.targetCommunity?.communityId {
                        let participation = AmityCommunityMembership(client: AmityUIKitManagerInternal.shared.client, andCommunityId: communityId)
                        let isModerator = participation.getMember(withId: AmityUIKitManagerInternal.shared.currentUserId)?.hasModeratorRole ?? false
                        
                        if isModerator {
                            items.insert(pinpostOption, at: 0)
                        }
                    }
                default:
                    if isModerator {
                        items.insert(pinpostOption, at: 0)
                    }
                }
                contentView.configure(items: items, selectedItem: nil)
                viewController.present(bottomSheet, animated: false, completion: nil)
            }
        }
        
    }
}
