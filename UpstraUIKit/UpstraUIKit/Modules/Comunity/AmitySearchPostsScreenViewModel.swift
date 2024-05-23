//
//  AmitySearchPostsScreenViewModel.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 12/4/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

final class AmitySearchPostsScreenViewModel: AmitySearchPostsScreenViewModelType {
    
    // MARK: - Delegate
    weak var delegate: AmitySearchPostsScreenViewModelDelegate?
    
    // MARK: - Controller
    private let postController: AmityPostControllerProtocol
    private let commentController: AmityCommentControllerProtocol
    private let reactionController: AmityReactionControllerProtocol
    private let pollRepository: AmityPollRepository
    private let repository = AmityPostRepository(client: AmityUIKitManagerInternal.shared.client)
    private let messageRepository = AmityMessageRepository(client: AmityUIKitManagerInternal.shared.client)

    // MARK: - Properties
    private let debouncer = Debouncer(delay: 0.3)
    private let debouncerLoadingMore = Debouncer(delay: 1.0)
    private let feedType: AmityPostFeedType
    private var postComponents = [AmityPostComponent]()
    private(set) var isPrivate: Bool
    private(set) var isLoading: Bool {
        didSet {
            guard oldValue != isLoading else { return }
            delegate?.screenViewModelLoadingStatusDidChange(self, isLoading: isLoading)
        }
    }
    private(set) var isLoadingMore: Bool = false
    
    private var keyword: String = ""
    
    private var tokenArray: [AmityNotificationToken?] = []
    private var fromIndex: Int = 0
    private var requestPostSize: Int = 20
    private let dispatchGroup = DispatchGroup()
    private var postLists: [AmityPostModel] = []
    private var dummyList: AmitySearchPostsModel = AmitySearchPostsModel(postIDS: [])
    
    private var isReactionLoading: Bool = false
    private var isReactionChanging: Bool = false // [Custom for ONE Krungthai] [Improvement] Add static value for check process reaction changing for ignore update post until add new reaction complete
    
    init(withFeedType feedType: AmityPostFeedType,
         postController: AmityPostControllerProtocol,
         commentController: AmityCommentControllerProtocol,
         reactionController: AmityReactionControllerProtocol) {
        self.feedType = feedType
        self.postController = postController
        self.commentController = commentController
        self.reactionController = reactionController
        self.isPrivate = false
        self.isLoading = false
        self.pollRepository = AmityPollRepository(client: AmityUIKitManagerInternal.shared.client)
    }
    
}

// MARK: - DataSource
extension AmitySearchPostsScreenViewModel {
    
    func getFeedType() -> AmityPostFeedType {
        return feedType
    }
    
    func postComponents(in section: Int) -> AmityPostComponent {
        return postComponents[section - 1]
    }
    
    // Plus 1 is for the header view section
    // We can be enhanced later
    func numberOfPostComponents() -> Int {
        return postComponents.count + 1
    }
    
    private func prepareComponents(posts: [AmityPostModel]) {
        postComponents = []
        for post in posts {
            post.appearance.displayType = .feed
            switch post.dataTypeInternal {
            case .text:
                addComponent(component: AmityPostTextComponent(post: post))
            case .image, .video:
                addComponent(component: AmityPostMediaComponent(post: post))
            case .file:
                addComponent(component: AmityPostFileComponent(post: post))
            case .poll:
                addComponent(component: AmityPostPollComponent(post: post))
            case .liveStream:
                addComponent(component: AmityPostLiveStreamComponent(post: post))
            case .unknown:
                addComponent(component: AmityPostPlaceHolderComponent(post: post))
            }
        }
        isLoading = false
        isLoadingMore = false
        delegate?.screenViewModelDidUpdateDataSuccess(self)
    }
    
    private func addComponent(component: AmityPostComposable) {
        postComponents.append(AmityPostComponent(component: component))
    }
}

// MARK: - Action
// MARK: Fetch data
extension AmitySearchPostsScreenViewModel {
    
