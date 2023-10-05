//
//  AmityFeedScreenViewModel.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 2/13/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

final class AmityFeedScreenViewModel: AmityFeedScreenViewModelType {
    
    // MARK: - Delegate
    weak var delegate: AmityFeedScreenViewModelDelegate?
    
    // MARK: - Controller
    private let postController: AmityPostControllerProtocol
    private let commentController: AmityCommentControllerProtocol
    private let reactionController: AmityReactionControllerProtocol
    private let pollRepository: AmityPollRepository
    private let postRepository: AmityPostRepository
    
    // MARK: - Properties
    private let debouncer = Debouncer(delay: 0.3)
    private let feedType: AmityPostFeedType
    private var postComponents = [AmityPostComponent]()
    private(set) var isPrivate: Bool
    private(set) var isLoading: Bool {
        didSet {
            guard oldValue != isLoading else { return }
            delegate?.screenViewModelLoadingStatusDidChange(self, isLoading: isLoading)
        }
    }
    
    private var pinPostData: [AmityPostModel] = []
    private var dummyList: [String] = []
    private var tokenArray: [AmityNotificationToken?] = []
    private let dispatchGroup = DispatchGroup()

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
        self.postRepository = AmityPostRepository(client: AmityUIKitManagerInternal.shared.client)
    }
    
}

// MARK: - DataSource
extension AmityFeedScreenViewModel {
    
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
        var postsData = pinPostData
        postsData += posts
        
        // Create a set to store unique post IDs
        var uniquePostIds = Set<String>()  // Assuming postId is of type String, change it to the appropriate type
        
        for post in postsData {
            // Check if the post's ID is already in the set
            if uniquePostIds.contains(post.postId) {
                continue  // Skip this post if it's a duplicate
            }
            
            // Add the post's ID to the set to mark it as seen
            uniquePostIds.insert(post.postId)
            
            post.appearance.displayType = .feed

            // [Custom for ONE Krungthai] Assign custom source post display type for use in moderator user in official community condition to outputing and prepare action
            switch feedType {
            case .communityFeed(_):
                post.appearance.amitySocialPostDisplayStyle = .community
                break
            default:
                post.appearance.amitySocialPostDisplayStyle = .feed
            }
            
            if let communityId = post.targetCommunity?.communityId {
                let participation = AmityCommunityMembership(client: AmityUIKitManagerInternal.shared.client, andCommunityId: communityId)
                post.isModerator = participation.getMember(withId: post.postedUserId)?.hasModeratorRole ?? false
            }
                        
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
        delegate?.screenViewModelDidUpdateDataSuccess(self)
    }

    private func addComponent(component: AmityPostComposable) {
        postComponents.append(AmityPostComponent(component: component))
    }
}

// MARK: - Action
// MARK: Fetch data
extension AmityFeedScreenViewModel {
    
    func fetchPosts() {
        pinPostData = []
        dummyList = []
        isLoading = true
        let serviceRequest = RequestGetPinPost()
        serviceRequest.requestGetPinPost(feedType) { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let data):
                strongSelf.getPostId(withpostIds: data.pinposts)
            case .failure(let error):
                print(error)
                strongSelf.fetchFeedPosts()
            }
        }
    }
    
    private func getPostId(withpostIds postIds: [String]) {
        dummyList += postIds
        DispatchQueue.main.async { [self] in
            for postId in postIds {
                print("-------> dispatchGroup.enter() \(postId)")
                dispatchGroup.enter()
                let postCollection = postRepository.getPost(withId: postId)
                let token = postCollection.observe { [weak self] (_, error) in
                    guard let strongSelf = self else { return }
                    if let _ = AmityError(error: error) {
                        print("-------> dispatchGroup.leave() \(postId)")
                        strongSelf.nextData()
                    } else {
                        if let model = strongSelf.prepareData(amityObject: postCollection) {
                            if !model.isDelete {
                                strongSelf.appendData(post: model)
                            }
                        } else {
                            print("-------> dispatchGroup.leave() \(postId)")
                            strongSelf.nextData()
                        }
                    }
                    strongSelf.dispatchGroup.leave()
                }
                tokenArray.append(token)
            }
            
            // Move the dispatchGroup.notify block here, outside of the loop
            dispatchGroup.notify(queue: .main) {
                let sortedArray = self.sortArrayPositions(array1: self.dummyList, array2: self.pinPostData)
                self.pinPostData = sortedArray
                self.tokenArray.removeAll()
                self.fetchFeedPosts()
            }
            
            if dummyList.isEmpty {
                let sortedArray = self.sortArrayPositions(array1: self.dummyList, array2: self.pinPostData)
                self.pinPostData = sortedArray
                self.fetchFeedPosts()
            }
        }
    }

    
    private func fetchFeedPosts() {
        DispatchQueue.main.async { [self] in
            postController.retrieveFeed(withFeedType: feedType) { [weak self] (result) in
                guard let strongSelf = self else { return }
                /* [Custom for ONE Krungthai] [Improvement] Check is process reaction changing for ignore update post until add new reaction complete */
                if !strongSelf.isReactionChanging {
                    switch result {
                    case .success(let posts):
                        strongSelf.debouncer.run {
                            strongSelf.prepareComponents(posts: posts)
                        }
                    case .failure(let error):
                        strongSelf.debouncer.run {
                            strongSelf.prepareComponents(posts: [])
                        }
                        if let amityError = AmityError(error: error), amityError == .noUserAccessPermission {
                            switch strongSelf.feedType {
                            case .userFeed:
                                strongSelf.isPrivate = true
                            default:
                                strongSelf.isPrivate = false
                            }
                            strongSelf.delegate?.screenViewModelDidFail(strongSelf, failure: amityError)
                        } else {
                            strongSelf.delegate?.screenViewModelDidFail(strongSelf, failure: AmityError(error: error) ?? .unknown)
                        }
                    }
                }
                strongSelf.isReactionChanging = false // [Custom for ONE Krungthai] [Improvement] Force set static value for check process reaction changing to false if reaction changing have problem
            }
        }
    }
    
    func loadMore() {
        postController.loadMore()
    }
    
    private func prepareData(amityObject: AmityObject<AmityPost>) -> AmityPostModel? {
        guard let _post = amityObject.snapshot else { return nil }
        let post = AmityPostModel(post: _post)
        post.isPinPost = true
        return post
    }
    
    func appendData(post: AmityPostModel) {
        let containsPostId = pinPostData.contains { dataArray in
            dataArray.postId == post.postId
        }
        
        if !containsPostId {
            pinPostData.append(post)
        }
        print("-------> dispatchGroup.leave() \(post.postId)")
    }
    
    func nextData() {
//        dispatchGroup.leave()
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
        self.postController.getPinPostForPostId(withPostId: postId) { [weak self] (result) in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let post):
                guard let index = strongSelf.postComponents.firstIndex(where: { $0._composable.post.postId == postId }) else { return }
                post.isPinPost = true
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
extension AmityFeedScreenViewModel {
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
        fetchPosts()
        if notification.name == Notification.Name.Post.didCreate {
            delegate?.screenViewModelScrollToTop(self)
            
            if let postId = notification.object as? String {
                if feedType == .globalFeed {
                    delegate?.screenViewModelRouteToPostDetail(postId, viewModel: self)
                    stopObserveFeedUpdate()
                }
            }
        }
    }
}

