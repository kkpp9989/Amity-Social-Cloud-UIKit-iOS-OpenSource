//
//  AmityMessageListScreenViewModel.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 5/8/2563 BE.
//  Copyright © 2563 Amity Communication. All rights reserved.
//

import UIKit
import Photos
import AmitySDK

final class AmityMessageListScreenViewModel: AmityMessageListScreenViewModelType {
    
    enum Route {
        case pop
    }
    
    enum Events {
        case updateMessages
        case didSendText
        case didEditText
        case didDelete(indexPath: IndexPath)
        case didDeeleteErrorMessage(indexPath: IndexPath)
        case didSendImage
        case didUploadImage(indexPath: IndexPath)
        case didSendAudio
    }
    
    enum AudioRecordingEvents {
        case show
        case hide
        case deleting
        case cancelingDelete
        case delete
        case record
        case timeoutRecord
    }

    enum CellEvents {
        case edit(indexPath: IndexPath)
        case delete(indexPath: IndexPath)
        case deleteErrorMessage(indexPath: IndexPath)
        case report(indexPath: IndexPath)
        case imageViewer(indexPath: IndexPath, imageView: UIImageView)
        case videoViewer(indexPath: IndexPath)
        case fileDownloader(indexPath: IndexPath)
        case forward(indexPath: IndexPath)
        case copy(indexPath: IndexPath)
        case reply(indexPath: IndexPath)
        case jumpReply(indexPath: IndexPath)
        case avatar(indexPath: IndexPath)
    }
    
    enum KeyboardInputEvents {
        case `default`, composeBarMenu, audio
    }
    
    weak var delegate: AmityMessageListScreenViewModelDelegate?
        
    // MARK: - Repository
    private let subChannelRepository: AmitySubChannelRepository!
    private var membershipParticipation: AmityChannelParticipation?
    private let channelRepository: AmityChannelRepository!
    private var messageRepository: AmityMessageRepository!
    private var userRepository: AmityUserRepository!
    private var editor: AmityMessageEditor?
    private var messageFlagger: AmityMessageFlagger?
    
    // MARK: - Collection
    private var messagesCollection: AmityCollection<AmityMessage>?
    
    // MARK: - Notification Token
    private var subChannelNotificationToken: AmityNotificationToken?
    private var channelNotificationToken: AmityNotificationToken?
    private var messagesNotificationToken: AmityNotificationToken?
    private var createMessageNotificationToken: AmityNotificationToken?
    private var userNotificationToken: AmityNotificationToken?
    private var navigatingNotificationToken: AmityNotificationToken?
    
    private var messageAudio: AmityMessageAudioController?
    
    // MARK: - Properties
    private let channelId: String
    private let subChannelId: String
    private var isFirstTimeLoaded: Bool = true
    
    private let debouncer = Debouncer(delay: 0.6)
    private var dataSourceHash: Int = -1 // to track if data source changes
    private var lastMessageHash: Int = -1 // to track if the last message changes
    private var didEnterBackgroundObservation: NSObjectProtocol?
    private var connectionObservation: NSKeyValueObservation?
    private var lastNotOnline: Date?
    private var lastEnterBackground: Date?
    
    private let dispatchGroup = DispatchGroup()

    init(channelId: String, subChannelId: String) {
        self.channelId = channelId
        self.subChannelId = subChannelId
        membershipParticipation = AmityChannelParticipation(client: AmityUIKitManagerInternal.shared.client, andChannel: channelId)
        channelRepository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
        messageRepository = AmityMessageRepository(client: AmityUIKitManagerInternal.shared.client)
        subChannelRepository = AmitySubChannelRepository(client: AmityUIKitManagerInternal.shared.client)
    }
    
    // MARK: - DataSource
    private let queue = OperationQueue()
    private var messages: [[AmityMessageModel]] = []
    private var unsortedMessages: [AmityMessageModel] = []
    private var keyboardEvents: KeyboardInputEvents = .default
    private var keyboardVisible: Bool = false
    private var text: String = "" {
        didSet {
            delegate?.screenViewModelDidTextChange(text: text)
        }
    }
    