    func fetchPosts(keyword: String) {
        if keyword.isEmpty { return }
        if !isLoadingMore {
            refresh()
        }
        
        AmityEventHandler.shared.showKTBLoading()
        isLoading = true
        var serviceRequest = RequestSearchingPosts()
        serviceRequest.keyword = keyword
        serviceRequest.from = fromIndex
        serviceRequest.size = requestPostSize
        serviceRequest.requestPost { result in
            switch result {
            case .success(let data):
                self.getPostbyPostIDsList(posts: data)
                self.fromIndex = data.postIDS.count == 0 ? self.fromIndex - serviceRequest.size : self.fromIndex
                self.keyword = keyword
            case .failure(let error):
                self.fromIndex = self.fromIndex - serviceRequest.size
                AmityEventHandler.shared.hideKTBLoading()
            }
        }
    }
    
    func loadMore() {
        debouncerLoadingMore.run { [weak self] in
            guard let weakSelf = self else { return }
            if !weakSelf.isLoadingMore && !weakSelf.isLoading && !weakSelf.postLists.isEmpty {
                weakSelf.isLoadingMore = true
                weakSelf.fromIndex += weakSelf.requestPostSize
                weakSelf.fetchPosts(keyword: weakSelf.keyword)
            }
        }
    }
    
    func refresh() {
        fromIndex = 0
        dummyList.postIDS = []
        postLists = []
//        postComponents = []
        delegate?.screenViewModelDidUpdateDataSuccess(self)
    }
    
    func getPostbyPostIDsList(posts: AmitySearchPostsModel) {
        dummyList.postIDS += posts.postIDS
        DispatchQueue.main.async { [self] in
            for postId in posts.postIDS {
                dispatchGroup.enter()
                let postCollection = repository.getPost(withId: postId)
                let token = postCollection.observe { [weak self] (_, error) in
                    guard let strongSelf = self else { return }
                    if let _ = AmityError(error: error) {
                        self?.nextData()
                    } else {
                        if let model = strongSelf.prepareData(amityObject: postCollection) {
                            if !model.isDelete {
                                self?.appendData(post: model)
                            }
                        } else {
                            self?.nextData()
                        }
                    }
                }
                
                tokenArray.append(token)
            }
            
            dispatchGroup.notify(queue: .main) {
                let sortedArray = self.sortArrayPositions(array1: self.dummyList.postIDS, array2: self.postLists)
                self.prepareComponents(posts: sortedArray)
                self.tokenArray.removeAll()
                AmityEventHandler.shared.hideKTBLoading()
            }
            
            if dummyList.postIDS.isEmpty {
                let sortedArray = self.sortArrayPositions(array1: self.dummyList.postIDS, array2: self.postLists)
                prepareComponents(posts: sortedArray)
                AmityEventHandler.shared.hideKTBLoading()
            }
        }
    }
    
    private func prepareData(amityObject: AmityObject<AmityPost>) -> AmityPostModel? {
        guard let _post = amityObject.object else { return nil }
        let post = AmityPostModel(post: _post)
        if let communityId = post.targetCommunity?.communityId {
            let participation = AmityCommunityParticipation(client: AmityUIKitManagerInternal.shared.client, andCommunityId: communityId)
            post.isModerator = participation.getMember(withId: post.postedUserId)?.hasModeratorRole ?? false
        }
        return post
    }
    
    func appendData(post: AmityPostModel) {
        let containsPostId = postLists.contains { dataArray in
            dataArray.postId == post.postId
        }
        
        if !containsPostId {
            postLists.append(post)
        }
        dispatchGroup.leave()
    }
    
    func nextData() {
        dispatchGroup.leave()
    }
    
    //  Sort function by list from fetchPosts
    func sortArrayPositions(array1: [String], array2: [AmityPostModel]) -> [AmityPostModel] {
        var sortedArray: [AmityPostModel] = []
        
        for postId in array1 {
            if let index = array2.firstIndex(where: { $0.postId == postId }) {
                sortedArray.append(array2[index])
            }
        }
        
        return sortedArray
    }
    
