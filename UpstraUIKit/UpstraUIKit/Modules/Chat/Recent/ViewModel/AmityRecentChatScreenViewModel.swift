//
//  AmityRecentChatScreenViewModel.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 8/9/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit
import AmitySDK
import Combine

public struct AmityChannelModel {
    let channelId: String
    let displayName: String
    let memberCount: Int
    let unreadCount: Int
    let avatarURL: String
    let lastActivity: Date
    let channelType: AmityChannelType
    let avatarFileId: String?
    let participation: AmityChannelParticipation
    let metadata: [String:Any]
    let object: AmityChannel
    let previewMessage: AmityMessagePreview?
    var isOnline: Bool
    
    init(object: AmityChannel) {
        self.channelId = object.channelId
        self.avatarURL = object.getAvatarInfo()?.fileURL ?? ""
        self.displayName = (object.displayName ?? "") == "" ? AmityLocalizedStringSet.General.anonymous.localizedString : object.displayName!
        self.memberCount = object.memberCount
        self.unreadCount = object.unreadCount
        self.lastActivity = object.lastActivity ?? Date()
        self.participation = object.participation
        self.channelType = object.channelType
        self.avatarFileId = object.getAvatarInfo()?.fileURL
        self.metadata = object.metadata ?? [:]
        self.object = object
        self.previewMessage = object.messagePreview
        self.isOnline = false
    }
    
    var isConversationChannel: Bool {
        return channelType == .conversation
    }
    
    func getOtherUserId() -> String {
        if let userIds = metadata["userIds"] as? [String] {
            for id in userIds {
                if id != AmityUIKitManagerInternal.shared.client.currentUserId {
                    return id
                }
            }
        }
        return ""
    }
}

final class AmityRecentChatScreenViewModel: AmityRecentChatScreenViewModelType {
    weak var delegate: AmityRecentChatScreenViewModelDelegate?
    
    
    enum Route {
        case messageView(channelId: String, subChannelId: String)
    }
    
    // MARK: - Repository
    private let channelRepository: AmityChannelRepository
    private var roleController: AmityChannelRoleController?
    
    // MARK: - Collection
    private var channelsCollection: AmityCollection<AmityChannel>?
    
    var cancellables: AnyCancellable?

    // MARK: - Token
    private var channelsToken: AmityNotificationToken?
    private var existingChannelToken: AmityNotificationToken?
    private var channelType: AmityChannelType = .conversation
    private var channelPresenceRepo: AmityChannelPresenceRepository

    init(channelType: AmityChannelType) {
        self.channelType = channelType
        channelRepository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
        channelPresenceRepo = AmityChannelPresenceRepository(client: AmityUIKitManagerInternal.shared.client)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - DataSource
    public var channels: [AmityChannelModel] = []
    
    func getChannelArray() -> [AmityChannelModel] {
        return channels
    }
    
    func channel(at indexPath: IndexPath) -> AmityChannelModel {
        return channels[indexPath.row]
    }
    
    func numberOfRow(in section: Int) -> Int {
        return channels.count
    }
    
    func isAddMemberBarButtonEnabled() -> Bool {
        return channelType == .community
    }
    
    func createCommunityChannel(users: [AmitySelectMemberModel]) {
        var allUsers = users
        var currentUser: AmitySelectMemberModel?
        if let user = AmityUIKitManagerInternal.shared.client.user?.snapshot {
            let userModel = AmitySelectMemberModel(object: user)
            currentUser = userModel
            allUsers.append(userModel)
        }
        let builder = AmityCommunityChannelBuilder()
        let userIds = allUsers.map{ $0.userId }
        let channelId = userIds.sorted().joined(separator: "-")
        let channelDisplayName = users.count == 1 ? users.first?.displayName ?? "" : allUsers.map { $0.displayName ?? "" }.joined(separator: "-")
        builder.setUserIds(userIds)
        let metaData: [String:Any] = [
            "isDirectChat": allUsers.count == 2,
            "creatorId": currentUser?.userId ?? "",
            "sdk_type":"ios",
            "userIds": userIds
        ]
        builder.setMetadata(metaData)
        builder.setDisplayName(channelDisplayName)
        builder.setTags(["ch-comm","ios-sdk"])
        existingChannelToken?.invalidate()
        existingChannelToken = channelRepository.getChannel(channelId).observe({ [weak self] (channel, error) in
            guard let weakSelf = self else { return }
            if error != nil {
                /// Might be two reason
                /// 1. Network error
                /// 2. Channel haven't created yet
                weakSelf.createNewCommiunityChannel(builder: builder)
            }
            /// which mean we already have that channel and don't need to creaet new channel
            guard let channel = channel.snapshot else { return }
            AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: weakSelf.channelRepository.joinChannel, parameters: channelId)
            weakSelf.existingChannelToken?.invalidate()
            weakSelf.delegate?.screenViewModelDidCreateCommunity(channelId: channelId, subChannelId: channel.defaultSubChannelId)
            weakSelf.existingChannelToken?.invalidate()
        })
    
    }
    
