//
//  GroupChatCreatorScreenViewModel.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 8/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

class GroupChatCreatorScreenViewModel: GroupChatCreatorScreenViewModelType {
    
    private let dispatchGroup = DispatchGroupWraper()
    private let amityUserUpdateBuilder = AmityLiveChannelBuilder()
    private let fileRepository = AmityFileRepository(client: AmityUIKitManagerInternal.shared.client)
    private var existingChannelToken: AmityNotificationToken?
    private let channelRepository: AmityChannelRepository

    weak var delegate: GroupChatCreatorScreenViewModelDelegate?
    var user: AmityUserModel?
    
    private var selectUsersData: [AmitySelectMemberModel]

    init(_ selectUsersData: [AmitySelectMemberModel]) {
        self.channelRepository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
        self.selectUsersData = selectUsersData
    }
    
    func update(avatar: UIImage, completion: ((Bool) -> Void)?) {
        // Update user avatar
        dispatchGroup.enter()
        fileRepository.uploadImage(avatar, progress: nil) { [weak self] (imageData, error) in
            guard let self = self else { return }
            if let error = error {
                self.dispatchGroup.leaveWithError(error)
                completion?(false)
            }
            if let imageData = imageData {
                self.amityUserUpdateBuilder.setAvatar(imageData)
                self.dispatchGroup.leave()
                completion?(true)
            }
        }
    }
    
    func createChannel(displayName: String) {
		if !displayName.isEmpty {
			amityUserUpdateBuilder.setDisplayName(displayName)
		}
		delegate?.screenViewModelDidCreateCommunity(self, builder: amityUserUpdateBuilder)
    }
}
