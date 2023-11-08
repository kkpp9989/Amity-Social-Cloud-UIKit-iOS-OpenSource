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
    func reportUser(with userId: String, _ completion: @escaping (_ result: Bool?, _ error: Error?) -> Void)
    func unreportUser(with userId: String, _ completion: @escaping (_ result: Bool?, _ error: Error?) -> Void)
    func getStatusReportUser(with userId: String, _ completion: @escaping (_ result: Bool?, _ error: Error?) -> Void)
    func getOtherUserInConversationChatByMemberShip(completion:  @escaping (_ user: AmityUserModel?) -> Void)
    func getOtherUserInConversationChatByOtherUserId(otherUserId: String, completion: @escaping (_ user: AmityUserModel?) -> Void)
    func getEditGroupChannelPermission(_ completion: @escaping (_ result: Bool) -> Void)
}

final class AmityChatUserController: AmityChatUserControllerProtocol {

    private let userRepository: AmityUserRepository
    private let channelId: String
    
    private var token: AmityNotificationToken?
    
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
    
    func getOtherUserInConversationChatByOtherUserId(otherUserId: String, completion: @escaping (_ user: AmityUserModel?) -> Void) {
        token = userRepository.getUser(otherUserId).observe { liveObject, error in
            guard let user = liveObject.snapshot else {
                completion(nil)
                return
            }
            completion(AmityUserModel(user: user))
        }
    }
    
    // MARK: Report / unreport user
    func getStatusReportUser(with userId: String, _ completion: @escaping (_ result: Bool?, _ error: Error?) -> Void) {
//        do {
//            let isFlaggedByMe = try await userRepository.isUserFlaggedByMe(withId: userId)
//            completion(isFlaggedByMe, nil)
//        } catch {
//            completion(nil, error)
//        }
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: userRepository.isUserFlaggedByMe(withId:), parameters: userId) { success, error in
            completion(success, error)
        }
    }
    
    func reportUser(with userId: String, _ completion: @escaping (_ result: Bool?, _ error: Error?) -> Void) {
//        do {
//            let flagged = try await userRepository.flagUser(withId: userId)
//            completion(flagged, nil)
//        } catch {
//            completion(nil, error)
//        }
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: userRepository.flagUser(withId:), parameters: userId) { success, error in
            completion(success, error)
        }
    }
    
    func unreportUser(with userId: String, _ completion: @escaping (_ result: Bool?, _ error: Error?) -> Void) {
//        do {
//            let unFlagged = try await userRepository.unflagUser(withId: userId)
//            completion(unFlagged, nil)
//        } catch {
//            completion(nil, error)
//        }
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: userRepository.unflagUser(withId:), parameters: userId) { success, error in
            completion(success, error)
        }
    }
    
    // MARK: Group role permission
    func getEditGroupChannelPermission(_ completion: @escaping (_ result: Bool) -> Void) {
        AmityUIKitManagerInternal.shared.client.hasPermission(.editChannel, forChannel: channelId) { status in
            completion(status)
        }
    }
}