    func fetchByPost(postId: String) {
        //Get Post data
        self.postController.getPostForPostId(withPostId: postId) { [weak self] (result) in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let post):
                guard let index = strongSelf.postComponents.firstIndex(where: { $0._composable.post.postId == postId }) else { return }
                switch post.dataTypeInternal {
                case .text:
                    strongSelf.postComponents[index] = AmityPostComponent(component: AmityPostTextComponent(post: post))
                case .image, .video:
                    strongSelf.postComponents[index] = AmityPostComponent(component: AmityPostMediaComponent(post: post))
                case .file:
                    strongSelf.postComponents[index] = AmityPostComponent(component: AmityPostFileComponent(post: post))
                case .poll:
                    strongSelf.postComponents[index] = AmityPostComponent(component: AmityPostPollComponent(post: post))
                case .liveStream:
                    strongSelf.postComponents[index] = AmityPostComponent(component: AmityPostLiveStreamComponent(post: post))
                case .unknown:
                    strongSelf.postComponents[index] = AmityPostComponent(component: AmityPostTextComponent(post: post))
                }
                strongSelf.delegate?.screenViewModelDidUpdateDataSuccess(strongSelf)
            case .failure:
                break
            }
        }
    }
}

// MARK: Observer
extension AmitySearchPostsScreenViewModel {
    func startObserveFeedUpdate() {
        NotificationCenter.default.addObserver(self, selector: #selector(feedNeedsUpdate(_:)), name: Notification.Name.Post.didCreate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(feedNeedsUpdate(_:)), name: Notification.Name.Post.didUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(feedNeedsUpdate(_:)), name: Notification.Name.Post.didDelete, object: nil)
    }
    
    func stopObserveFeedUpdate() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Post.didCreate, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Post.didUpdate, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Post.didDelete, object: nil)
    }
    
    @objc private func feedNeedsUpdate(_ notification: NSNotification) {
        // Feed can't get notified from SDK after posting because backend handles a query step.
        // So, it needs to be notified from our side over NotificationCenter.
        if notification.name == Notification.Name.Post.didCreate {
            //            delegate?.screenViewModelScrollToTop(self)
        }
    }
}

// MARK: Post&Comment
extension AmitySearchPostsScreenViewModel {
    func like(id: String, referenceType: AmityReactionReferenceType) {
        reactionController.addReaction(withReaction: .like, referanceId: id, referenceType: referenceType) { [weak self] (success, error) in
            guard let strongSelf = self else { return }
            if success {
                switch referenceType {
                case .post:
                    strongSelf.delegate?.screenViewModelDidLikePostSuccess(strongSelf)
                case .comment:
                    strongSelf.delegate?.screenViewModelDidLikeCommentSuccess(strongSelf)
                default:
                    break
                }
            } else {
                strongSelf.delegate?.screenViewModelDidFail(strongSelf, failure: AmityError(error: error) ?? .unknown)
            }
        }
    }
    
    func unlike(id: String, referenceType: AmityReactionReferenceType) {
        reactionController.removeReaction(withReaction: .like, referanceId: id, referenceType: referenceType) { [weak self] (success, error) in
            guard let strongSelf = self else { return }
            if success {
                switch referenceType {
                case .post:
                    strongSelf.delegate?.screenViewModelDidUnLikePostSuccess(strongSelf)
                case .comment:
                    strongSelf.delegate?.screenViewModelDidUnLikeCommentSuccess(strongSelf)
                default:
                    break
                }
            } else {
                strongSelf.delegate?.screenViewModelDidFail(strongSelf, failure: AmityError(error: error) ?? .unknown)
            }
        }
    }
    
    func addReaction(id: String, reaction: AmityReactionType, referenceType: AmityReactionReferenceType) {
        if !isReactionLoading {
            isReactionLoading = true
            reactionController.addReaction(withReaction: reaction, referanceId: id, referenceType: referenceType) { [weak self] (success, error) in
                guard let strongSelf = self else { return }
                strongSelf.isReactionLoading = false
                if success {
                    switch referenceType {
                    case .post:
                        strongSelf.fetchByPost(postId: id)
                    case .comment:
                        strongSelf.delegate?.screenViewModelDidLikeCommentSuccess(strongSelf)
                    default:
                        break
                    }
                } else {
                    strongSelf.delegate?.screenViewModelDidFail(strongSelf, failure: AmityError(error: error) ?? .unknown)
                }
            }
        }
    }
    
