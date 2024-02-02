//
//  AmityMessageTextFullEditorScreenViewModelType.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 31/1/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

enum AmityMessageMode: Equatable {
    case create
    case edit(messageId: String)
    
    static func == (lhs: AmityMessageMode, rhs: AmityMessageMode) -> Bool {
        if case .create = lhs, case .create = rhs {
            return true
        }
        return false
    }
}

public enum AmityMessageTarget {
    case conversation(channels: [AmityChannelModel]?)
    case community(channels: [AmityChannelModel]?)
    case privateChannel(channels: [AmityChannelModel]?)
    case broadcast(channels: [AmityChannelModel]?)
}

protocol AmityMessageTextFullEditorScreenViewModelDataSource {
    func loadMessage(for postId: String)
}

protocol AmityMessageTextFullEditorScreenViewModelDelegate: AnyObject {
    func screenViewModelDidLoadMessage(_ viewModel: AmityMessageTextFullEditorScreenViewModelType, message: AmityMessage)
    func screenViewModelDidCreateMessage(_ viewModel: AmityMessageTextFullEditorScreenViewModelType, message: AmityMessage?, error: Error?)
    func screenViewModelDidUpdateMessage(_ viewModel: AmityMessageTextFullEditorScreenViewModelType, error: Error?)
}

protocol AmityAmityMessageTextFullEditorScreenViewModelAction {
    func createMessage(text: String, medias: [AmityMedia], files: [AmityFile], channelId: String?, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?)
    func updateMessage(oldMessage: AmityMessageModel, text: String, medias: [AmityMedia], files: [AmityFile], metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?)
}

protocol AmityMessageTextFullEditorScreenViewModelType: AmityAmityMessageTextFullEditorScreenViewModelAction, AmityMessageTextFullEditorScreenViewModelDataSource {
    var action: AmityAmityMessageTextFullEditorScreenViewModelAction { get }
    var dataSource: AmityMessageTextFullEditorScreenViewModelDataSource { get }
    var delegate: AmityMessageTextFullEditorScreenViewModelDelegate? { get set }
}

extension AmityMessageTextFullEditorScreenViewModelType {
    var action: AmityAmityMessageTextFullEditorScreenViewModelAction { return self }
    var dataSource: AmityMessageTextFullEditorScreenViewModelDataSource { return self }
}
