//
//  AmityPendingMembersScreenViewModel.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 19/4/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

final class AmityPendingMembersScreenViewModel: AmityPendingMembersScreenViewModelType {
    
    // MARK: - Delegate
    weak var delegate: AmityPendingMembersScreenViewModelDelegate?
    
    // MARK: - Repository
    private let communityRepository: AmityCommunityRepository
    private let feedRepositoryManager: AmityFeedRepositoryManagerProtocol
    private let postRepository: AmityPostRepository
    
    // MARK: - Tasks
    private let communityViewModel: AmityPendingMembersCommunityViewModelProtocol
    private let pendingMembersFeedViewModel: AmityPendingMembersFeedViewModelProtocol
    //private let postViewModel: AmityPendingPostsDetailGetPostViewModelProtocol
    
    // MARK: - Properties
    private var postComponents = [AmityPostComponent]()
    private var community: AmityCommunityModel?
    let communityId: String
    private(set) var memberStatusCommunity: AmityMemberStatusCommunity = .guest
    
    init(communityId: String) {
        self.communityId = communityId
        self.communityRepository = AmityCommunityRepository(client: AmityUIKitManagerInternal.shared.client)
        self.feedRepositoryManager = AmityFeedRepositoryManager()
        self.postRepository = AmityPostRepository(client: AmityUIKitManagerInternal.shared.client)
        self.communityViewModel = AmityPendingMembersCommunityViewModel(communityId: communityId, communityRepository: communityRepository)
        self.pendingMembersFeedViewModel = AmityPendingMembersFeedViewModel(communityId: communityId, feedRepositoryManager: feedRepositoryManager)
        //self.postViewModel = AmityPendingMembersDetailGetPostViewModel()
    }
}

// MARK: - Data Source
extension AmityPendingMembersScreenViewModel {
    
    func postComponents(in section: Int) -> AmityPostComponent {
        return postComponents[section]
    }
    
    func numberOfPostComponents() -> Int {
        return postComponents.count
    }
    
    func numberOfItemComponents(_ tableView: AmityPostTableView, in section: Int) -> Int {
        let postComponent = postComponents[section]
        
        if let component = tableView.feedDataSource?.getUIComponentForPost(post: postComponent._composable.post, at: section) {
            return component.getComponentCount(for: section)
        }
        return postComponent.getComponentCount(for: section)
    }
    
}

// MARK: - Action
extension AmityPendingMembersScreenViewModel {
    
    func getMemberStatus() {
        communityViewModel.getMemberStatus { [weak self] (community, status) in
            guard let strongSelf = self else { return }
            strongSelf.community = community
            strongSelf.memberStatusCommunity = status
            strongSelf.delegate?.screenViewModel(strongSelf, didGetMemberStatusCommunity: status)
        }
    }
    
    func getPendingMembers() {
        pendingMembersFeedViewModel.getReviewingFeed(hasEditCommunityPermission: memberStatusCommunity == .admin) { [weak self] (postComponents) in
            guard let strongSelf = self else { return }
            strongSelf.postComponents = postComponents
            strongSelf.delegate?.screenViewModelDidGetPendingMemberRequests(strongSelf)
        }
    }
   
    func approvePost(withPostId postId: String) {
        postRepository.approvePost(withId: postId, completion: nil)
    }
    
    func declinePost(withPostId postId: String) {
        postRepository.declinePost(withId: postId, completion: nil)
    }
    
    func deletePost(withPostId postId: String) {
        /*
        postViewModel.getPostForPostId(withPostId: postId) { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let post):
                switch post.feedType {
                case .published, .declined:
                    strongSelf.delegate?.screenViewModelDidDeleteMemberRequestFail(title: "Something went wrong",
                                                                          message: AmityLocalizedStringSet.PendingMembers.alertDeleteFailApproveOrDecline.localizedString)
                        //AmityLocalizedStringSet.PendingMembers.postNotAvailable.localizedString
                case .reviewing:
                    self?.postRepository.deletePost(withId: postId, parentId: nil, hardDelete: false, completion: nil)
                @unknown default:
                    break
                }
            case .failure:
                strongSelf.delegate?.screenViewModelDidDeleteMemberRequestFail(title: "Something went wrong",
                                                                      message: AmityLocalizedStringSet.somethingWentWrongWithTryAgain.localizedString)
                    //AmityLocalizedStringSet.PendingMembers.alertDeleteFailTitle.localizedString
            }
        }*/
    }
}
