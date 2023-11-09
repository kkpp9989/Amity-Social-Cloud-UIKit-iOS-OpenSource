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
    
    private var getByOtherUserIdToken: AmityNotificationToken?
    private var getByMemberShipToken: AmityNotificationToken?
    
    init(channelId: String) {
        self.channelId = channelId
        
        // Get Channel
        userRepository = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
        
    }
    // MARK: Get other user (1:1 Chat)
    func getOtherUserInConversationChatByMemberShip(completion: @escaping (_ user: AmityUserModel?) -> Void) {
        let membershipParticipation = AmityChannelMembership(client: AmityUIKitManager.client, andChannel: channelId)
        let getByMemberShip = membershipParticipation.getMembers(filter: .all, sortBy: .firstCreated, roles: [])
        getByMemberShipToken = getByMemberShip.observeOnce { [self] liveObjectCollection, change, error in
            if liveObjectCollection.count() > 0 {
                let currentMemberList = liveObjectCollection.allObjects()
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
    }
    
    func getOtherUserInConversationChatByOtherUserId(otherUserId: String, completion: @escaping (_ user: AmityUserModel?) -> Void) {
        getByOtherUserIdToken = userRepository.getUser(otherUserId).observeOnce { [self] liveObject, error in
            if let user = liveObject.snapshot {
                completion(AmityUserModel(user: user))
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: Report / unreport user
    func getStatusReportUser(with userId: String, _ completion: @escaping (_ result: Bool?, _ error: Error?) -> Void) {
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: userRepository.isUserFlaggedByMe(withId:), parameters: userId) { success, error in
            completion(success, error)
        }
    }
    
    func reportUser(with userId: String, _ completion: @escaping (_ result: Bool?, _ error: Error?) -> Void) {
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: userRepository.flagUser(withId:), parameters: userId) { success, error in
            completion(success, error)
        }
    }
    
    func unreportUser(with userId: String, _ completion: @escaping (_ result: Bool?, _ error: Error?) -> Void) {
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
