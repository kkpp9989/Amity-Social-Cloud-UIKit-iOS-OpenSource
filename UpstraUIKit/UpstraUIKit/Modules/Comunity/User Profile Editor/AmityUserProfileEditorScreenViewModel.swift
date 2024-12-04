//
//  AmityEditUserProfileScreenViewModel.swift
//  AmityUIKit
//
//  Created by Nontapat Siengsanor on 15/10/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit
import AmitySDK

class AmityUserProfileEditorScreenViewModel: AmityUserProfileEditorScreenViewModelType {
    
    private let userRepository = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
    private var userObject: AmityObject<AmityUser>?
    private var userCollectionToken: AmityNotificationToken?
    private let dispatchGroup = DispatchGroupWraper()
    private let amityUserUpdateBuilder = AmityUserUpdateBuilder()
    private let fileRepository = AmityFileRepository(client: AmityUIKitManagerInternal.shared.client)
    
    weak var delegate: AmityUserProfileEditorScreenViewModelDelegate?
    var user: AmityUserModel?
    
    init() {
        userObject = userRepository.getUser(AmityUIKitManagerInternal.shared.client.currentUserId!)
        userCollectionToken = userObject?.observe { [weak self] user, error in
            guard let strongSelf = self,
                  let user = user.snapshot else { return }
            
            strongSelf.user = AmityUserModel(user: user)
            strongSelf.delegate?.screenViewModelDidUpdate(strongSelf)
        }
    }
    
    // [Deprecated]
    func update(displayName: String, about: String) {
        
        let completion: AmityRequestCompletion? = { [weak self] success, error in
            if success {
                self?.dispatchGroup.leave()
            } else {
                self?.dispatchGroup.leaveWithError(error)
            }
        }
        
        // Update
        dispatchGroup.enter()
        amityUserUpdateBuilder.setUserDescription(about)
        AmityUIKitManagerInternal.shared.client.updateUser(amityUserUpdateBuilder, completion: completion)
        
        dispatchGroup.notify(queue: DispatchQueue.main) { error in
            if let error = error {
                Log.add("Error")
            } else {
                Log.add("Success")
            }
        }
    }
    
    func update(displayName: String, about: String) async -> Bool {
        do {
            // Set about text to builder
            amityUserUpdateBuilder.setUserDescription(about)
            // Update profile
            let isSuccess = try await AmityUIKitManagerInternal.shared.client.editUser(amityUserUpdateBuilder)
            return isSuccess
        } catch {
//            print("[Chat] Can't update display name / about to profile with error: \(error.localizedDescription)")
            return false
        }
    }
    
    // [Deprecated]
    func update(avatar: UIImage, completion: ((Bool) -> Void)?) {
        // Update user avatar
        dispatchGroup.enter()
        fileRepository.uploadImage(avatar, progress: nil) { [weak self] (imageData, error) in
            guard let self = self else { return }
            self.amityUserUpdateBuilder.setAvatar(imageData)
            AmityUIKitManagerInternal.shared.client.updateUser(self.amityUserUpdateBuilder) { [weak self] success, error in
                if success {
                    self?.dispatchGroup.leave()
                } else {
                    self?.dispatchGroup.leaveWithError(error)
                }
                completion?(success)
            }
        }
    }
    
    func update(avatar: UIImage) async -> Bool {
        do {
            // Upload avatar image
            let imageData = try await fileRepository.uploadImage(avatar) { progress in
//                print("[Avatar][Chat] Upload progressing result: \(progress)")
                DispatchQueue.main.async {
                    self.delegate?.screenViewModelDidUpdateAvatarUploadingProgress(self, progressing: progress)
                }
            }
            // Set avatar to update builder
            amityUserUpdateBuilder.setAvatar(imageData)
            // Update user profile
            let isSuccess = try await AmityUIKitManagerInternal.shared.client.editUser(amityUserUpdateBuilder)
            return isSuccess
        } catch {
//          print("[Chat] Can't update avatar to profile with error: \(error.localizedDescription)")
            return false
        }
    }
}
