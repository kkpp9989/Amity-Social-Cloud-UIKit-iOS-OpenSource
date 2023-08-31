//
//  LiveStreamBroadcastVC+TargetDetail.swift
//  AmityUIKitLiveStream
//
//  Created by Nutchaphon Rewik on 2/9/2564 BE.
//

import UIKit
import AmitySDK
import AmityUIKit

extension LiveStreamBroadcastViewController {
    
    func queryTargetDetail() {
        switch targetType {
        case .community:
            guard let targetId = targetId else {
                setTargetDetail(name: nil, avatarUrl: nil, isCommunityTarget: true) // [Improvement] Set is community target to true for set default avatar to default category
                assertionFailure("community target must have targetId.")
                return
            }
            liveObjectQueryToken = communityRepository.getCommunity(withId: targetId).observeOnce { [weak self] result, error in
                self?.liveObjectQueryToken = nil
                guard let community = result.object else {
                    self?.setTargetDetail(name: nil, avatarUrl: nil, isCommunityTarget: true) // [Improvement] Set is community target to true for set default avatar to default category
                    return
                }
                self?.setTargetDetail(name: community.displayName, avatarUrl: community.avatar?.fileURL, isCommunityTarget: true) // [Improvement] Set is community target to true for set default avatar to default category
            }
        case .user:
            if let targetId = targetId {
                liveObjectQueryToken = userRepository.getUser(targetId).observeOnce { [weak self] result, error in
                    self?.liveObjectQueryToken = nil
                    guard let user = result.object else {
                        self?.setTargetDetail(name: nil, avatarUrl: nil)
                        return
                    }
                    self?.setTargetDetail(name: user.displayName, avatarUrl: user.getAvatarInfo()?.fileURL)
                }
            } else {
                let currentUser = client.currentUser?.object
                setTargetDetail(
                    name: currentUser?.displayName,
                    avatarUrl: currentUser?.getAvatarInfo()?.fileURL
                )
            }
        @unknown default:
            assertionFailure("Unhandled case")
            break
        }
        
    }
    // [Improvement] Modify function for check is community target for set default avatar if don't have or can't get image
    private func setTargetDetail(name: String?, avatarUrl: String?, isCommunityTarget: Bool = false) {
        if let name = name {
            targetNameLabel.text = name
        } else {
            targetNameLabel.text = "Not Found"
        }
        if let avatarUrl = avatarUrl {
            fileRepository.downloadImageAsData(fromURL: avatarUrl, size: .small) { [weak self] image, size, error in
                guard let image = image else {
                    // [Improvement] Add set default avatar if don't have or can't get image
                    if isCommunityTarget {
                        self?.targetImageView.image = AmityIconSet.defaultCommunity
                    } else {
                        self?.targetImageView.image = AmityIconSet.defaultAvatar
                    }
                    return
                }
                self?.targetImageView.image = image
            }
        } else {
            // [Improvement] Add set default avatar if don't have or can't get image
            if isCommunityTarget {
                targetImageView.image = AmityIconSet.defaultCommunity
            } else {
                targetImageView.image = AmityIconSet.defaultAvatar
            }
        }
    }
    
}
