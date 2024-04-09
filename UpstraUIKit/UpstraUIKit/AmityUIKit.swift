//
//  AmityUIKit.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 2/6/2563 BE.
//  Copyright © 2563 Amity Communication. All rights reserved.
//

import UIKit
import AmitySDK
import Combine

/// AmityUIKit
public final class AmityUIKitManager {
    
    private init() { }
    
    
    /// Setup AmityUIKit instance. Internally it creates AmityClient instance
    /// from AmitySDK.
    ///
    /// If you are using `AmitySDK` & `AmityUIKit` within same project, you can setup `AmityClient` instance using this method and access it using static property `client`.
    ///
    /// ~~~
    /// AmityUIKitManager.setup(...)
    /// ...
    /// let client: AmityClient = AmityUIKitManager.client
    /// ~~~
    ///
    /// - Parameters:
    ///   - apiKey: ApiKey provided by Amity
    ///   - region: The region to which this UIKit connects to. By default, region is .global
    public static func setup(apiKey: String, region: AmityRegion = .global, completion: @escaping (Result<Bool, Error>) -> Void) {
        AmityUIKitManagerInternal.shared.setup(apiKey: apiKey, region: region) { result in
            switch result {
            case .success(let successValue):
                completion(.success(successValue))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Setup AmityUIKit instance. Internally it creates AmityClient instance from AmitySDK.
    ///
    /// If you do not need extra configuration, please use setup(apiKey:_, region:_) method instead.
    ///
    /// Also if you are using `AmitySDK` & `AmityUIKit` within same project, you can setup `AmityClient` instance using this method and access it using static property `client`.
    ///
    /// ~~~
    /// AmityUIKitManager.setup(...)
    /// ...
    /// let client: AmityClient = AmityUIKitManager.client
    /// ~~~
    ///
    /// - Parameters:
    ///   - apiKey: ApiKey provided by Amity
    ///   - endpoint: Custom Endpoint to which this UIKit connects to.
    public static func setup(apiKey: String, endpoint: AmityEndpoint) {
        AmityUIKitManagerInternal.shared.setup(apiKey, endpoint: endpoint)
    }
    
    // MARK: - Setup Authentication
    
    /// Registers current user with server. This is analogous to "login" process. If the user is already registered, local
    /// information is used. It is okay to call this method multiple times.
    ///
    /// Note:
    /// You do not need to call `unregisterDevice` before calling this method. If new user is being registered, then sdk handles unregistering process automatically.
    /// So simply call `registerDevice` with new user information.
    ///
    /// - Parameters:
    ///   - userId: Id of the user
    ///   - displayName: Display name of the user. If display name is not provided, user id would be set as display name.
    ///   - authToken: Auth token for this user if you are using secure mode.
    ///   - completion: Completion handler.
    public static func registerDevice(
        withUserId userId: String,
        displayName: String?,
        authToken: String? = nil,
        sessionHandler: SessionHandler,
        completion: AmityRequestCompletion? = nil) {
            
        DispatchQueue.main.async {
            AmityUIKitManagerInternal.shared.registerDevice(userId, displayName: displayName, authToken: authToken, sessionHandler: sessionHandler, completion: completion)
        }
    }
    
    /// Unregisters current user. This removes all data related to current user & terminates conenction with server. This is analogous to "logout" process.
    /// Once this method is called, the only way to re-establish connection would be to call `registerDevice` method again.
    ///
    /// Note:
    /// You do not need to call this method before calling `registerDevice`.
    public static func unregisterDevice() {
        AmityUIKitManagerInternal.shared.unregisterDevice()
    }
    
    public static func clearCache(isSkipResendCache: Bool = false) {
        AmityUIKitManagerInternal.shared.clearCache(isSkipResendCache: isSkipResendCache)
    }
    
    /// Registers this device for receiving apple push notification
    /// - Parameter deviceToken: Correct apple push notificatoin token received from the app.
    public static func registerDeviceForPushNotification(_ deviceToken: String, completion: AmityRequestCompletion? = nil) {
        AmityUIKitManagerInternal.shared.registerDeviceForPushNotification(deviceToken, completion: completion)
    }
    
    /// Unregisters this device for receiving push notification related to AmitySDK.
    public static func unregisterDevicePushNotification(completion: AmityRequestCompletion? = nil) {
        let currentUserId = AmityUIKitManagerInternal.shared.currentUserId
        Task { @MainActor in
            do {
                let success = try await AmityUIKitManagerInternal.shared.unregisterDevicePushNotification(for: currentUserId)
                completion?(success, nil)
            } catch let error {
                completion?(false, error)
            }
        }
    }
    
    public static func setEnvironment(_ env: [String: Any]) {
        AmityUIKitManagerInternal.shared.env = env
    }
    
    public static func isInitialClient() -> Bool {
        AmityUIKitManagerInternal.shared.isInitialClient()
    }
    
    public static func isModeratorUserInCommunity(withUserId userId: String, communityId: String) -> Bool {
        let membershipParticipation = AmityCommunityMembership(client: AmityUIKitManagerInternal.shared.client, andCommunityId: communityId)
        let member = membershipParticipation.getMember(withId: userId)
        return member?.hasModeratorRole ?? false
    }
    
    // MARK: - Variable
    
    /// Public instance of `AmityClient` from `AmitySDK`. If you are using both`AmitySDK` & `AmityUIKit` in a same project, we recommend to have only one instance of `AmityClient`. You can use this instance instead.
    public static var client: AmityClient {
        return AmityUIKitManagerInternal.shared.client
    }
    
    public static var feedUISettings: AmityFeedUISettings {
        return AmityFeedUISettings.shared
    }
    
    static var bundle: Bundle {
        return Bundle(for: self)
    }
    
    // [Custom for ONE Krungthai] Add current user token property for use request custom API
    public static var currentUserToken: String {
        return AmityUIKitManagerInternal.shared.currentUserToken
    }
    
    public static var displayName: String {
        return AmityUIKitManagerInternal.shared.displayName
    }
    
    public static var currentUserId: String {
        return AmityUIKitManagerInternal.shared.currentUserId
    }
    
    public static var avatarURL: String {
        return AmityUIKitManagerInternal.shared.avatarURL
    }
    
    public static var isHaveCreateBroadcastPermission: Bool {
        return AmityUIKitManagerInternal.shared.isHaveCreateBroadcastPermission
    }
    
    // [Custom for ONE Krungthai] Add env property for get env for use some function
    public static var env: [String: Any] {
        return AmityUIKitManagerInternal.shared.env
    }
    
    public static var apiKey: String {
        return AmityUIKitManagerInternal.shared.apiKey
    }
    
    // MARK: - Helper methods
    
    public static func set(theme: AmityTheme) {
        AmityThemeManager.set(theme: theme)
    }
    
    public static func set(typography: AmityTypography) {
        AmityFontSet.set(typography: typography)
    }
    
    public static func set(eventHandler: AmityEventHandler) {
        AmityEventHandler.shared = eventHandler
    }
    
    public static func set(channelEventHandler: AmityChannelEventHandler) {
        AmityChannelEventHandler.shared = channelEventHandler
    }
    
    // [Improvement] Add function for update file repository when session state is established and don't want to register device again
    public static func updateFileRepository() {
        AmityUIKitManagerInternal.shared.didUpdateClient()
    }
    
    public static func retrieveNotifcationSettings(completion: @escaping (Result<AmityUserNotificationSettings, Error>) -> Void) {
        let userNotificationController = AmityUserNotificationSettingsController()
        userNotificationController.retrieveNotificationSettings { result in
            switch result {
            case .success(let notification):
                completion(.success(notification))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public static func enableSocialNotificationSetting() {
        let userNotificationManager = client.notificationManager
        userNotificationManager.enable(for: [AmityUserNotificationModule(moduleType: .social, isEnabled: true, roleFilter: nil)]) { _, _ in }
    }
    
    public static func disableSocialNotificationSetting() {
        let userNotificationManager = client.notificationManager
        userNotificationManager.enable(for: [AmityUserNotificationModule(moduleType: .social, isEnabled: false, roleFilter: nil)]) { _, _ in }
    }
    
    public static func enableChatNotificationSetting() {
        AmityUIKitManagerInternal.shared.enableChatNotificationSetting()
    }
    
    public static func disableChatNotificationSetting() {
        AmityUIKitManagerInternal.shared.disableChatNotificationSetting()
    }
    
    /* Not used is for back up only */
    public static func clearCustomTempData() {
        AmityUIKitManagerInternal.shared.clearCustomTempData()
    }
    
    public static func checkPresenceStatus() {
        Task {
            do {
                let isEnable = try await client.presence.isEnabled()
                print("------> User presence \(isEnable)")
            } catch let error {
                print(error)
            }
        }
    }
    
    public static func enablePresenceStatus() {
        Task {
            do {
                try await client.presence.enable()
            } catch let error {
                print(error)
            }
        }
    }
    
    public static func startHeartbeat() {
        Task {
            do {
                try await client.presence.startHeartbeat()
            } catch let error {
                print(error)
            }
        }
    }
    
    public static func stopHeartbeat() {
        client.presence.stopHeartbeat()
    }
    public static func enableUnreadCount() {
        client.enableUnreadCount()
    }
    
    public static func createChannel(_ source: UIViewController,userId: String) {
        AmityUIKitManagerInternal.shared.getUser(source, userId: userId)
    }
    
    public static func totalUnreadCount() -> Int {
        return AmityUIKitManagerInternal.shared.totalUnreadCount
    }
    
    public static func getUnreadCount() {
        AmityUIKitManagerInternal.shared.getTotalUnreadCount()
    }
    
    public static func setUnreadCount(unreadCount: Int) {
        AmityUIKitManagerInternal.shared.totalUnreadCount = unreadCount
    }
    
    public static func getSyncAllChannelPresence() {
        AmityUIKitManagerInternal.shared.getSyncAllChannelPresence()
    }
    
    public static func syncChannelPresence(_ channelId: String) {
        AmityUIKitManagerInternal.shared.syncChannelPresence(channelId)
    }
    
    public static func unsyncChannelPresence(_ channelId: String) {
        AmityUIKitManagerInternal.shared.unsyncChannelPresence(channelId)
    }
    
    public static func unsyncAllChannelPresence() {
        AmityUIKitManagerInternal.shared.unsyncAllChannelPresence()
    }
    
    public static func getOnlinePresencesList() -> [AmityChannelPresence] {
        AmityUIKitManagerInternal.shared.onlinePresences
    }
    
    public static func checkOnlinePresence(channelId: String) -> Bool {
        let onlinePresences = AmityUIKitManagerInternal.shared.onlinePresences
        let isOnline = onlinePresences.contains { $0.channelId == channelId }
        
        return isOnline
    }

    public static func setASMRemoteConfig(_ isEnableMenu: Bool) {
        AmityUIKitManagerInternal.shared.isEnableMenu = isEnableMenu
    }

    //ktb kk custom share menu
    public static func getShareExternalURL(post: AmityPostModel) -> String {
        let externalURL = AmityURLCustomManager.ExternalURL.generateExternalURLOfPost(post: post)
        return externalURL
    }

}

final class AmityUIKitManagerInternal: NSObject {
    
    // MARK: - Properties
    
    public static let shared = AmityUIKitManagerInternal()
    private var _client: AmityClient?
    var apiKey: String = ""
    private var notificationTokenMap: [String: String] = [:]
    
    private(set) var fileService = AmityFileService()
    private(set) var messageMediaService = AmityMessageMediaService()
    private(set) var userRepository: AmityUserRepository?
    private(set) var channelRepository: AmityChannelRepository?
    private(set) var channelPresenceRepo: AmityChannelPresenceRepository?

    var currentUserId: String { return client.currentUserId ?? "" }
    var displayName: String {
        if let displayName = client.user?.snapshot?.displayName {
            cacheDisplayName = displayName
            return displayName
        } else {
            return cacheDisplayName
        }
    }
    private var cacheDisplayName: String = ""
    var avatarURL: String { return client.user?.snapshot?.getAvatarInfo()?.fileURL ?? "" }
    var userStatus: AmityUserStatus.StatusType = .AVAILABLE
    var currentStatus: String { return client.user?.snapshot?.metadata?["user_presence"] as? String ?? "available" }

    private var userToken: String = ""
    public var currentUserToken: String { return self.userToken }
    
    private var userCollectionToken: AmityNotificationToken?
    private var channelCollectionToken: AmityNotificationToken?
    private var broadcastChannelCollectionToken: AmityNotificationToken?
    private var disposeBag: Set<AnyCancellable> = []
    private var postIdCannotGetSnapshotList: [String] = []
    
    var totalUnreadCount: Int = 0
    var isSyncingAllChannelPresence: Bool = false
    var onlinePresences: [AmityChannelPresence] = []
    var onlinePresencesDataHash: Int = -1
    var limitFileSize: Double? // .mb
    var isHaveCreateBroadcastPermission: Bool = false
    private let dispatchGroup = DispatchGroup()

    var client: AmityClient {
        guard let client = _client else {
            fatalError("Something went wrong. Please ensure `AmityUIKitManager.setup(:_)` get called before accessing client.")
        }
        return client
    }
    
    var env: [String: Any] = [:]
    
    var isEnableMenu: Bool = true
    
    // MARK: - Initializer
    
    private override init() { }
    
    // MARK: - Setup functions

    func setup(apiKey: String, region: AmityRegion, completion: @escaping (Result<Bool, Error>) -> Void) {
        enum SetupError: Error {
            case clientInitializationFailed
        }
        guard let client = try? AmityClient(apiKey: apiKey, region: region) else {
            completion(.failure(SetupError.clientInitializationFailed))
            return
        }
        
        _client = client
        _client?.delegate = self
        
        // [Custom for ONE Krungthai] Set apiKey for use some function of AmitySDK
        self.apiKey = apiKey
        
        
        completion(.success(true))
    }
    
    func setup(_ apiKey: String, endpoint: AmityEndpoint) { 
        guard let client = try? AmityClient(apiKey: apiKey, endpoint: endpoint) else { return }
        
        _client = client
        _client?.delegate = self
        
        // [Custom for ONE Krungthai] Set apiKey for use some function of AmitySDK
        self.apiKey = apiKey
    }
    
    func isInitialClient() -> Bool { _client != nil }
    
//    func registerDevice(_ userId: String,
//                        displayName: String?,
//                        authToken: String?,
//                        sessionHandler: SessionHandler,
//                        completion: AmityRequestCompletion?) {
//
//        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: client.login, parameters: (userId: userId, displayName: displayName, authToken: authToken, sessionHandler: sessionHandler)) { [weak self] success, error in
//            if let error = error {
//                completion?(false, error)
//                return
//            }
////            self?.revokeDeviceTokens()
//            self?.didUpdateClient()
//
//            // [Custom for ONE Krungthai] Add register user token function for request custom API
//            self?.registerUserToken(userId: userId, authToken: authToken ?? "")
//
//            // [Custom for ONE Krungthai] [Temp] Disable livestream user level notification
//            self?.disableLivestreamUserLevelNotification()
//
//            self?.clearCache(isSkipResendCache: true)
//
//            self?.cacheDisplayName = ""
//
//            self?.getCreateBroadcastMessagePermission()
//
//            completion?(true, error)
//        }
//    }
    
    func registerDevice(_ userId: String,
                        displayName: String?,
                        authToken: String?,
                        sessionHandler: SessionHandler,
                        completion: AmityRequestCompletion?) {
        Task { @MainActor in
            do {
                try await client.login(userId: userId, displayName: displayName, authToken: authToken, sessionHandler: sessionHandler)
                await revokeDeviceTokens()
                didUpdateClient()
                completion?(true, nil)
            } catch let error {
                completion?(false, error)
            }
        }
    }
    
    func unregisterDevice() {
        AmityFileCache.shared.clearCache()
        self._client?.logout()
    }
    
    func clearCache(isSkipResendCache: Bool = false) {
        AmityFileCache.shared.clearCache(isSkipResendCache: isSkipResendCache)
    }
    
    func registerDeviceForPushNotification(_ deviceToken: String, completion: AmityRequestCompletion? = nil) {
        // It's possible that `deviceToken` can be changed while user is logging in.
        // To prevent user from registering notification twice, we will revoke the current one before register new one.
        Task { @MainActor in
            do {
                await revokeDeviceTokens()
                
                let success = try await client.registerPushNotification(withDeviceToken: deviceToken)
                
                if success, let currentUserId = _client?.currentUserId {
                    // if register device successfully, binds device token to user id.
                    notificationTokenMap[currentUserId] = deviceToken
                }
                completion?(success, nil)
            } catch let error {
                completion?(false, error)
            }

        }
    }
    
    @MainActor
    func unregisterDevicePushNotification(for userId: String) async throws -> Bool {
        
        do {
            let success = try await client.unregisterPushNotification(forUserId: userId)
            if success, let currentUserId = self._client?.currentUserId {
                // if unregister device successfully, remove device token belonging to the user id.
                self.notificationTokenMap[currentUserId] = nil
            }
            return success

        } catch {
            return false
        }
    }
    
    // [Custom for ONE Krungthai] Add register user token function for request custom API
    func registerUserToken(userId: String, authToken: String) {
        Task {
            do {
                let auth = try await AmityUserTokenManager(apiKey: apiKey, region: .SG).createUserToken(userId: userId, authToken: authToken)
                userToken = auth.accessToken
                
                // [Custom for ONE Krungthai] Get custom limit file size setting after register user token
                getCustomLimitFileSizeSetting()
            } catch let _ {
            }
        }
    }
    
    // [Custom for ONE Krungthai] [Temp] Disable livestream user level notification
    func disableLivestreamUserLevelNotification() {
        let userNotificationManager = client.notificationManager
        
        userNotificationManager.enable(for: [AmityUserNotificationModule(moduleType: .videoStreaming, isEnabled: false, roleFilter: nil)]) { result, error in
            print("[Livestream-notification] Disable livestream user level notification result : \(result)")
        }
    }
    
    func enableChatNotificationSetting() {
        let userNotificationManager = client.notificationManager
        let moduleSettings = [
            AmityUserNotificationModule(moduleType: .chat, isEnabled: true, roleFilter: nil)
        ]
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: userNotificationManager.enable(for:), parameters: moduleSettings) { result, error in
            if let error = error {
                print("[Notification] Enable chat user level notification fail with error : \(error.localizedDescription)")
            } else if let result = result {
                print("[Notification] Enable chat user level notification result : \(result)")
            }
        }
    }
    
    func disableChatNotificationSetting() {
        let userNotificationManager = client.notificationManager
        let moduleSettings = [
            AmityUserNotificationModule(moduleType: .chat, isEnabled: false, roleFilter: nil)
        ]
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: userNotificationManager.enable(for:), parameters: moduleSettings) { result, error in
            if let error = error {
                print("[Notification] Disable chat user level notification fail with error : \(error.localizedDescription)")
            } else if let result = result {
                print("[Notification] Disable chat user level notification result : \(result)")
            }
        }
    }
    
    func getCustomLimitFileSizeSetting() {
        let request = RequestCustomSettings()
        request.requestLimitFileSizeSetting { [weak self] result in
            guard let weakSelf = self else { return }
            switch result {
            case .success(let data):
                weakSelf.limitFileSize = data.limitFileSize
                print("[RequestCustomSettings] Get limit file size success with value: \(data.limitFileSize) mb")
            case .failure(let error):
                print("[RequestCustomSettings] Get limit file size fail with error: \(error.localizedDescription)")
                break
            }
        }
    }
    
    func getCreateBroadcastMessagePermission() {
        // Set default value back to false before get new one
        isHaveCreateBroadcastPermission = false
        
        // Query broadcast channels
        guard let channelRepo = channelRepository, let client = _client else { return }
        let query = AmityChannelQuery()
        query.filter = .userIsMember
        query.includeDeleted = false
        query.types = [AmityChannelQueryType.broadcast]
        let channelsCollection = channelRepo.getChannels(with: query)
        
        // Check each group that have channel-moderator role
        broadcastChannelCollectionToken = channelsCollection.observe { [weak self] (collection, change, error) in
            guard let strongSelf = self else { return }
            
            // Get permission each channel
            let channelModels = collection.allObjects().map( { AmityChannelModel(object: $0) } )
            for channel in channelModels {
                client.hasPermission(.editChannel, forChannel: channel.channelId) { isHavePermission in
                    if isHavePermission {
                        self?.isHaveCreateBroadcastPermission = true
                    }
                }
            }
        }
    }
    
    public func getUser(_ source: UIViewController, userId: String) {
        AmityEventHandler.shared.showKTBLoading()
        guard let userRepo = userRepository else { return }
        userCollectionToken = userRepo.getUser(userId).observe { [weak self] object, error in
            guard let strongSelf = self else { return }
            if let user = object.snapshot {
                let userModel = AmityUserModel(user: user)
                strongSelf.userCollectionToken?.invalidate()
                strongSelf.createChannel(source, user: userModel)
            }
        }
    }
    
    func createChannel(_ source: UIViewController, user: AmityUserModel) {
        guard let channelRepo = channelRepository else { return }
        let userIds: [String] = [user.userId, currentUserId]
        let builder = AmityConversationChannelBuilder()
        builder.setUserId(user.userId)
        builder.setDisplayName(user.displayName)
        builder.setMetadata(["user_id_member": userIds])
                
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: channelRepo.createChannel, parameters: builder) { [weak self] channelObject, _ in
            if let channel = channelObject {
                AmityEventHandler.shared.hideKTBLoading()
                AmityChannelEventHandler.shared.channelDidTap(from: source, channelId: channel.channelId, subChannelId: channel.defaultSubChannelId)
            }
        }
    }
    
    func getTotalUnreadCount() {
        client.getUserUnread().sink(receiveValue: { [weak self] userUnread in
            guard let strongSelf = self else { return }
            strongSelf.totalUnreadCount = userUnread.unreadCount
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RefreshNotification"), object: nil)
        }).store(in: &disposeBag)
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func revokeDeviceTokens() async {
        
        await withThrowingTaskGroup(of: Bool.self, body: { group in
            for (userId, _) in notificationTokenMap {
                group.addTask {
                    try await self.unregisterDevicePushNotification(for: userId)
                }
            }
        })
            
    }
    
    func didUpdateClient() {
        // Update file repository to use in file service.
        fileService.fileRepository = AmityFileRepository(client: client)
        messageMediaService.fileRepository = AmityFileRepository(client: client)
        userRepository = AmityUserRepository(client: client)
        channelRepository = AmityChannelRepository(client: client)
        channelPresenceRepo = AmityChannelPresenceRepository(client: client)
    }
    
    func getSyncAllChannelPresence() {
        if !isSyncingAllChannelPresence {
            isSyncingAllChannelPresence = true
            channelPresenceRepo?.getSyncingChannelPresence().sink { completion in
                // Handle completion
                switch completion {
                case .failure(let error):
//                    print("-------------------> [Status] Start getSyncAllChannelPresence fail with error: \(error.localizedDescription)")
                    print("\(error.localizedDescription)")
                default:
//                    print("-------------------> [Status] Start getSyncAllChannelPresence success")
                    print("[Amity SDK] getSyncingChannelPresence finish")
                }
            } receiveValue: { presences in
                /// Channel presences where any other member is online
                let onlinePresences = presences.filter { $0.isAnyMemberOnline }
//                print("-------------------> [Status] Receive new onlinePresences")
//                for user in onlinePresences {
//                    print("[Status] \(user.channelId) is online")
//                }
                /// Check different of new and current onlinePresences data for prevent refresh channel presence too frequently
                if self.onlinePresencesDataHash != onlinePresences.hashValue {
//                    print("[Status] have any update onlinePresences -> update online presences")
                    self.onlinePresencesDataHash = onlinePresences.hashValue
                    self.onlinePresences = onlinePresences
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RefreshChannelPresence"), object: nil)
                }
//                print("-------------------- [Status] -------------------------->")
            }.store(in: &disposeBag)
        }
    }
    
    func syncChannelPresence(_ channelId: String) {
        channelPresenceRepo?.syncChannelPresence(id: channelId)
//        print("-------------------> [Status] Start syncChannelPresence id \(channelId) success")
    }
    
    func unsyncChannelPresence(_ channelId: String) {
        channelPresenceRepo?.unsyncChannelPresence(id: channelId)
//        print("-------------------> [Status] Start unsyncChannelPresence id \(channelId) success")
    }
    
    func unsyncAllChannelPresence() {
        isSyncingAllChannelPresence = false
        channelPresenceRepo?.unsyncAllChannelPresence()
//        print("-------------------> [Status] Start unsyncAllChannelPresence success")
    }
}

// Handle post id can't get snapshot
extension AmityUIKitManagerInternal {
    func addPostIdCannotGetSnapshot(postId: String) {
        postIdCannotGetSnapshotList.append(postId)
    }
    
    func getPostIdsCannotGetSnapshot() -> [String] {
        return postIdCannotGetSnapshotList
    }
}

/* Not used is for back up only */
// Custom temp data
extension AmityUIKitManagerInternal {
    func clearCustomTempData() {
        // Clear all temp send file message data (delete custom temp folder)
        AmityTempSendFileMessageData.shared.removeAll()
    }
}

extension AmityUIKitManagerInternal: AmityClientDelegate {
    func didReceiveError(error: Error) {
        if !error.isAmityErrorCode(.globalBan) {
            AmityHUD.show(.error(message: error.localizedDescription))
        }
    }
    
}

extension AmityClient {
    var isEstablished: Bool {
        switch sessionState {
        case .established:
            return true
        default:
            return false
        }
    }
}