    func removeReaction(id: String, reaction: AmityReactionType, referenceType: AmityReactionReferenceType) {
        if !isReactionLoading {
            isReactionLoading = true
            reactionController.removeReaction(withReaction: reaction, referanceId: id, referenceType: referenceType) { [weak self] (success, error) in
                guard let strongSelf = self else { return }
                strongSelf.isReactionLoading = false
                if success {
                    switch referenceType {
                    case .post:
                        strongSelf.fetchByPost(postId: id)
                    case .comment:
                        strongSelf.delegate?.screenViewModelDidUnLikeCommentSuccess(strongSelf)
                    default:
                        break
                    }
                } else {
                    strongSelf.delegate?.screenViewModelDidFail(strongSelf, failure: AmityError(error: error) ?? .unknown)
                }
            }
        }
    }
    
    func removeHoldReaction(id: String, reaction: AmityReactionType, referenceType: AmityReactionReferenceType, reactionSelect: AmityReactionType) {
        if !isReactionLoading {
            isReactionLoading = true
            isReactionChanging = true // [Custom for ONE Krungthai] [Improvement] Set static value for check process reaction changing to true for start reaction changing
            reactionController.removeReaction(withReaction: reaction, referanceId: id, referenceType: referenceType) { [weak self] (success, error) in
                guard let strongSelf = self else { return }
                strongSelf.isReactionLoading = false
                strongSelf.isReactionChanging = false // [Custom for ONE Krungthai] [Improvement] Set static value for check process reaction changing to false for don't ignore update post next time
                if success {
                    strongSelf.delegate?.screenViewModelDidUnLikePostSuccess(strongSelf)
                    self?.addReaction(id: id, reaction: reactionSelect, referenceType: referenceType)
                } else {
                    strongSelf.delegate?.screenViewModelDidFail(strongSelf, failure: AmityError(error: error) ?? .unknown)
                }
            }
        }
    }
}

// MARK: Post
extension AmitySearchPostsScreenViewModel {
    func delete(withPostId postId: String) {
        postController.delete(withPostId: postId, parentId: nil) { [weak self] (success, error) in
            guard let strongSelf = self else { return }
            if success {
                NotificationCenter.default.post(name: NSNotification.Name.Post.didDelete, object: nil)
            } else {
                strongSelf.delegate?.screenViewModelDidFail(strongSelf, failure: AmityError(error: error) ?? .unknown)
            }
        }
    }
    
    func report(withPostId postId: String) {
        postController.report(withPostId: postId)  { [weak self] (success, error) in
            self?.reportHandler(success: success, error: error)
        }
    }
    
    func unreport(withPostId postId: String) {
        postController.unreport(withPostId: postId) { [weak self] (success, error) in
            self?.unreportHandler(success: success, error: error)
        }
    }
    
    func getReportStatus(withPostId postId: String) {
        postController.getReportStatus(withPostId: postId) { [weak self] (isReported) in
            self?.delegate?.screenViewModelDidGetReportStatusPost(isReported: isReported)
        }
    }
}

// MARK: Comment
extension AmitySearchPostsScreenViewModel {
    func delete(withCommentId commentId: String) {
        commentController.delete(withCommentId: commentId) { [weak self] (success, error) in
            guard let strongSelf = self else { return }
            if success {
                strongSelf.delegate?.screenViewModelDidDeleteCommentSuccess(strongSelf)
            } else {
                strongSelf.delegate?.screenViewModelDidFail(strongSelf, failure: AmityError(error: error) ?? .unknown)
            }
        }
    }
    
    func edit(withComment comment: AmityCommentModel, text: String, metadata: [String : Any]?, mentionees: AmityMentioneesBuilder?) {
        commentController.edit(withComment: comment, text: text, metadata: metadata, mentionees: mentionees) { [weak self] (success, error) in
            guard let strongSelf = self else { return }
            if success {
                strongSelf.delegate?.screenViewModelDidEditCommentSuccess(strongSelf)
            } else {
                strongSelf.delegate?.screenViewModelDidFail(strongSelf, failure: AmityError(error: error) ?? .unknown)
            }
        }
    }
    