    private var channelType: AmityChannelType = .conversation
    
    private var subChannel: AmitySubChannel?
    private var forwardMessageList: [AmityMessageModel] = []
    
    private(set) var allCellNibs: [String: UINib] = [:]
    private(set) var allCellClasses: [String: AmityMessageCellProtocol.Type] = [:]
    
    func message(at indexPath: IndexPath) -> AmityMessageModel? {
        guard !messages.isEmpty else { return nil }
        return messages[indexPath.section][indexPath.row]
    }
    
    func isKeyboardVisible() -> Bool {
        return keyboardVisible
    }
    
    func numberOfSection() -> Int {
        return messages.count
    }
    
    func numberOfMessages() -> Int {
        return messages.reduce(0, { $0 + $1.count })
    }
    
    func numberOfMessage(in section: Int) -> Int {
        return messages[section].count
    }
    
    func getChannelId() -> String {
        return channelId
    }
    
    func getCommunityId() -> String {
        return channelId
    }
    
    func getChannelType() -> AmityChannelType {
        return channelType
    }
    
    func findIndexPath(forMessageId messageId: String) -> IndexPath? {
        for (section, messageSection) in messages.enumerated() {
            if let row = messageSection.firstIndex(where: { $0.messageId == messageId }) {
                return IndexPath(row: row, section: section)
            }
        }
        return nil  // Message not found
    }
}

// MARK: - Action
extension AmityMessageListScreenViewModel {
    
    func registerCellNibs() {
        AmityMessageTypes.allCases.forEach { item in
            if allCellNibs[item.identifier] == nil {
                allCellNibs[item.identifier] = item.nib
                allCellClasses[item.identifier] = item.class
            }
        }
    }
    
    func register(items: [AmityMessageTypes : AmityMessageCellProtocol.Type]) {
        for (key, _) in allCellNibs {
            for item in items {
                if item.key.identifier == key {
                    allCellNibs[key] = UINib(nibName: item.value.cellIdentifier, bundle: nil)
                    allCellClasses[key] = item.value
                }
            }
        }
        
    }
    
    func route(for route: Route) {
        delegate?.screenViewModelRoute(route: route)
    }
    
    func setText(withText text: String?) {
        guard let text = text else { return }
        self.text = text
    }
    
    func getChannel(){
        channelNotificationToken?.invalidate()
        channelNotificationToken = channelRepository.getChannel(channelId).observe { [weak self] (channel, error) in
            guard let object = channel.snapshot else { return }
            let channelModel = AmityChannelModel(object: object)
            self?.channelType = channelModel.channelType
            self?.delegate?.screenViewModelDidGetChannel(channel: channelModel)
        }
    }
    
    func getSubChannel(){
        subChannelNotificationToken?.invalidate()
        subChannelNotificationToken = subChannelRepository.getSubChannel(withId: subChannelId).observe { [weak self] (subChannel, error) in
            guard let object = subChannel.snapshot else { return }
            self?.subChannel = object
        }
    }
    