// MARK: Post&Comment
extension AmityFeedScreenViewModel {
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
    
    func addReaction(id: String, reaction: AmityReactionType, referenceType: AmityReactionReferenceType, isPinPost: Bool) {
        if !isReactionLoading {
            isReactionLoading = true
            reactionController.addReaction(withReaction: reaction, referanceId: id, referenceType: referenceType) { [weak self] (success, error) in
                guard let strongSelf = self else { return }
                if success {
                    strongSelf.isReactionLoading = false
                    switch referenceType {
                    case .post:
                        if isPinPost {
                            strongSelf.fetchByPost(postId: id)
                        } else {
                            strongSelf.delegate?.screenViewModelDidLikePostSuccess(strongSelf)
                        }
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
    
    func removeReaction(id: String, reaction: AmityReactionType, referenceType: AmityReactionReferenceType, isPinPost: Bool) {
        if !isReactionLoading {
            isReactionLoading = true
            reactionController.removeReaction(withReaction: reaction, referanceId: id, referenceType: referenceType) { [weak self] (success, error) in
                guard let strongSelf = self else { return }
                strongSelf.isReactionLoading = false
                if success {
                    switch referenceType {
                    case .post:
                        if isPinPost {
                            strongSelf.fetchByPost(postId: id)
                        } else {
                            strongSelf.delegate?.screenViewModelDidUnLikePostSuccess(strongSelf)
                        }
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
    
    func removeHoldReaction(id: String, reaction: AmityReactionType, referenceType: AmityReactionReferenceType, reactionSelect: AmityReactionType, isPinPost: Bool) {
        if !isReactionLoading {
            isReactionLoading = true
            isReactionChanging = true // [Custom for ONE Krungthai] [Improvement] Set static value for check process reaction changing to true for start reaction changing
            reactionController.removeReaction(withReaction: reaction, referanceId: id, referenceType: referenceType) { [weak self] (success, error) in
                guard let strongSelf = self else { return }
                strongSelf.isReactionLoading = false
                strongSelf.isReactionChanging = false // [Custom for ONE Krungthai] [Improvement] Set static value for check process reaction changing to false for don't ignore update post next time
                if success {
                    strongSelf.delegate?.screenViewModelDidUnLikePostSuccess(strongSelf)
                    self?.addReaction(id: id, reaction: reactionSelect, referenceType: referenceType, isPinPost: isPinPost)
                } else {
                    strongSelf.delegate?.screenViewModelDidFail(strongSelf, failure: AmityError(error: error) ?? .unknown)
                }
            }
        }
    }
}

// MARK: Post
extension AmityFeedScreenViewModel {
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
extension AmityFeedScreenViewModel {
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
private extension AmityFeedScreenViewModel {
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
extension AmityFeedScreenViewModel {
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
extension AmityFeedScreenViewModel {
    
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

// MARK: Pin Post
extension AmityFeedScreenViewModel {
    
    func pinpost(withpostId postId: String) {
        let serviceRequest = RequestGetPinPost()
        serviceRequest.requestPinPost(postId, type: feedType, isPinned: true) { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success():
                strongSelf.delegate?.screenViewModelDidUpdatePinSuccess(strongSelf, message: "Pin send success")
            case .failure(_):
                strongSelf.delegate?.screenViewModelDidUpdatePinSuccess(strongSelf, message: "Pin send failed")
            }
        }
    }
    
    func unpinpost(withpostId postId: String) {
        let serviceRequest = RequestGetPinPost()
        serviceRequest.requestPinPost(postId, type: feedType, isPinned: false) { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success():
                strongSelf.delegate?.screenViewModelDidUpdatePinSuccess(strongSelf, message: "Unpin send success")
            case .failure(_):
                strongSelf.delegate?.screenViewModelDidUpdatePinSuccess(strongSelf, message: "Unpin send failed")
            }
        }
    }
}
