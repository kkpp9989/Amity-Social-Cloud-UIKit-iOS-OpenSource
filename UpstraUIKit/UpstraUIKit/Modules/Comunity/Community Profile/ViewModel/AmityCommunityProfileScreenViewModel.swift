//
//  AmityCommunityProfileScreenViewModel.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 20/4/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

enum AmityMemberStatusCommunity: String {
    case guest
    case member
    case admin
}

final class AmityCommunityProfileScreenViewModel: AmityCommunityProfileScreenViewModelType {
    
    weak var delegate: AmityCommunityProfileScreenViewModelDelegate?
    
    // MARK: - Repository Manager
    private let communityRepositoryManager: AmityCommunityRepositoryManagerProtocol
    
    // MARK: - Properties
    let communityId: String
    private(set) var community: AmityCommunityModel?
    private(set) var memberStatusCommunity: AmityMemberStatusCommunity = .guest
    private(set) var isJoiningCommunity: Bool = false
    
    var postCount: Int {
        return community?.object.getPostCount(feedType: .published) ?? 0
    }
    
    init(communityId: String,
         communityRepositoryManager: AmityCommunityRepositoryManagerProtocol) {
        self.communityId = communityId
        self.communityRepositoryManager = communityRepositoryManager
    }
    
}

// MARK: - DataSource
extension AmityCommunityProfileScreenViewModel {
    
    func getPendingPostCount(completion: ((Int) -> Void)?) {
        getPendingPostCount(with: .reviewing, completion: completion)
    }
    
    private func getPendingPostCount(with feedType: AmityFeedType, completion: ((Int) -> Void)?) {
        guard let community = community, community.isPostReviewEnabled else {
            completion?(0)
            return
        }
        
        // Return pending post count which is already available locally.
        completion?(community.pendingPostCount)
    }
}

// MARK: - Action

// MARK: Routing
extension AmityCommunityProfileScreenViewModel {
    func route(_ route: AmityCommunityProfileRoute) {
        delegate?.screenViewModelRoute(self, route: route)
    }
    
}

// MARK: - Action
extension AmityCommunityProfileScreenViewModel {
    
    func retriveCommunity() {
        communityRepositoryManager.retrieveCommunity { [weak self] (result) in
            switch result {
            case .success(let community):
                self?.community = community
                self?.prepareDataToShowCommunityProfile(community: community)
                
                /* [Custom for ONE Krungthai] Check and set disable all notification in user level if community not important */
                if let isJoiningCommunity = self?.isJoiningCommunity, isJoiningCommunity {
                    print("[Notification] Is joining community -> Check is important community")
                    let isImportantCommunity = AmityMemberCommunityUtilities.isImportantCommunityByCommunityModel(community: community)
                    if !isImportantCommunity {
                        print("[Notification] Is joining community and is not important community -> Disable community notification")
                        self?.setDisableNotificationOfCommunity(community: community)
                    } else {
                        print("[Notification] Is joining community but is important community -> Enable community notification")
                    }
                } else {
                    print("[Notification] Is not joining community -> Skip check or set disable community notification")
                }
            case .failure:
                break
            }
            
            /* [Custom for ONE Krungthai] Set is joinging community to false for ask app is joining process end */
            self?.isJoiningCommunity = false
        }
    }
    
    private func prepareDataToShowCommunityProfile(community model: AmityCommunityModel) {
        community = model
        AmityUIKitManagerInternal.shared.client.hasPermission(.editCommunity, forCommunity: communityId) { [weak self] (hasPermission) in
            guard let strongSelf = self else { return }
            if model.isJoined {
                strongSelf.memberStatusCommunity = hasPermission ? .admin : .member
            } else {
                if model.isPublic {
                    strongSelf.memberStatusCommunity = .guest
                } else {
                    strongSelf.memberStatusCommunity = .guest
                    strongSelf.delegate?.screenViewModelToastPrivate()
                }
            }

            strongSelf.delegate?.screenViewModelDidGetCommunity(with: model)
        }
    }
    
    func joinCommunity() {
        /* [Custom for ONE Krungthai] Set is joining community to true for ask app is joining process start */
        isJoiningCommunity = true
        communityRepositoryManager.join { [weak self] (error) in
            if let error = error {
                /* [Custom for ONE Krungthai] Set is joinging community to false for ask app is joining process end */
                self?.isJoiningCommunity = false
                self?.delegate?.screenViewModelFailure()
            } else {
                self?.retriveCommunity()
            }
        }
    }
    
    /* [Custom for ONE Krungthai] Check and set disable all notification in user level if community not important */
    func setDisableNotificationOfCommunity(community model: AmityCommunityModel) {
        let vc = AmityCommunityNotificationSettingsController(withCommunityId: communityId)
        vc.disableNotificationSettings { result, error in
            if let error = error {
                print("[Notification] Disable community notification fail with error: \(error.localizedDescription)")
            } else {
                print("[Notification] Disable community notification result: \(result)")
            }
        }
    }

}