    func getMessage() {
        let queryOptions = AmityMessageQueryOptions(subChannelId: subChannelId, messageParentFilter: .noParent, sortOption: .lastCreated)
        messagesCollection = messageRepository.getMessages(options: queryOptions)
        
        messagesNotificationToken = messagesCollection?.observe { [weak self] (liveCollection, change, error) in
            self?.groupMessages(in: liveCollection, change: change)
        }
        
        didEnterBackgroundObservation = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] notification in
            self?.lastEnterBackground = Date()
        }
        
        //        connectionObservation = AmityUIKitManagerInternal.shared.client.observe(\.connectionStatus) { [weak self] client, changes in
        //            self?.connectionStateDidChanged()
        //        }
        
    }
    
    func send(withText text: String?, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?) {
        let textMessage = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !textMessage.isEmpty else {
            return
        }
        let createOptioins = AmityTextMessageCreateOptions(
            subChannelId: subChannelId,
            text: textMessage,
            tags: nil,
            parentId: nil,
            metadata: metadata,
            mentioneesBuilder: mentionees)
        
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: messageRepository.createTextMessage(options:), parameters: createOptioins) { [weak self] _,_ in
            self?.text = ""
            self?.delegate?.screenViewModelEvents(for: .didSendText)
        }
    }
    
    func editText(with text: String, messageId: String, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?){
        let textMessage = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textMessage.isEmpty else { return }
        
        editor = AmityMessageEditor(client: AmityUIKitManagerInternal.shared.client, messageId: messageId)
        editor?.editText(textMessage, metadata: metadata, mentionees: mentionees, completion: { [weak self] (isSuccess, error) in
            guard isSuccess else { return }
            
            self?.delegate?.screenViewModelEvents(for: .didEditText)
            self?.editor = nil
        })
    }
    
    func delete(withMessage message: AmityMessageModel, at indexPath: IndexPath) {
        messageRepository?.deleteMessage(withId: message.messageId, completion: { [weak self] (status, error) in
            guard error == nil , status else { return }
            switch message.messageType {
            case .audio:
                AmityFileCache.shared.deleteFile(for: .audioDirectory, fileName: message.messageId + ".m4a")
            default:
                break
            }
            self?.delegate?.screenViewModelEvents(for: .didDelete(indexPath: indexPath))
            self?.editor = nil
        })
    }
    
    
    func deleteErrorMessage(with messageId: String, at indexPath: IndexPath) {
        messageRepository.deleteFailedMessage(messageId) { [weak self] (isSuccess, error) in
            if isSuccess {
                self?.delegate?.screenViewModelEvents(for: .didDeeleteErrorMessage(indexPath: indexPath))
                self?.delegate?.screenViewModelEvents(for: .updateMessages)
            }
        }
    }
    
    func reply(withText text: String?, parentId: String, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?, type: AmityMessageType) {
        let textMessage = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !textMessage.isEmpty else {
            return
        }
        let createOptioins = AmityTextMessageCreateOptions(
            subChannelId: subChannelId,
            text: textMessage,
            tags: nil,
            parentId: parentId,
            metadata: metadata,
            mentioneesBuilder: mentionees)
        
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: messageRepository.createTextMessage(options:), parameters: createOptioins) { [weak self] _,_ in
            self?.text = ""
            self?.delegate?.screenViewModelEvents(for: .didSendText)
        }
    }
    
    func forward(withChannelIdList channelIdList: [String]) {
        AmityEventHandler.shared.showKTBLoading()
        for channelId in channelIdList {
            for forwardMessage in forwardMessageList {
                dispatchGroup.enter()
                let serviceRequest = RequestChat()
                serviceRequest.requestSendMessage(channelId: channelId, message: forwardMessage) { [weak self] result in
                    guard let strongSelf = self else { return }
                    switch result {
                    case .success(let isSuccess):
                        print(isSuccess)
                        strongSelf.dispatchGroup.leave()
                    case .failure(let error):
                        print(error)
                        strongSelf.dispatchGroup.leave()
                    }
                }
            }
        }
        
        // Wait for all requests to complete
        dispatchGroup.notify(queue: .main) { [self] in
            // All channels have been created
            AmityEventHandler.shared.hideKTBLoading()
            forwardMessageList.removeAll()
        }
    }
    
    func checkChannelId(withSelectChannel selectChannel: [AmitySelectMemberModel]) {
        var channelIdList: [String] = []
        AmityEventHandler.shared.showKTBLoading()
        for user in selectChannel {
            dispatchGroup.enter()
            switch user.type {
            case .user:
                let userIds: [String] = [user.userId, AmityUIKitManagerInternal.shared.currentUserId]
                let builder = AmityConversationChannelBuilder()
                builder.setUserId(user.userId)
                builder.setDisplayName(user.displayName ?? "")
                builder.setMetadata(["user_id_member": userIds])
                
                let channelRepo = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
                AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: channelRepo.createChannel, parameters: builder) { [self] channelObject, _ in
                    if let channel = channelObject {
                        channelIdList.append(channel.channelId)
                    }
                    
                    dispatchGroup.leave()
                }
            case .channel:
                channelIdList.append(user.userId)
                dispatchGroup.leave()
            case .community:
                channelIdList.append(user.userId)
                dispatchGroup.leave()
            }
        }
        
        // Wait for all requests to complete
        dispatchGroup.notify(queue: .main) { [self] in
            forward(withChannelIdList: channelIdList)
        }
    }
    
    func startReading() {
        guard let subChannel = subChannel else { return }
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: subChannel.startReading, parameters: ()) { _,_ in }
    }
    
    func stopReading() {
        guard let subChannel = subChannel else { return }
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: subChannel.stopReading, parameters: ()) { _,_ in }
    }
    
    func shouldScrollToBottom(force: Bool) {
        guard let indexPath = lastIndexMessage() else { return }
        
        if force {
            // Forcely scroll to bottom regardless of current view state.
            delegate?.screenViewModelScrollToBottom(for: indexPath)
        } else {
            // Determining when to scroll or not when receiving message
            // depends upon the view state.
            delegate?.screenViewModelShouldUpdateScrollPosition(to: indexPath)
        }
    }
    
    func inputSource(for event: KeyboardInputEvents) {
        keyboardEvents = event
        delegate?.screenViewModelKeyboardInputEvents(for: event)
    }
    
    func toggleInputSource() {
        if keyboardEvents == .default {
            keyboardEvents = .composeBarMenu
        } else {
            keyboardEvents = .default
        }
        delegate?.screenViewModelKeyboardInputEvents(for: keyboardEvents)
    }
    
    func toggleKeyboardVisible(visible: Bool) {
        keyboardVisible = visible
    }
    
    func loadMoreScrollUp(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // load previous page when scrolled to the top
        if targetContentOffset.pointee.y.isLessThanOrEqualTo(0) {
            guard let collection = messagesCollection else { return }
            switch collection.loadingStatus {
            case .loaded:
                if collection.hasPrevious {
                    collection.previousPage()
                    delegate?.screenViewModelLoadingState(for: .loading)
                }
            default:
                break
            }
        }
    }
    
    func performCellEvent(for event: CellEvents) {
        delegate?.screenViewModelCellEvents(for: event)
    }
    
    func toggleShowDefaultKeyboardAndAudioKeyboard(_ sender: UIButton) {
        let tag = sender.tag
        if tag == 0 {
            delegate?.screenViewModelToggleDefaultKeyboardAndAudioKeyboard(for: .audio)
        } else if tag == 1 {
            delegate?.screenViewModelToggleDefaultKeyboardAndAudioKeyboard(for: .default)
        }
    }
    
    func reportMessage(at indexPath: IndexPath) {
        getReportMessageStatus(at: indexPath) { [weak self] isFlaggedByMe in
            guard let message = self?.message(at: indexPath) else { return }
            self?.messageFlagger = AmityMessageFlagger(client: AmityUIKitManagerInternal.shared.client, messageId: message.messageId)
            if isFlaggedByMe {
                self?.messageFlagger?.unflag { [weak self] success, error in
                    self?.handleReportResponse(at: indexPath, isSuccess: success, error: error)
                }
            } else {
                self?.messageFlagger?.flag { [weak self] success, error in
                    self?.handleReportResponse(at: indexPath, isSuccess: success, error: error)
                }
            }
        }
    }
	
	func tapOnMention(withUserId userId: String) {
		delegate?.screenViewModelDidTapOnMention(with: userId)
	}
    
    func updateForwardMessageInList(with message: AmityMessageModel) {
        if let foundedIndex = forwardMessageList.firstIndex(where: { $0.messageId == message.messageId }) {
            forwardMessageList.remove(at: foundedIndex)
            print("[ForwardMessage] Found message in forward message list | Remove message id: \(message.messageId) | Amount of forward message list: \(forwardMessageList.count)")
        } else {
            forwardMessageList.append(message)
            print("[ForwardMessage] Not Found message in forward message list | Add message id: \(message.messageId) | Amount of forward message list: \(forwardMessageList.count)")
        }
        
        delegate?.screenViewModelDidUpdateForwardMessageList(amountForwardMessageList: forwardMessageList.count)
    }
    
    func resetDataInForwardMessageList() {
        forwardMessageList.removeAll()
        delegate?.screenViewModelDidUpdateForwardMessageList(amountForwardMessageList: forwardMessageList.count)
    }

	func jumpToTargetId(_ message: AmityMessageModel) {
        for messageSection in messages {
            if let targetMessage = messageSection.first(where: { $0.messageId == message.parentId }) {
                self.delegate?.screenViewModelDidJumpToTarget(with: targetMessage.messageId)
                return
            }
        }
        
        // Handle case when the target message is not found.
        var queryOptions: AmityMessageQueryOptions!
        queryOptions = AmityMessageQueryOptions(subChannelId: subChannelId, aroundMessageId: message.parentId, sortOption: .lastCreated)

        // Call the queryMessages function with the updated query options to jump to the desired message.
        queryMessages(queryOptions: queryOptions, messageId: message.messageId)
    }
    
    func jumpToMessageId(_ messageId: String) {
        for messageSection in messages {
            if let targetMessage = messageSection.first(where: { $0.messageId == messageId }) {
                self.delegate?.screenViewModelDidJumpToTarget(with: messageId)
                return
            }
        }
        
        // Handle case when the target message is not found.
        var queryOptions: AmityMessageQueryOptions!
        queryOptions = AmityMessageQueryOptions(subChannelId: subChannelId, aroundMessageId: messageId, sortOption: .lastCreated)
        
        // Call the queryMessages function with the updated query options to jump to the desired message.
        queryMessages(queryOptions: queryOptions, messageId: messageId)
    }
}

