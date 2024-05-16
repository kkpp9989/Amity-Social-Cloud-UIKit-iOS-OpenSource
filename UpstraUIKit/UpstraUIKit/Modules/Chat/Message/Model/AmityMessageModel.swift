//
//  AmityMessageModel.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 17/8/2563 BE.
//  Copyright © 2563 Amity Communication. All rights reserved.
//

import UIKit
import AmitySDK

public final class AmityMessageModel {
    
    public var object: AmityMessage
    public var messageId: String
    public var userId: String
    public var displayName: String?
    public var syncState: AmitySyncState
    public var isDeleted: Bool
    public var isEdited: Bool
    public var flagCount: UInt
    public var messageType: AmityMessageType
    public var createdAtDate: Date
    public var date: String
    public var time: String
    public var data: [AnyHashable : Any]?
    public var tags: [String]
    public var channelSegment: UInt
	public let metadata: [String: Any]?
	public let mentionees: [AmityMentionees]?
    public let parentId: String?
    public var parentMessageObjc: AmityMessage?
    public var readCount: Int?
    public var isFlaggedByMe: Bool = false
	
    /**
     * The post appearance settings
     */
    public var appearance: AmityMessageModelAppearance
    
    public var isOwner: Bool {
        return userId == AmityUIKitManagerInternal.shared.client.currentUserId
    }
    
    private let messageRepository = AmityMessageRepository(client: AmityUIKitManagerInternal.shared.client)
    private var messageToken: AmityNotificationToken?
    
    public init(object: AmityMessage) {
        self.object = object
        self.messageId = object.messageId
        self.userId = object.userId
        self.displayName = object.user?.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString
        self.syncState = object.syncState
        self.isDeleted = object.isDeleted
        self.isEdited = object.isEdited
        self.messageType = object.messageType
        self.createdAtDate = object.createdAt
        self.date = AmityDateFormatter.Message.getDate(date: object.createdAt)
        self.time = AmityDateFormatter.Message.getTime(date: object.createdAt)
        self.flagCount = UInt(object.flagCount)
        self.data = object.data
        self.tags = object.tags
        self.channelSegment = UInt(object.channelSegment)
        self.appearance = AmityMessageModelAppearance()
		self.metadata = object.metadata
		self.mentionees = object.mentionees
        self.parentId = object.parentId
        self.readCount = object.readCount
        self.getParentMessage { result in
            self.parentMessageObjc = result
            self.messageToken?.invalidate()
        }
        self.getFlaggedData()
    }
    
    public var text: String? {
        return data?["text"] as? String
    }
    
    public var imageCaption: String? {
        if let caption = data?["caption"] as? String, caption != "" {
            return caption
        } else {
            return nil
        }
    }
}

extension AmityMessageModel {
    
    // MARK: - Appearance
    
    open class AmityMessageModelAppearance {
        
        public init () { }
        /**
         * The flag marking a message for how it will display
         *  - true : display a full content
         *  - false : display a partial content with read more button
         */
        public var isExpanding: Bool = false
    }
    
}

extension AmityMessageModel: Hashable {
    
    public static func == (lhs: AmityMessageModel, rhs: AmityMessageModel) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(messageId)
        hasher.combine(userId)
        hasher.combine(displayName)
        hasher.combine(syncState)
        hasher.combine(isDeleted)
        hasher.combine(isEdited)
        hasher.combine(flagCount)
        hasher.combine(messageType)
        hasher.combine(createdAtDate)
        hasher.combine(date)
        hasher.combine(time)
        hasher.combine(text)
        hasher.combine(tags)
        hasher.combine(channelSegment)
        hasher.combine(readCount)
        if let dataDesc = data?.description {
            hasher.combine(dataDesc)
        }
    }
    
}

extension AmityMessageModel {
    private func getParentMessage(completion: @escaping (AmityMessage?) -> Void) {
        if let cachedMessage = MessageCacheManager.shared.getMessageFromCache(parentId ?? "") {
            // If the message is cached, use it directly
            completion(cachedMessage)
        } else {
            // If not cached, fetch it from the repository
            guard let parentId = parentId else {
                completion(nil)
                return
            }
            messageToken = messageRepository.getMessage(parentId).observeOnce { (message, error) in
                if let message = message.snapshot {
                    // Cache the fetched message
                    MessageCacheManager.shared.cacheMessage(parentId, message: message)
                    completion(message)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    private func getFlaggedData() {
        Task { @MainActor in
            do {
                let isFlaggedByMe = try await messageRepository.isMessageFlaggedByMe(withId: self.messageId)
                self.isFlaggedByMe = isFlaggedByMe
            } catch {
                self.isFlaggedByMe = false
            }
        }
    }
}

// Create a simple cache manager
class MessageCacheManager {
    static let shared = MessageCacheManager()
    
    private var messageCache: [String: AmityMessage] = [:]
    
    func cacheMessage(_ messageId: String, message: AmityMessage) {
        messageCache[messageId] = message
    }
    
    func getMessageFromCache(_ messageId: String) -> AmityMessage? {
        return messageCache[messageId]
    }
}
