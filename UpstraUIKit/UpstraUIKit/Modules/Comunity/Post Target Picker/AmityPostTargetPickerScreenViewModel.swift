//
//  AmityPostTargetPickerScreenViewModel.swift
//  AmityUIKit
//
//  Created by Nontapat Siengsanor on 27/8/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import AmitySDK
import UIKit

enum CustomAmityCommunityPermission {
    case userCanPost
}

class AmityPostTargetPickerScreenViewModel: AmityPostTargetPickerScreenViewModelType {
    
    weak var delegate: AmityPostTargetPickerScreenViewModelDelegate?
    
    private let communityRepository = AmityCommunityRepository(client: AmityUIKitManagerInternal.shared.client)
    private var communityCollection: AmityCollection<AmityCommunity>?
    private var categoryCollectionToken:AmityNotificationToken?
    
    private var communities: [AmityCommunity] = []
    
    func observe() {
        let queryOptions = AmityCommunityQueryOptions(displayName: "", filter: .userIsMember, sortBy: .displayName, includeDeleted: false)
        communityCollection = communityRepository.getCommunities(with: queryOptions)
        categoryCollectionToken = communityCollection?.observe({ [weak self] (collection, _, _) in
            guard let strongSelf = self else { return }
            
            // [Fix-defect] Add filter community from user can post setting
            let latestResultCommunities = collection.allObjects().filter { _community in
                return strongSelf.checkCurrentLoginUserCommunityPermission(community: _community, permission: .userCanPost)
            }
            
            strongSelf.communities = latestResultCommunities
            
            switch collection.dataStatus {
            case .fresh:
                strongSelf.delegate?.screenViewModelDidUpdateItems(strongSelf)
            default: break
            }
        })
    }
    
    func numberOfItems() -> Int {
//        return Int(communityCollection?.count() ?? 0)
        return communities.count
    }
    
    func community(at indexPath: IndexPath) -> AmityCommunity? {
//        return communityCollection?.object(at: indexPath.row)
        return communities[indexPath.row]
    }
    
    func loadNext() {
        guard let collection = communityCollection else { return }
        switch collection.loadingStatus {
        case .loaded:
            collection.nextPage()
        default:
            break
        }
    }
    
    private func checkCurrentLoginUserCommunityPermission(community: AmityCommunity, permission: CustomAmityCommunityPermission) -> Bool {
        var result: Bool = true
        
        switch permission {
        case .userCanPost:
            let isModeratorUserInOfficialCommunity = AmityMemberCommunityUtilities.isModeratorUserInCommunity(withUserId: AmityUIKitManagerInternal.shared.currentUserId, communityId: community.communityId)
            let isOfficial = community.isOfficial
            let isOnlyAdminCanPost = community.onlyAdminCanPost

            // Check permission from backend setting
            if isOnlyAdminCanPost && !isModeratorUserInOfficialCommunity {
                result = false // Case : Can't post -> remove this community from post community picker
            }
        default:
            break
        }
        
        return result
    }
    
}
