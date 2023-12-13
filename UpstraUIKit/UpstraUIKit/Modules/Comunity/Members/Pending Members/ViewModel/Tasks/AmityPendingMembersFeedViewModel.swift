//
//  AmityPendingMembersFeedViewModel.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 13/7/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityPendingMembersFeedViewModelProtocol {
    func getReviewingFeed(hasEditCommunityPermission: Bool, _ completion: (([AmityPostComponent]) -> Void)?)
}

final class AmityPendingMembersFeedViewModel: AmityPendingMembersFeedViewModelProtocol {
    
    private weak var feedRepositoryManager: AmityFeedRepositoryManagerProtocol?
    private var communityId: String
    
    init(communityId: String,
         feedRepositoryManager: AmityFeedRepositoryManagerProtocol)  {
        self.communityId = communityId
        self.feedRepositoryManager = feedRepositoryManager
    }
    
    // Pending Members
    func getReviewingFeed(hasEditCommunityPermission: Bool, _ completion: (([AmityPostComponent]) -> Void)?) {
        /*
        feedRepositoryManager?.retrieveFeed(withFeedType: .pendingMembersFeed(communityId: communityId), completion: { [weak self] (result) in
            switch result {
            case .success(let Members):
                //self?.preparePostComponent(Members: posts, hasEditCommunityPermission: hasEditCommunityPermission, completion)
            case .failure:
                completion?([])
            }
        })*/
    }
    /*
    // Prepare post component
    private func preparePostComponent(Members: [AmityPostModel], hasEditCommunityPermission: Bool, _ completion: (([AmityPostComponent]) -> Void)?) {
        var postComponents = [AmityPostComponent]()

        for post in Members {
            let component = AmityPendingMembersComponent(post: post, hasEditCommunityPermission: hasEditCommunityPermission)
            postComponents.append(AmityPostComponent(component: component))
        }
        
        completion?(postComponents)
    }
     */
}
