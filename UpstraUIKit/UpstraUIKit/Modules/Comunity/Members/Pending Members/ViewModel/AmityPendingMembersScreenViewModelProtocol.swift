//
//  AmityPendingMembersScreenViewModelProtocol.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 19/4/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

import UIKit

protocol AmityPendingMembersScreenViewModelDelegate: AnyObject {
    func screenViewModel(_ viewModel: AmityPendingMembersScreenViewModelType, didGetMemberStatusCommunity status: AmityMemberStatusCommunity)
    func screenViewModelDidGetPendingMembers(_ viewModel: AmityPendingMembersScreenViewModelType)
    func screenViewModel(_ viewModel: AmityPendingMembersScreenViewModelType, didFail error: AmityError)
    func screenViewModelDidDeletePostFail(title: String, message: String)
}

protocol AmityPendingMembersScreenViewModelDataSource {
    var communityId: String { get }
    var memberStatusCommunity: AmityMemberStatusCommunity { get }
    
    func postComponents(in section: Int) -> AmityPostComponent
    func numberOfPostComponents() -> Int
    func numberOfItemComponents(_ tableView: AmityPostTableView, in section: Int) -> Int
    
}

protocol AmityPendingMembersScreenViewModelAction {
    func getMemberStatus()
    func getPendingMembers()
    
    func approveMember(withId memberId: String)
    func deleteMember(withId memberId: String)
}

protocol AmityPendingMembersScreenViewModelType: AmityPendingMembersScreenViewModelAction, AmityPendingMembersScreenViewModelDataSource {
    var delegate: AmityPendingMembersScreenViewModelDelegate? { get set }
    var action: AmityPendingMembersScreenViewModelAction { get }
    var dataSource: AmityPendingMembersScreenViewModelDataSource { get }
}

extension AmityPendingMembersScreenViewModelType {
    var action: AmityPendingMembersScreenViewModelAction { return self }
    var dataSource: AmityPendingMembersScreenViewModelDataSource { return self }
}

