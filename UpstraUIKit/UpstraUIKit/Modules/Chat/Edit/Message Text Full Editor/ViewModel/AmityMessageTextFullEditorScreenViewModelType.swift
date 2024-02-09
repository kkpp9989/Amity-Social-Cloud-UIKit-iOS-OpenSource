//
//  AmityMessageTextFullEditorScreenViewModelType.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 31/1/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

public enum AmityMessageMode: Equatable {
    case create
    case createManyChannel
    case edit(messageId: String)
    
    public static func == (lhs: AmityMessageMode, rhs: AmityMessageMode) -> Bool {
        if case .create = lhs, case .create = rhs {
            return true
        }
        return false
    }
}

public enum AmityMessageTarget {
    case conversation
    case community
    case privateChannel
    case broadcast(channel: AmityChannelModel?)
}

protocol AmityMessageTextFullEditorScreenViewModelDataSource {
}

protocol AmityMessageTextFullEditorScreenViewModelDelegate: AnyObject {
    func screenViewModelDidCreateMessage(_ viewModel: AmityMessageTextFullEditorScreenViewModelType, message: AmityMessage?, error: Error?)
}

protocol AmityAmityMessageTextFullEditorScreenViewModelAction {
    func createMessage(message: AmityBroadcastMessageCreatorModel, channelId: String)
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