private extension AmityMessageListScreenViewModel {
    
    func lastIndexMessage() -> IndexPath? {
        guard !messages.isEmpty else { return nil }
        let lastSection = messages.count - 1
        let messageCount = messages[lastSection].count - 1
        return IndexPath(item: messageCount, section: lastSection)
    }
    
    /*
     TODO: Refactor this
     
     Now we loop through whole collection and update the tableview for messages. The observer block also
     provides collection `change` object which can be used to track which indexpaths to add/remove/change.
     */
    func groupMessages(in collection: AmityCollection<AmityMessage>, change: AmityCollectionChange?) {
        
        // First we get message from the collection
        let storedMessages: [AmityMessageModel] = collection.allObjects().map(AmityMessageModel.init)
        
        // Ignore performing data if it don't change.
        guard dataSourceHash != storedMessages.hashValue else {
            // Ask view to hide loading indicator.
            self.delegate?.screenViewModelIsRefreshing(false)
            return
        }
        
        dataSourceHash = storedMessages.hashValue
        unsortedMessages = storedMessages
        
        // We use debouncer to prevent data updating too frequently and interupting UI.
        // When data is settled for a particular second, then updating UI in one time.
        debouncer.run { [weak self] in
            self?.notifyView()
        }
    }
    
    func getReportMessageStatus(at indexPath: IndexPath, completion: ((Bool) -> Void)?) {
        guard let message = message(at: indexPath) else { return }
        messageFlagger = AmityMessageFlagger(client: AmityUIKitManagerInternal.shared.client, messageId: message.messageId)
        messageFlagger?.isFlaggedByMe {
            completion?($0)
        }
    }
    
