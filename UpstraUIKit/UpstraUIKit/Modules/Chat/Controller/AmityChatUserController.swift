//
//  AmityChatUserController.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 3/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation
import AmitySDK

protocol AmityChatUserControllerProtocol {
    func reportUser(with userId: String, _ completion: @escaping (_ result: Bool?, _ error: Error?) -> Void) async // Used
    func unreportUser(with userId: String, _ completion: @escaping (_ result: Bool?, _ error: Error?) -> Void) async // Used
    func getStatusReportUser(with userId: String, _ completion: @escaping (_ result: Bool?, _ error: Error?) -> Void) async // Used
    func getOtherUserInConversationChatByMemberShip(completion: (_ user: AmityUserModel?) -> Void) // Used
}

final class AmityChatUserController: AmityChatUserControllerProtocol {

    private let userRepository: AmityUserRepository
    private let channelId: String
    
    init(channelId: String) {
        self.channelId = channelId
        
        // Get Channel
        userRepository = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
        
    }
    // MARK: Get other user (1:1 Chat)
    func getOtherUserInConversationChatByMemberShip(completion: (_ user: AmityUserModel?) -> Void) {
        let membershipParticipation = AmityChannelMembership(client: AmityUIKitManager.client, andChannel: channelId)
        let currentMemberList = membershipParticipation.getMembers(filter: .all, sortBy: .firstCreated, roles: []).allObjects()
        if currentMemberList.count > 0 {
            let currentLoginedUserId = AmityUIKitManagerInternal.shared.currentUserId
            let otherMember = currentMemberList.filter { member in
                return member.userId != currentLoginedUserId
            }
            if otherMember.count > 0, let otherMemberModel = otherMember[0].user {
                completion(AmityUserModel(user: otherMemberModel))
            } else {
                completion(nil)
            }
        } else {
            completion(nil)
        }
    }
    
    
    // MARK: Report / unreport user
    func getStatusReportUser(with userId: String, _ completion: @escaping (_ result: Bool?, _ error: Error?) -> Void) async {
        do {
            let isFlaggedByMe = try await userRepository.isUserFlaggedByMe(withId: userId)
            completion(isFlaggedByMe, nil)
        } catch {
            completion(nil, error)
        }
    }
    
    func reportUser(with userId: String, _ completion: @escaping (_ result: Bool?, _ error: Error?) -> Void) async {
        do {
            let flagged = try await userRepository.flagUser(withId: userId)
            completion(flagged, nil)
        } catch {
            completion(nil, error)
        }
    }
    
    func unreportUser(with userId: String, _ completion: @escaping (_ result: Bool?, _ error: Error?) -> Void) async {
        do {
            let unFlagged = try await userRepository.unflagUser(withId: userId)
            completion(unFlagged, nil)
        } catch {
            completion(nil, error)
        }
    }
}
