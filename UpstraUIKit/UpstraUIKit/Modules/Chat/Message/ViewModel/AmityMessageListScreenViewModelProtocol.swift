//
//  AmityMessageListScreenViewModelProtocol.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 5/8/2563 BE.
//  Copyright © 2563 Amity Communication. All rights reserved.
//

import UIKit
import Photos
import AmitySDK

protocol AmityMessageListScreenViewModelDelegate: AnyObject {
    
    func screenViewModelRoute(route: AmityMessageListScreenViewModel.Route)
    func screenViewModelDidGetChannel(channel: AmityChannelModel)
    func screenViewModelDidGetUser(channel: AmityChannelModel, user: AmityUserModel)
    func screenViewModelScrollToBottom(for indexPath: IndexPath)
    func screenViewModelDidTextChange(text: String)
    func screenViewModelLoadingState(for state: AmityLoadingState)
    func screenViewModelEvents(for events: AmityMessageListScreenViewModel.Events)
    func screenViewModelCellEvents(for events: AmityMessageListScreenViewModel.CellEvents)
    func screenViewModelKeyboardInputEvents(for events: AmityMessageListScreenViewModel.KeyboardInputEvents)
    func screenViewModelToggleDefaultKeyboardAndAudioKeyboard(for events: AmityMessageListScreenViewModel.KeyboardInputEvents)
    func screenViewModelAudioRecordingEvents(for events: AmityMessageListScreenViewModel.AudioRecordingEvents)
    
    func screenViewModelShouldUpdateScrollPosition(to indexPath: IndexPath)
    
    func screenViewModelDidReportMessage(at indexPath: IndexPath, isFlag: Bool)
    func screenViewModelDidFailToReportMessage(at indexPath: IndexPath, with error: Error?)
    
    func screenViewModelIsRefreshing(_ isRefreshing: Bool)
	func screenViewModelDidTapOnMention(with userId: String)
    func screenViewModelDidJumpToTarget(with messageId: String)
    
    func screenViewModelDidUpdateForwardMessageList(amountForwardMessageList: Int)
    
    func screenViewModelDidUpdateJoinChannelSuccess()
}

protocol AmityMessageListScreenViewModelDataSource {
    var allCellNibs: [String: UINib] { get }
    var allCellClasses: [String: AmityMessageCellProtocol.Type] { get }
    
    func message(at indexPath: IndexPath) -> AmityMessageModel?
    func numberOfMessages() -> Int
    func numberOfSection() -> Int
    func numberOfMessage(in section: Int) -> Int
    func getChannelId() -> String
    func getCommunityId() -> String
    func isKeyboardVisible() -> Bool
    func findIndexPath(forMessageId messageId: String) -> IndexPath?
    func getChannelType() -> AmityChannelType
    func isMessageInForwardMessageList(messageId: String) -> Bool
    func getNotification() -> Bool
}

protocol AmityMessageListScreenViewModelAction {
    func route(for route: AmityMessageListScreenViewModel.Route)
    func setText(withText text: String?)
    func getChannel()
    func getSubChannel()
    func getMessage()
    func scrollToLatestMessage()
    
    func send(withText text: String?, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?)
    func send(withMedias medias: [AmityMedia], type: AmityMediaType)
    func send(withFiles files: [AmityFile])
    func sendAudio()
    func sendAudio(tempAudioURL: URL)
    func resend(with message: AmityMessageModel, at indexPath: IndexPath)
    func reply(withText text: String?, parentId: String, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?, type: AmityMessageType)
    func forward(withChannelIdList channelIdList: [String])
    func checkChannelId(withSelectChannel selectChannel: [AmitySelectMemberModel])
    
    func editText(with text: String, messageId: String, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?)
    func delete(withMessage message: AmityMessageModel, at indexPath: IndexPath)
    func deleteErrorMessage(with messageId: String, at indexPath: IndexPath, isFromResend: Bool)
    func startReading()
    func stopReading()
    
    func shouldScrollToBottom(force: Bool)
    
    func registerCellNibs()
    func register(items: [AmityMessageTypes:AmityMessageCellProtocol.Type])
    
    func inputSource(for event: AmityMessageListScreenViewModel.KeyboardInputEvents)
    func toggleInputSource()
    func toggleKeyboardVisible(visible: Bool)
    
    func performCellEvent(for event: AmityMessageListScreenViewModel.CellEvents)
    
    func loadMoreScrollUp(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
    
    func toggleShowDefaultKeyboardAndAudioKeyboard(_ sender: UIButton)
    
    func performAudioRecordingEvents(for event: AmityMessageListScreenViewModel.AudioRecordingEvents)
    
    func reportMessage(at indexPath: IndexPath)
	func tapOnMention(withUserId userId: String)
    
    func updateForwardMessageInList(with message: AmityMessageModel)
    func resetDataInForwardMessageList()

    func jumpToMessageId(_ messageId: String)
    
    func startRealtimeSubscription()
    func stopRealtimeSubscription()
    
    func startUserRealtimeSubscription()
    func stopUserRealtimeSubscription()
    
    func syncChannelPresence()
    func unsyncChannelPresence()
    
    func join()
    
    func getTotalUnreadCount()
    
    func stopObserve()
    
    func retrieveNotificationSettings()
}

protocol AmityMessageListScreenViewModelType: AmityMessageListScreenViewModelAction, AmityMessageListScreenViewModelDataSource {
    var action: AmityMessageListScreenViewModelAction { get }
    var dataSource: AmityMessageListScreenViewModelDataSource { get }
    var delegate: AmityMessageListScreenViewModelDelegate? { get set }
}

extension AmityMessageListScreenViewModelType {
    var action: AmityMessageListScreenViewModelAction { return self }
    var dataSource: AmityMessageListScreenViewModelDataSource { return self }
}