    func handleReportResponse(at indexPath: IndexPath, isSuccess: Bool, error: Error?) {
        if isSuccess {
            delegate?.screenViewModelDidReportMessage(at: indexPath)
        } else {
            delegate?.screenViewModelDidFailToReportMessage(at: indexPath, with: error)
        }
    }
    
    func groupMessagesAndJumpToTarget(in collection: AmityCollection<AmityMessage>, change: AmityCollectionChange?, messageId: String) {
        
        // First we get message from the collection
        let storedMessages: [AmityMessageModel] = collection.allObjects().map(AmityMessageModel.init)
        
        // Ignore performing data if it don't change.
        guard dataSourceHash != storedMessages.hashValue else {
            // Ask view to hide loading indicator.
            self.delegate?.screenViewModelIsRefreshing(false)
            return
        }
        
        dataSourceHash = storedMessages.hashValue
        unsortedMessages = storedMessages
        
        // We use debouncer to prevent data updating too frequently and interupting UI.
        // When data is settled for a particular second, then updating UI in one time.
        debouncer.run { [weak self] in
            self?.notifyView()
            self?.delegate?.screenViewModelDidJumpToTarget(with: messageId)
        }
    }
    
    private func queryMessages(queryOptions: AmityMessageQueryOptions, messageId: String) {
        // Invalidate the existing observer token to stop the previous observation.
        navigatingNotificationToken?.invalidate()
        
        // Fetch messages using the specified query options and observe changes.
        navigatingNotificationToken = messageRepository.getMessages(options: queryOptions).observe({ collection, change, error in
            if let error = error {
                print("Error: \(error).")
                return
            }
            
            // Use the 'collection' as the data source for the message table view.
            // Reload the message table view when the data source changes due to new messages or updates.
//            self.groupMessagesAndJumpToTarget(in: collection, change: change, messageId: messageId)
        })
    }
    
