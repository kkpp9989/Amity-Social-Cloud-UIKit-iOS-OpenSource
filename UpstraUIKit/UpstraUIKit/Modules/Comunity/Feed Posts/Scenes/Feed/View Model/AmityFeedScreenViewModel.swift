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
        for post in posts {
            post.appearance.displayType = .feed
            
            // [Custom for ONE Krungthai] Assign custom source post display type for use in moderator user in official community condition to outputing and prepare action
            switch feedType {
            case .communityFeed(_):
                post.appearance.amitySocialPostDisplayStyle = .community
                break
            default:
                post.appearance.amitySocialPostDisplayStyle = .feed
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
        isLoading = true
        let serviceRequest = RequestGetPinPost()
        serviceRequest.requestGetPinPost() { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(_):
                strongSelf.getPostId(withpostId: "64fed4955acb9c3f752ce4ed") { (result) in
                    switch result {
                    case .success(let post):
                        strongSelf.pinPostData.append(post)
                        strongSelf.fetchFeedPosts()
                    case .failure(_):
                        strongSelf.fetchFeedPosts()
                    }
                }
            case .failure(let error):
                print(error)
                //                strongSelf.fetchFeedPosts()
                
                strongSelf.getPostId(withpostId: "64fed4955acb9c3f752ce4ed") { (result) in
                    switch result {
                    case .success(let post):
                        strongSelf.pinPostData.append(post)
                        strongSelf.fetchFeedPosts()
                    case .failure(_):
                        strongSelf.fetchFeedPosts()
                    }
                }
            }
        }
    }
    
//    func getPostbyPostIDsList(posts: AmitySearchPostsModel, completion: @escaping (Result<AmityPostModel,AmityError>) -> Void) {
//        DispatchQueue.main.async { [self] in
//            let postCollection = postRepository.getPost(withId: "64fed4955acb9c3f752ce4ed")
//            let token = postCollection.observe { [weak self] (_, error) in
//                guard let strongSelf = self else { return }
//                if let error = AmityError(error: error) {
//                    completion(.failure(error))
//                } else {
//                    if let model = strongSelf.prepareData(amityObject: postCollection) {
//                        completion(.success(model))
//                    } else {
//                        completion(.failure(error))
//                    }
//                }
//            }
//        }
//    }
    
    private func prepareData(amityObject: AmityObject<AmityPost>) -> AmityPostModel? {
        guard let _post = amityObject.object else { return nil }
        let post = AmityPostModel(post: _post)
        if let communityId = post.targetCommunity?.communityId {
            let participation = AmityCommunityParticipation(client: AmityUIKitManagerInternal.shared.client, andCommunityId: communityId)
            post.isModerator = participation.getMember(withId: post.postedUserId)?.hasModeratorRole ?? false
        }
        return post
    }
    
    private func getPostId(withpostId postId: String, completion: @escaping (Result<AmityPostModel,AmityError>) -> Void) {
        DispatchQueue.main.async { [self] in
            postController.getPostForPostId(withPostId: postId) { (result) in
                switch result {
                case .success(let post):
                    post.isPinPost = true
                    completion(.success(post))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func fetchFeedPosts() {
        postController.retrieveFeed(withFeedType: feedType) { [weak self] (result) in
            guard let strongSelf = self else { return }
            /* [Custom for ONE Krungthai] [Improvement] Check is process reaction changing for ignore update post until add new reaction complete */
            if !strongSelf.isReactionChanging {
                switch result {
                case .success(let posts):
                    strongSelf.pinPostData += posts
                    strongSelf.debouncer.run {
                        strongSelf.prepareComponents(posts: strongSelf.pinPostData)
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
    
    func loadMore() {
        postController.loadMore()
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
    
    func addReaction(id: String, reaction: AmityReactionType, referenceType: AmityReactionReferenceType) {
        if !isReactionLoading {
            isReactionLoading = true
            reactionController.addReaction(withReaction: reaction, referanceId: id, referenceType: referenceType) { [weak self] (success, error) in
                guard let strongSelf = self else { return }
                if success {
                    strongSelf.isReactionLoading = false
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