    private func createNewCommiunityChannel(builder: AmityCommunityChannelBuilder) {
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: channelRepository.createChannel, parameters: builder) { [weak self] channelObject, error in
            guard let weakSelf = self else { return }
            if let error = error {
                weakSelf.delegate?.screenViewModelDidFailedCreateCommunity(error: error.localizedDescription)
            }
            if let channelId = channelObject?.channelId, let subChannelId = channelObject?.defaultSubChannelId {
                weakSelf.delegate?.screenViewModelDidCreateCommunity(channelId: channelId, subChannelId: subChannelId)
            }
        }
    }
    
    func createConversationChannel(users: [AmitySelectMemberModel]) {
        var allUsers = users
        var currentUser: AmitySelectMemberModel?
        if let user = AmityUIKitManagerInternal.shared.client.user?.snapshot {
            let userModel = AmitySelectMemberModel(object: user)
            currentUser = userModel
            allUsers.append(userModel)
        }
        let builder = AmityConversationChannelBuilder()
        let userIds = users.map{ $0.userId }
        let channelDisplayName = users.count == 1 ? users.first?.displayName ?? "" : allUsers.map { $0.displayName ?? "" }.joined(separator: "-")
        let metaData: [String:Any] = [
            "isDirectChat": allUsers.count == 2,
            "creatorId": currentUser?.userId ?? "",
            "sdk_type":"ios"
        ]
        builder.setMetadata(metaData)
        builder.setUserIds(userIds)
        builder.setDisplayName(channelDisplayName)
        builder.setTags(["ch-comm","ios-sdk"])
        
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: channelRepository.createChannel, parameters: builder) { channelObject, error in
            if let channelId = channelObject?.channelId, let subChannelId = channelObject?.defaultSubChannelId {
                self.delegate?.screenViewModelDidCreateCommunity(channelId: channelId, subChannelId: subChannelId)
            }
        }
    }
    
    func syncChannelPresence(_ channelId: String) {
        channelPresenceRepo.syncChannelPresence(id: channelId)
    }
    
    func unsyncChannelPresence(_ channelId: String) {
        channelPresenceRepo.unsyncChannelPresence(id: channelId)
    }
    
    func unsyncAllChannelPresence() {
        channelPresenceRepo.unsyncAllChannelPresence()
    }
    
    func getSyncAllChannelPresence() {
        cancellables = channelPresenceRepo.getSyncingChannelPresence().sink { completion in
            // Handle completion
            switch completion {
            case .failure(let error):
                print("------------> getSyncingChannelPresence error: \(error.localizedDescription)")
            default:
                print("------------> getSyncingChannelPresence error: nil")
            }
        } receiveValue: { presences in
            
            /// Channel presences where any other member is online
            let onlinePresences = presences.filter { $0.isAnyMemberOnline }
            
            // You can use this onlinePresences & map it with your channel list to determine
            // list of online channels to show or sort it in asc | desc order
            let onlineChannels = self.channels.filter { channel in
                let isOnline = onlinePresences.contains { $0.channelId == channel.channelId }
                return isOnline
            }
            
            self.channels = onlineChannels
            
        }
    }

}

// MARK: - Action
extension AmityRecentChatScreenViewModel {
    
    func viewDidLoad() {
        getChannelList()
        getSyncAllChannelPresence()
        AmityUIKitManager.checkPresenceStatus()
    }
    
    func viewWillDisappear() {
        channelsToken?.invalidate()
        cancellables?.cancel()
    }
    
    func createChannel(users: [AmitySelectMemberModel]) {
        switch channelType {
        case .community:
            createCommunityChannel(users: users)
        case .conversation:
            createConversationChannel(users: users)
        default:
            break
        }
    }

    func loadMore() {
        guard let collection = channelsCollection else { return }
        
        switch collection.loadingStatus {
        case .loaded:
            if collection.hasNext {
                collection.nextPage()
                delegate?.screenViewModelLoadingState(for: .loading)
            }
        default: break
        }
    }
    
    func join(at indexPath: IndexPath) {
        let channel = channel(at: indexPath).object
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: channelRepository.joinChannel, parameters: channel.channelId)
        delegate?.screenViewModelRoute(for: .messageView(channelId: channel.channelId, subChannelId: channel.defaultSubChannelId))
    }

    func update(completion: @escaping (Result<Void, Error>) -> Void) {
        // Create an instance of AmityUserStatus
        let userStatus = AmityUserStatus()

        // Call mapTypeToAmitySDK to map a StatusType enum value to a string
        let statusType = AmityUIKitManagerInternal.shared.userStatus
        let amityStatusString = userStatus.mapTypeToAmitySDK(statusType)
        
        let meta: [String: Any] = ["user_presence": amityStatusString]
        let amityUserUpdateBuilder = AmityUserUpdateBuilder()
        amityUserUpdateBuilder.setUserMetadata(meta)
        
        Task {
            do {
                let editUser = try await AmityUIKitManagerInternal.shared.client.editUser(amityUserUpdateBuilder)
                // The update was successful
                completion(.success(()))
            } catch {
                // Handle the error here
                print("Update failed: \(error)")
                completion(.failure(error))
            }
        }
    }
}

private extension AmityRecentChatScreenViewModel {
    
    func getChannelList() {
        switch channelType {
        case .community:
            let query = AmityChannelQuery()
            query.filter = .userIsMember
            query.includeDeleted = false
            channelsCollection = channelRepository.getChannels(with: query)
        case .conversation:
            let query = AmityChannelQuery()
            query.filter = .userIsMember
            query.includeDeleted = false
            channelsCollection = channelRepository.getChannels(with: query)
        default:
            break
        }
        channelsToken = channelsCollection?.observe { [weak self] (collection, change, error) in
            self?.prepareDataSource()
        }
    }
    
    private func prepareDataSource() {
        AmityHUD.hide()
        guard let collection = channelsCollection else {
            return
        }
        var _channels: [AmityChannelModel] = []
        for index in 0..<collection.count() {
            guard let channel = collection.object(at: index) else { return }
            let model = AmityChannelModel(object: channel)
            _channels.append(model)
        }
        channels = _channels
        delegate?.screenViewModelLoadingState(for: .loaded)
        delegate?.screenViewModelDidGetChannel()
        delegate?.screenViewModelEmptyView(isEmpty: channels.isEmpty)
    }
}