    // MARK: - Helper
    
    private func notifyView() {
        messages = unsortedMessages.groupSort(byDate: { $0.createdAtDate })
        delegate?.screenViewModelLoadingState(for: .loaded)
        delegate?.screenViewModelEvents(for: .updateMessages)
        delegate?.screenViewModelIsRefreshing(false)
        
        if isFirstTimeLoaded {
            // If this screen is opened for first time, we want to scroll to bottom.
            shouldScrollToBottom(force: true)
            isFirstTimeLoaded = false
        } else if let lastMessage = messages.last?.last,
                  lastMessageHash != lastMessage.hashValue {
            // Compare message hash
            // - if it's equal, the last message remains the same -> do nothing
            // - if it's not equal, there is new message -> scroll to bottom
            
            if lastMessageHash != -1 {
                shouldScrollToBottom(force: false)
            }
            lastMessageHash = lastMessage.hashValue
        }
        
    }
}

// MARK: - Send Image / Video
extension AmityMessageListScreenViewModel {
    
    func send(withMedias medias: [AmityMedia], type: AmityMediaType) {
        var operations: [AsyncOperation] = []
        
        switch type {
        case .image:
            operations = medias.map { UploadImageMessageOperation(subChannelId: subChannelId, media: $0, repository: messageRepository) }
        case .video:
            operations = medias.map { UploadVideoMessageOperation(subChannelId: subChannelId, media: $0, repository: messageRepository) }
        }
        
        // Define serial dependency A <- B <- C <- ... <- Z
        for (left, right) in zip(operations, operations.dropFirst()) {
            right.addDependency(left)
        }

        queue.addOperations(operations, waitUntilFinished: false)
    }
    
}

// MARK: - Send Audio
extension AmityMessageListScreenViewModel {
    func sendAudio() {
        messageAudio = AmityMessageAudioController(subChannelId: subChannelId, repository: messageRepository)
        messageAudio?.create { [weak self] in
            self?.messageAudio = nil
            self?.delegate?.screenViewModelEvents(for: .updateMessages)
            self?.delegate?.screenViewModelEvents(for: .didSendAudio)
            self?.shouldScrollToBottom(force: true)
        }
    }

}

// MARK: - Send File
extension AmityMessageListScreenViewModel {
    func send(withFiles files: [AmityFile]) {
        let operations = files.map { UploadFileMessageOperation(subChannelId: subChannelId, file: $0, repository: messageRepository) }
        
        // Define serial dependency A <- B <- C <- ... <- Z
        for (left, right) in zip(operations, operations.dropFirst()) {
            right.addDependency(left)
        }

        queue.addOperations(operations, waitUntilFinished: false)
    }
}


// MARK: - Audio Recording
extension AmityMessageListScreenViewModel {
    func performAudioRecordingEvents(for event: AudioRecordingEvents) {
        delegate?.screenViewModelAudioRecordingEvents(for: event)
    }
}
