//
//  GroupChatCreatorScreenViewModelProtocol.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 8/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol GroupChatCreatorScreenViewModelAction {
    func update(avatar: UIImage, completion: ((Bool) -> Void)?)
    func createChannel(displayName: String)
}

protocol GroupChatCreatorScreenViewModelDataSource {
    var user: AmityUserModel? { get }
}

protocol GroupChatCreatorScreenViewModelDelegate: AnyObject {
	func screenViewModelDidCreateCommunity(_ viewModel: GroupChatCreatorScreenViewModelType, builder: AmityLiveChannelBuilder)
}

protocol GroupChatCreatorScreenViewModelType: GroupChatCreatorScreenViewModelAction, GroupChatCreatorScreenViewModelDataSource {
    var action: GroupChatCreatorScreenViewModelAction { get }
    var dataSource: GroupChatCreatorScreenViewModelDataSource { get }
    var delegate: GroupChatCreatorScreenViewModelDelegate? { get set }
}

extension GroupChatCreatorScreenViewModelType {
    var action: GroupChatCreatorScreenViewModelAction { return self }
    var dataSource: GroupChatCreatorScreenViewModelDataSource { return self }
}
