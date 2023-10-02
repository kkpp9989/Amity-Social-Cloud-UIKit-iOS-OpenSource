//
//  AmityChatFriendScreenViewModelProtocol.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 2/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation
import AmitySDK

protocol AmityChatFriendScreenViewModelDelegate: AnyObject {
    func screenViewModelDidGetListFail()
    func screenViewModelDidGetListSuccess()
    func screenViewModel(_ viewModel: AmityChatFriendScreenViewModelType, failure error: AmityError)
    func screenViewModel(_ viewModel: AmityChatFriendScreenViewModelType, didRemoveUser at: IndexPath)
    func screenViewModel(_ viewModel: AmityChatFriendScreenViewModelType, didReportUserSuccess at: IndexPath)
    func screenViewModel(_ viewModel: AmityChatFriendScreenViewModelType, didUnreportUserSuccess at: IndexPath)
    func screenViewModel(_ viewModel: AmityChatFriendScreenViewModelType, didGetReportUserStatus isReported: Bool, at indexPath: IndexPath)
}

protocol AmityChatFriendScreenViewModelDataSource {
    var userId: String { get }
    var isCurrentUser: Bool { get }
    var type: AmityFollowerViewType { get }
    func numberOfItems() -> Int
    func item(at indexPath: IndexPath) -> AmityUserModel?
}

protocol AmityChatFriendScreenViewModelAction {
    func getFollowsList()
    func loadMoreFollowingList()
    func reportUser(at indexPath: IndexPath)
    func removeUser(at indexPath: IndexPath)
    func unreportUser(at indexPath: IndexPath)
    func getReportUserStatus(at indexPath: IndexPath)
}

protocol AmityChatFriendScreenViewModelType: AmityChatFriendScreenViewModelAction, AmityChatFriendScreenViewModelDataSource {
    var delegate: AmityChatFriendScreenViewModelDelegate? { get set }
    var action: AmityChatFriendScreenViewModelAction { get }
    var dataSource: AmityChatFriendScreenViewModelDataSource { get }
}

extension AmityChatFriendScreenViewModelType {
    var action: AmityChatFriendScreenViewModelAction { return self }
    var dataSource: AmityChatFriendScreenViewModelDataSource { return self }
}
