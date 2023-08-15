//
//  AmityUIKit.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 2/6/2563 BE.
//  Copyright © 2563 Amity Communication. All rights reserved.
//

import UIKit
import AmitySDK

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
    public static func setup(apiKey: String, region: AmityRegion = .global) {
        AmityUIKitManagerInternal.shared.setup(apiKey, region: region)
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
        AmityUIKitManagerInternal.shared.registerDevice(userId, displayName: displayName, authToken: authToken, sessionHandler: sessionHandler, completion: completion)
    }
    
    /// Unregisters current user. This removes all data related to current user & terminates conenction with server. This is analogous to "logout" process.
    /// Once this method is called, the only way to re-establish connection would be to call `registerDevice` method again.
    ///
    /// Note:
    /// You do not need to call this method before calling `registerDevice`.
    public static func unregisterDevice() {
        AmityUIKitManagerInternal.shared.unregisterDevice()
    }
    
    
    /// Registers this device for receiving apple push notification
    /// - Parameter deviceToken: Correct apple push notificatoin token received from the app.
    public static func registerDeviceForPushNotification(_ deviceToken: String, completion: AmityRequestCompletion? = nil) {
        AmityUIKitManagerInternal.shared.registerDeviceForPushNotification(deviceToken, completion: completion)
    }
    
    /// Unregisters this device for receiving push notification related to AmitySDK.
    public static func unregisterDevicePushNotification(completion: AmityRequestCompletion? = nil) {
        let currentUserId = AmityUIKitManagerInternal.shared.currentUserId
        AmityUIKitManagerInternal.shared.unregisterDevicePushNotification(for: currentUserId, completion: completion)
    }
    
    public static func setEnvironment(_ env: [String: Any]) {
        AmityUIKitManagerInternal.shared.env = env
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
    
    public static var avatarURL: String {
        return AmityUIKitManagerInternal.shared.avatarURL
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
}

final class AmityUIKitManagerInternal: NSObject {
    
    // MARK: - Properties
    
    public static let shared = AmityUIKitManagerInternal()
    private var _client: AmityClient?
    var apiKey: String = ""
    private var notificationTokenMap: [String: String] = [:]
    
    private(set) var fileService = AmityFileService()
    private(set) var messageMediaService = AmityMessageMediaService()
    
    var currentUserId: String { return client.currentUserId ?? "" }
    var displayName: String { return client.user?.object?.displayName ?? "" }
    var avatarURL: String { return client.user?.object?.getAvatarInfo()?.fileURL ?? "" }

    var userToken: String = ""
    public var currentUserToken: String { return self.userToken }
    
    var client: AmityClient {
        guard let client = _client else {
            fatalError("Something went wrong. Please ensure `AmityUIKitManager.setup(:_)` get called before accessing client.")
        }
        return client
    }
    
    var env: [String: Any] = [:]
    
    // MARK: - Initializer
    
    private override init() { }
    
    // MARK: - Setup functions

    func setup(_ apiKey: String, region: AmityRegion) {
        guard let client = try? AmityClient(apiKey: apiKey, region: region) else { return }
        
        _client = client
        _client?.delegate = self
        
        // [Custom for ONE Krungthai] Set apiKey for use some function of AmitySDK
        self.apiKey = apiKey
    }
    
    func setup(_ apiKey: String, endpoint: AmityEndpoint) {
        guard let client = try? AmityClient(apiKey: apiKey, endpoint: endpoint) else { return }
        
        _client = client
        _client?.delegate = self
        
        // [Custom for ONE Krungthai] Set apiKey for use some function of AmitySDK
        self.apiKey = apiKey
    }
    
    func registerDevice(_ userId: String,
                        displayName: String?,
                        authToken: String?,
                        sessionHandler: SessionHandler,
                        completion: AmityRequestCompletion?) {
        
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: client.login, parameters: (userId: userId, displayName: displayName, authToken: authToken, sessionHandler: sessionHandler)) { [weak self] success, error in
            if let error = error {
                completion?(false, error)
                return
            }
            self?.revokeDeviceTokens()
            self?.didUpdateClient()
            
            // [Custom for ONE Krungthai] Add register user token function for request custom API
            self?.registerUserToken(userId: userId, authToken: authToken ?? "")
            
            // [Custom for ONE Krungthai] [Temp] Disable livestream user level notification
            self?.disableLivestreamUserLevelNotification()
            
            completion?(true, error)
        }
    }
    
    func unregisterDevice() {
        AmityFileCache.shared.clearCache()
        self._client?.logout()
    }
    
    func registerDeviceForPushNotification(_ deviceToken: String, completion: AmityRequestCompletion? = nil) {
        // It's possible that `deviceToken` can be changed while user is logging in.
        // To prevent user from registering notification twice, we will revoke the current one before register new one.
        revokeDeviceTokens()
        
        _client?.registerDeviceForPushNotification(withDeviceToken: deviceToken) { [weak self] success, error in
            if success, let currentUserId = self?._client?.currentUserId {
                // if register device successfully, binds device token to user id.
                self?.notificationTokenMap[currentUserId] = deviceToken
            }
            completion?(success, error)
        }
    }
    
    func unregisterDevicePushNotification(for userId: String, completion: AmityRequestCompletion? = nil) {
        client.unregisterDeviceForPushNotification(forUserId: userId) { [weak self] success, error in
            if success, let currentUserId = self?._client?.currentUserId {
                // if unregister device successfully, remove device token belonging to the user id.
                self?.notificationTokenMap[currentUserId] = nil
            }
            completion?(success, error)
        }
    }
    
    // [Custom for ONE Krungthai] Add register user token function for request custom API
    func registerUserToken(userId: String, authToken: String) {
        Task {
            do {
                let auth = try await AmityUserTokenManager(apiKey: apiKey, region: .SG).createUserToken(userId: userId, authToken: authToken)
                userToken = auth.accessToken
            } catch let error {
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
    
    // MARK: - Helpers
    
    private func revokeDeviceTokens() {
        for (userId, _) in notificationTokenMap {
            unregisterDevicePushNotification(for: userId, completion: nil)
        }
    }
    
    func didUpdateClient() {
        // Update file repository to use in file service.
        fileService.fileRepository = AmityFileRepository(client: client)
        messageMediaService.fileRepository = AmityFileRepository(client: client)
    }
    
}

extension AmityUIKitManagerInternal: AmityClientDelegate {
    func didReceiveError(error: Error) {
        AmityHUD.show(.error(message: error.localizedDescription))
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
