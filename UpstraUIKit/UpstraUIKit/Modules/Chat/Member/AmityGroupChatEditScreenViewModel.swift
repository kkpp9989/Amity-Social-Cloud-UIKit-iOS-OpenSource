//
//  GroupChatScreenViewModel.swift
//  AmityUIKit
//
//  Created by min khant on 13/05/2021.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityGroupChatEditorScreenViewModelAction {
    func update(displayName: String) async -> Bool
    func update(avatar: UIImage) async -> Bool
}

protocol AmityGroupChatEditorViewModelDataSource {
    var channel: AmityChannel? { get }
    func getChannelEditUserPermission(_ completion: ((Bool) -> Void)?)
}

protocol AmityGroupChatEditorScreenViewModelDelegate: AnyObject {
    func screenViewModelDidUpdate(_ viewModel: AmityGroupChatEditorScreenViewModelType)
    func screenViewModelDidUpdateAvatarUploadingProgress(_ viewModel: AmityGroupChatEditorScreenViewModelType, progressing: Double)
}

protocol AmityGroupChatEditorScreenViewModelType: AmityGroupChatEditorScreenViewModelAction, AmityGroupChatEditorViewModelDataSource {
    var action: AmityGroupChatEditorScreenViewModelAction { get }
    var dataSource: AmityGroupChatEditorViewModelDataSource { get }
    var delegate: AmityGroupChatEditorScreenViewModelDelegate? { get set }
}

extension AmityGroupChatEditorScreenViewModelType {
    var action: AmityGroupChatEditorScreenViewModelAction { return self }
    var dataSource: AmityGroupChatEditorViewModelDataSource { return self }
}

class AmityGroupChatEditScreenViewModel: AmityGroupChatEditorScreenViewModelType {
    
    private var channelNotificationToken: AmityNotificationToken?
    private let channelRepository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
    private var channelUpdateBuilder: AmityChannelUpdateBuilder!
    private let fileRepository = AmityFileRepository(client: AmityUIKitManagerInternal.shared.client)

    var channel: AmityChannel?
    weak var delegate: AmityGroupChatEditorScreenViewModelDelegate?
    var user: AmityUserModel?
    var channelId = String()
    
    init(channelId: String) {
        self.channelId = channelId
        channelUpdateBuilder = AmityChannelUpdateBuilder(channelId: channelId)
        channelNotificationToken = channelRepository.getChannel(channelId)
            .observe({ [weak self] channel, error in
                guard let weakself = self,
                    let channel = channel.snapshot else{ return }
                weakself.channel = channel
                weakself.delegate?.screenViewModelDidUpdate(weakself)
            })
    }
    
    func update(displayName: String) async -> Bool {
        do {
            // Set about text to builder
            channelUpdateBuilder.setDisplayName(displayName)
            // Update profile
            let _ = try await channelRepository.editChannel(with: channelUpdateBuilder)
            return true
        } catch {
//            print("[Chat] Can't update display name / about to profile with error: \(error.localizedDescription)")
            return false
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
            channelUpdateBuilder.setAvatar(imageData)
            // Update group chat profile
            let _ = try await channelRepository.editChannel(with: channelUpdateBuilder)
            return true
        } catch {
//          print("[Chat] Can't update avatar to profile with error: \(error.localizedDescription)")
            return false
        }
    }
    
    func getChannelEditUserPermission(_ completion: ((Bool) -> Void)?) {
        AmityUIKitManagerInternal.shared.client.hasPermission(.editChannel, forChannel: channelId, completion: { hasPermission in
            completion?(hasPermission)
        })
    }
}