    func report(withCommentId commentId: String) {
        commentController.report(withCommentId: commentId) { [weak self] (success, error) in
            self?.reportHandler(success: success, error: error)
        }
    }
    
    func unreport(withCommentId commentId: String) {
        commentController.unreport(withCommentId: commentId) { [weak self] (success, error) in
            self?.unreportHandler(success: success, error: error)
        }
    }
    
    
    func getReportStatus(withCommendId commendId: String, completion: ((Bool) -> Void)?) {
        commentController.getReportStatus(withCommentId: commendId, completion: completion)
    }
}

// MARK: Report handler
private extension AmitySearchPostsScreenViewModel {
    func reportHandler(success: Bool, error: Error?) {
        if success {
            delegate?.screenViewModelDidSuccess(self, message: AmityLocalizedStringSet.HUD.reportSent)
        } else {
            delegate?.screenViewModelDidFail(self, failure: AmityError(error: error) ?? .unknown)
        }
    }
    
    func unreportHandler(success: Bool, error: Error?) {
        if success {
            delegate?.screenViewModelDidSuccess(self, message: AmityLocalizedStringSet.HUD.unreportSent)
        } else {
            delegate?.screenViewModelDidFail(self, failure: AmityError(error: error) ?? .unknown)
        }
    }
}

// MARK: User settings
extension AmitySearchPostsScreenViewModel {
    func fetchUserSettings() {
        switch feedType {
        case .userFeed(let userId):
            // retrieveFeed user settings
            if userId != AmityUIKitManagerInternal.shared.currentUserId {
                delegate?.screenViewModelDidGetUserSettings(self)
            }
            return
        default: break
        }
    }
}

// MARK: Poll
extension AmitySearchPostsScreenViewModel {
    
    func vote(withPollId pollId: String?, answerIds: [String]) {
        guard let pollId = pollId else { return }
        pollRepository.votePoll(withId: pollId, answerIds: answerIds) { [weak self] success, error in
            guard let strongSelf = self else { return }
            
            Log.add("[Poll] Vote Poll: \(success) Error: \(error)")
            if success {
                
            } else {
                strongSelf.delegate?.screenViewModelDidFail(strongSelf, failure: AmityError(error: error) ?? .unknown)
            }
        }
    }
    
    func close(withPollId pollId: String?) {
        guard let pollId = pollId else { return }
        pollRepository.closePoll(withId: pollId) { [weak self] success, error in
            guard let strongSelf = self else { return }
            if success {
                
            } else {
                strongSelf.delegate?.screenViewModelDidFail(strongSelf, failure: AmityError(error: error) ?? .unknown)
            }
        }
    }
    
}

// MARK: - Share to Chat
extension AmitySearchPostsScreenViewModel {
    
    func checkChannelId(withSelectChannel selectChannel: [AmitySelectMemberModel], post: AmityPostModel) {
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
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let stringSelf = self else { return }
            stringSelf.forward(withChannelIdList: channelIdList, post: post)
        }
    }
    
    func forward(withChannelIdList channelIdList: [String], post: AmityPostModel) {
        let externalURL = AmityURLCustomManager.ExternalURL.generateExternalURLOfPost(post: post)
        for channelId in channelIdList {
            dispatchGroup.enter()
            let createOptions = AmityTextMessageCreateOptions(subChannelId: channelId, text: externalURL)
            AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: messageRepository.createTextMessage(options:), parameters: createOptions) { [weak self] message, error in
                guard let stringSelf = self else { return }
                stringSelf.dispatchGroup.leave()
            }
        }
        
        // Wait for all requests to complete
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let stringSelf = self else { return }
            // All channels have been created
            AmityEventHandler.shared.hideKTBLoading()
            AmityHUD.show(.success(message: AmityLocalizedStringSet.MessageList.alertSharedMessageSuccessfully.localizedString))
        }
    }
}
