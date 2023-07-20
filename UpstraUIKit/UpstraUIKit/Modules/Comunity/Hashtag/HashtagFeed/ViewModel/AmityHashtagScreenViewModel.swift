//
//  AmityHashtagScreenViewModel.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 19/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

class AmityHashtagScreenViewModel: AmityHashtagScreenViewModelType {
    
    // MARK: - Delegate
    weak var delegate: AmityHashtagScreenViewModelDelegate?
    
    // MARK: - Controller
    private let postController: AmityPostControllerProtocol
    private let commentController: AmityCommentControllerProtocol
    private let reactionController: AmityReactionControllerProtocol
    private let pollRepository: AmityPollRepository
    private let repository = AmityPostRepository(client: AmityUIKitManagerInternal.shared.client)
    
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
    
    private var keyword: String = ""
    
    private var tokenArray: [AmityNotificationToken?] = []
    private var fromIndex: Int = 0
    private let dispatchGroup = DispatchGroup()
    private var postLists: [AmityPostModel] = []
    
    init(withFeedType feedType: AmityPostFeedType,
         postController: AmityPostControllerProtocol,
         commentController: AmityCommentControllerProtocol,
         reactionController: AmityReactionControllerProtocol,
         keyword: String) {
        self.feedType = feedType
        self.postController = postController
        self.commentController = commentController
        self.reactionController = reactionController
        self.isPrivate = false
        self.isLoading = false
        self.pollRepository = AmityPollRepository(client: AmityUIKitManagerInternal.shared.client)
        self.keyword = keyword
    }
    
}

// MARK: - DataSource
extension AmityHashtagScreenViewModel {
    
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
        delegate?.screenViewModelDidUpdateDataSuccess(self)
    }
    
    private func addComponent(component: AmityPostComposable) {
        postComponents.append(AmityPostComponent(component: component))
    }
}

// MARK: - Action
// MARK: Fetch data
extension AmityHashtagScreenViewModel {
    
    func fetchPosts(keyword: String) {
        isLoading = true
        var serviceRequest = RequestSearchingPosts()
        serviceRequest.keyword = keyword
        serviceRequest.from = fromIndex
        serviceRequest.request { result in
            switch result {
            case .success(let data):
                self.getPostbyPostIDsList(posts: data)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func loadMore() {
        fromIndex += 20
        fetchPosts(keyword: keyword)
    }
    
    func getPostbyPostIDsList(posts: AmitySearchPostsModel) {
        DispatchQueue.main.async { [self] in
            for postId in posts.postIDS {
                dispatchGroup.enter()
                let postCollection = repository.getPost(withId: postId)
                let token = postCollection.observe { [weak self] (_, error) in
                    guard let strongSelf = self else { return }
                    if let error = AmityError(error: error) {
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
                
                dispatchGroup.notify(queue: .main) {
                    let sortedArray = self.sortArrayPositions(array1: posts.postIDS, array2: self.postLists)
                    self.prepareComponents(posts: sortedArray)
                    self.tokenArray.removeAll()
                }
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
    
    func fetchHashtagData(keyword: String) {
        var serviceRequest = RequestHashtag()
        serviceRequest.keyword = keyword.replacingOccurrences(of: "#", with: "")
        serviceRequest.size = 1
        serviceRequest.request { result in
            switch result {
            case .success(let data):
                if let data = data.hashtag, !data.isEmpty {
                    self.delegate?.screenViewModelDidUpdateHashtagDataSuccess(self, postCount: data[0].count ?? 0)
                } else {
                    self.delegate?.screenViewModelDidUpdateHashtagDataSuccess(self, postCount: 0)
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}

// MARK: Observer
extension AmityHashtagScreenViewModel {
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
extension AmityHashtagScreenViewModel {
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
        reactionController.addReaction(withReaction: reaction, referanceId: id, referenceType: referenceType) { [weak self] (success, error) in
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
    
    func removeReaction(id: String, reaction: AmityReactionType, referenceType: AmityReactionReferenceType) {
        reactionController.removeReaction(withReaction: reaction, referanceId: id, referenceType: referenceType) { [weak self] (success, error) in
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
}

// MARK: Post
extension AmityHashtagScreenViewModel {
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
extension AmityHashtagScreenViewModel {
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
private extension AmityHashtagScreenViewModel {
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
extension AmityHashtagScreenViewModel {
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
extension AmityHashtagScreenViewModel {
    
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
