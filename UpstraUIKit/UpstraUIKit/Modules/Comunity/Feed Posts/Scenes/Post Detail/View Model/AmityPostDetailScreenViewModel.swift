//
//  AmityPostDetailScreenViewModel.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 2/14/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import AmitySDK

final class AmityPostDetailScreenViewModel: AmityPostDetailScreenViewModelType {
    
    weak var delegate: AmityPostDetailScreenViewModelDelegate?
    
    // MARK: - Controller
    private let postController: AmityPostControllerProtocol
    private let commentController: AmityCommentControllerProtocol
    private let reactionController: AmityReactionControllerProtocol
    private let childrenController: AmityCommentChildrenController
    private let pollRepository: AmityPollRepository
    private let reactionRepository: AmityReactionRepository
    private let messageRepository: AmityMessageRepository
        
    private var postId: String
    private(set) var post: AmityPostModel?
    private var comments: [AmityCommentModel] = []
    private var viewModelArrays: [[PostDetailViewModel]] = []
    private let debouncer = Debouncer(delay: 0.3)
    private(set) var community: AmityCommunity?
    private var viewerCount: Int = 0
    private let dispatchGroup = DispatchGroup()

    private var isReactionLoading: Bool = false
    private var isReactionChanging: Bool = false // [Custom for ONE Krungthai] [Improvement] Add static value for check process reaction changing for ignore update post until add new reaction complete
    
    private var streamId: String?
    private var uniqueCommentIds = Set<String>()
    
    private var pollAnswers: [String: [String]]?
    
    public var reaction: [String: Int] = ["create": 0, "honest": 0, "harmony": 0, "success": 0, "society": 0, "like": 0, "love": 0]
    
    private var tokenArray: [AmityNotificationToken] = []

    init(withPostId postId: String,
         postController: AmityPostControllerProtocol,
         commentController: AmityCommentControllerProtocol,
         reactionController: AmityReactionControllerProtocol,
         childrenController: AmityCommentChildrenController,
         withStreamId streamId: String?,
         withPollAnswers pollAnswers: [String: [String]]
    ) {
        self.postId = postId
        self.postController = postController
        self.commentController = commentController
        self.reactionController = reactionController
        self.childrenController = childrenController
        self.pollRepository = AmityPollRepository(client: AmityUIKitManagerInternal.shared.client)
        self.reactionRepository = AmityReactionRepository(client: AmityUIKitManagerInternal.shared.client)
        self.messageRepository = AmityMessageRepository(client: AmityUIKitManagerInternal.shared.client)
        self.streamId = streamId
        self.pollAnswers = pollAnswers
    }
    
}

// MARK: - DataSource
extension AmityPostDetailScreenViewModel {
    
    func numberOfSection() -> Int {
        return viewModelArrays.count
    }
    
    func numberOfItems(_ tableView: AmityPostTableView, in section: Int) -> Int {
        let viewModels = viewModelArrays[section]
        if case .post(let postComponent) = viewModels.first(where: { $0.isPostType }) {
            // a postComponent has section/row manager, return its component count
            // a single post will be splited as 3 rows
            // example: [.post(component)] => [.header, .body, .footer]
            if let component = tableView.feedDataSource?.getUIComponentForPost(post: postComponent._composable.post, at: section) {
                return component.getComponentCount(for: section)
            }
            return postComponent.getComponentCount(for: section)
        }
        return viewModels.count
    }
    
    func item(at indexPath: IndexPath) -> PostDetailViewModel {
        let viewModels = viewModelArrays[indexPath.section]
        if let index = viewModels.firstIndex(where: { $0.isPostType }) {
            // a postComponent is separated to 3 rows already
            // enforce 3 of them accessing the same index
            // example: [.header, .body, .footer] => [.post(component)]
            return viewModels[index]
        }
        return viewModels[indexPath.row]
    }
    
    private func prepareComponents(post: AmityPostModel) -> AmityPostComponent {
        post.appearance.displayType = .postDetail
        switch post.dataTypeInternal {
        case .text:
            return AmityPostComponent(component: AmityPostTextComponent(post: post))
        case .image:
            return AmityPostComponent(component: AmityPostMediaComponent(post: post))
        case .file:
            return AmityPostComponent(component: AmityPostFileComponent(post: post))
        case .video:
            return AmityPostComponent(component: AmityPostMediaComponent(post: post))
        case .poll:
            return AmityPostComponent(component: AmityPostPollComponent(post: post))
        case .liveStream:
            return AmityPostComponent(component: AmityPostLiveStreamComponent(post: post))
        case .unknown:
            return AmityPostComponent(component: AmityPostPlaceHolderComponent(post: post))
        }
    }
    
    func getPostReportStatus() {
        postController.getReportStatus(withPostId: postId) { [weak self] (isReported) in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.screenViewModel(strongSelf, didReceiveReportStatus: isReported)
        }
    }
    
    func getReactionList() -> [String: Int] {
        return reaction
    }
    
    // MARK: - Helper
    
    private func prepareData() {
        var viewModels = [[PostDetailViewModel]]()
        
        // prepare post
        if let post = post {
            if let community = post.targetCommunity {
                self.community = community
                let communityId = community.communityId
                let participation = AmityCommunityParticipation(client: AmityUIKitManagerInternal.shared.client, andCommunityId: communityId)
                post.isModerator = participation.getMember(withId: post.postedUserId)?.hasModeratorRole ?? false
            }
            post.pollAnswers = pollAnswers ?? [:]

            // Mapping new reaction value from updated post
            reaction.forEach { key, value in
                if let newValue = post.reactions[key] {
                    reaction[key] = newValue
                } else {
                    reaction[key] = 0
                }
            }
            
            let component = prepareComponents(post: post)
            viewModels.append([.post(component)])
        }
        
        // prepare comments
        for model in comments {
            var commentsModels = [PostDetailViewModel]()
            
            // parent comment
            commentsModels.append(.comment(model))
            
            // Check if commentId is unique
            if !uniqueCommentIds.contains(model.id) {
                uniqueCommentIds.insert(model.id)
            } else {
                continue
            }
            
            // if parent is deleted, don't show its children.
            guard !model.isDeleted else {
                viewModels.append(commentsModels)
                continue
            }
            
            // child comments
            let parentId = model.id
            var loadedItems = childrenController.childrenComments(for: parentId)
            let itemToDisplay = childrenController.numberOfDisplayingItem(for: parentId)
            let deletedItemCount = childrenController.numberOfDeletedChildren(for: parentId)
            
            /* [Fix-defect] Disable this condition for set ascending of reply comment */
            // loadedItems will be empty on the first load.
            // set childrenComment directly to reduce number of server request.
//            if loadedItems.isEmpty {
//                loadedItems = model.childrenComment.reversed()
//            }
            
            // model.childrenNumber doesn't include deleted children.
            // so, add it directly to correct the total count.
            let totalItemCount = model.childrenNumber + deletedItemCount
            let shouldShowLoadmore = itemToDisplay < totalItemCount
            let isReadyToShow = itemToDisplay <= loadedItems.count
            let isAllLoaded = loadedItems.count == totalItemCount
            
            // visible items are limited by itemToDisplay.
            // see more: AmityCommentChildrenController.swift
            let postDetailViewModels: [PostDetailViewModel] = loadedItems.map({ PostDetailViewModel.replyComment($0) })
            commentsModels += Array(postDetailViewModels.prefix(itemToDisplay))
            
            if shouldShowLoadmore {
                commentsModels.append(.loadMoreReply)
            }
            if !(isReadyToShow || isAllLoaded) {
                loadChild(commentId: model.id)
            }
            
            viewModels.append(commentsModels)
        }
        
        self.viewModelArrays = viewModels
        self.uniqueCommentIds = []
        delegate?.screenViewModelDidUpdateData(self)
        delegate?.screenViewModel(self, didUpdateloadingState: .loaded)
    }
    
    private func loadChild(commentId: String) {
        childrenController.fetchChildren(for: commentId) { [weak self] in
            self?.debouncer.run {
                self?.prepareData()
            }
        }
    }

}

// MARK: - Action
extension AmityPostDetailScreenViewModel {
    
    // MARK: Reaction

    // Not use
    func fetchReactionList() {
        for objData in reaction {
            dispatchGroup.enter()
            
            DispatchQueue.main.async { [self] in
                var liveCollection: AmityCollection<AmityReaction>
                let token: AmityNotificationToken
                
                // Query reactions
                liveCollection = reactionRepository.getReactions(postId, referenceType: .post, reactionName: objData.key)
                token = liveCollection.observeOnce({ [weak self] liveCollection, _, error in
                    guard let strongSelf = self else { return }
                    
                    let allObjects = liveCollection.allObjects()
                    let count = allObjects.map { ReactionUser(reaction: $0) }.count
                    
                    if var oldValue = strongSelf.reaction[objData.key] {
                        oldValue = count
                        strongSelf.reaction[objData.key] = oldValue
                    }
                    
                    strongSelf.dispatchGroup.leave()
                })
                
                tokenArray.append(token)
            }
        }
        
        dispatchGroup.notify(queue: .main) { [self] in
            tokenArray.removeAll()
        }
    }
    
    // MARK: Post
    
    func fetchPost() {
        func getPostId(withStreamId streamId: String, completion: @escaping (String) -> Void) {
            // Simulate your API request using a service object or Alamofire, etc.
            let serviceRequest = RequestGetPost()
            serviceRequest.requestPostIdByStreamId(streamId) { result in
                switch result {
                case .success(let dataResponse):
                    let postId = dataResponse.postId ?? ""
                    completion(postId)
                case .failure(_):
                    completion("")
                }
            }
        }
        
        func getViewerCount(withpostId postId: String, completion: @escaping (Int) -> Void) {
            // Simulate your API request using a service object or Alamofire, etc.
            let serviceRequest = RequestGetViewerCount()
            serviceRequest.request(postId: postId, viewerUserId: AmityUIKitManager.currentUserToken, viewerDisplayName: AmityUIKitManager.displayName, isTrack: false, streamId: ""){ result in
                switch result {
                case .success(let dataResponse):
                    let viwerCount = dataResponse.viewerCount ?? 0
                    completion(viwerCount)
                case .failure(_):
                    completion(0)
                }
            }
        }
        
        func doFetchPost() {
            DispatchQueue.main.async { [self] in
                postController.getPostForPostId(withPostId: postId) { [weak self] (result) in
                    guard let strongSelf = self else { return }
                    switch result {
                    case .success(let post):
                        strongSelf.post = post
                        strongSelf.post?.viewerCount = strongSelf.viewerCount ?? 0
                        
                        /* [Custom for ONE Krungthai] [Improvement] Check is process reaction changing for ignore update post until add new reaction complete */
                        let isReactionChanging = strongSelf.isReactionChanging ?? false
                        if !isReactionChanging {
                            strongSelf.debouncer.run {
                                strongSelf.prepareData()
                            }
                        }
                        strongSelf.isReactionChanging = false // [Custom for ONE Krungthai] [Improvement] Force set static value for check process reaction changing to false if reaction changing have problem
                    case .failure(let error):
                        strongSelf.delegate?.screenViewModel(strongSelf, didFinishWithError: AmityError(error: error) ?? .unknown)
                    }
                }
            }
        }
        
        func doFetchViewerCount() {
            DispatchQueue.main.async { [self] in
                getViewerCount(withpostId: postId) { [self] viewerCount in
                    self.viewerCount = viewerCount
                    doFetchPost()
                }
            }
        }
        
        if postId == "" {
            DispatchQueue.main.async {
                // Get postId by streamId with API
                getPostId(withStreamId: self.streamId ?? "") { [self] postId in
                    self.postId = postId
//                    doFetchPost()
                    doFetchViewerCount()
                    fetchComments()
                }
            }
        } else {
            doFetchViewerCount()
//            doFetchPost()
        }
    }
    
    func fetchComments() {
        DispatchQueue.main.async { [self] in
            commentController.getCommentsForPostId(withReferenceId: postId, referenceType: .post, filterByParentId: true, parentId: nil, orderBy: .ascending, includeDeleted: true) { [weak self] (result) in
                guard let strongSelf = self else { return }
                switch result {
                case .success(let comments):
                    strongSelf.comments = comments
                    strongSelf.debouncer.run {
                        strongSelf.prepareData()
                    }
                case .failure:
                    break
                }
            }
        }
    }
    
    func loadMoreComments() {
        if commentController.hasMoreComments {
            delegate?.screenViewModel(self, didUpdateloadingState: .loading)
            commentController.loadMoreComments()
        }
    }
    
    func updatePost(withText text: String) {
        postController.update(withPostId: postId, text: text) { [weak self] (post, error) in
            guard let strongSelf = self else { return }
            if let error = AmityError(error: error) {
                strongSelf.delegate?.screenViewModel(strongSelf, didFinishWithError: AmityError(error: error) ?? .unknown)
            } else {
                strongSelf.delegate?.screenViewModelDidUpdatePost(strongSelf)
            }
        }
    }
    
    func likePost() {
        reactionController.addReaction(withReaction: .like, referanceId: postId, referenceType: .post) { [weak self] (success, error) in
            guard let strongSelf = self else { return }
            if success {
                strongSelf.delegate?.screenViewModelDidLikePost(strongSelf)
            } else {
                strongSelf.delegate?.screenViewModel(strongSelf, didFinishWithError: AmityError(error: error) ?? .unknown)
            }
        }
    }
    
    func unlikePost() {
        reactionController.removeReaction(withReaction: .like, referanceId: postId, referenceType: .post) { [weak self] (success, error) in
            guard let strongSelf = self else { return }
            if success {
                strongSelf.delegate?.screenViewModelDidUnLikePost(strongSelf)
            } else {
                strongSelf.delegate?.screenViewModel(strongSelf, didFinishWithError: AmityError(error: error) ?? .unknown)
            }
        }
    }
    
    func addReactionPost(type: AmityReactionType) {
        if !isReactionLoading {
            reactionController.addReaction(withReaction: type, referanceId: postId, referenceType: .post) { [weak self] (success, error) in
                guard let strongSelf = self else { return }
                strongSelf.isReactionLoading = false
                if success {
                    strongSelf.delegate?.screenViewModelDidLikePost(strongSelf)
                } else {
                    strongSelf.delegate?.screenViewModel(strongSelf, didFinishWithError: AmityError(error: error) ?? .unknown)
                }
            }
        }
    }
    
    func removeReactionPost(type: AmityReactionType) {
        if !isReactionLoading {
            reactionController.removeReaction(withReaction: type, referanceId: postId, referenceType: .post) { [weak self] (success, error) in
                guard let strongSelf = self else { return }
                strongSelf.isReactionLoading = false
                if success {
                    strongSelf.delegate?.screenViewModelDidUnLikePost(strongSelf)
                } else {
                    strongSelf.delegate?.screenViewModel(strongSelf, didFinishWithError: AmityError(error: error) ?? .unknown)
                }
            }
        }
    }
    
    func removeHoldReactionPost(type: AmityReactionType, typeSelect: AmityReactionType) {
        if !isReactionLoading {
            isReactionLoading = true
            isReactionChanging = true // [Custom for ONE Krungthai] [Improvement] Set static value for check process reaction changing to true for start reaction changing
            reactionController.removeReaction(withReaction: type, referanceId: postId, referenceType: .post) { [weak self] (success, error) in
                guard let strongSelf = self else { return }
                strongSelf.isReactionLoading = false
                strongSelf.isReactionChanging = false // [Custom for ONE Krungthai] [Improvement] Set static value for check process reaction changing to false for don't ignore update post next time
                if success {
                    strongSelf.delegate?.screenViewModelDidUnLikePost(strongSelf)
                    strongSelf.addReactionPost(type: typeSelect)
                } else {
                    strongSelf.delegate?.screenViewModel(strongSelf, didFinishWithError: AmityError(error: error) ?? .unknown)
                }
            }
        }
    }
    
    func deletePost() {
        postController.delete(withPostId: postId, parentId: nil) { [weak self] (success, error) in
            guard let strongSelf = self else { return }
            if success {
                NotificationCenter.default.post(name: NSNotification.Name.Post.didDelete, object: nil)
            } else {
                strongSelf.delegate?.screenViewModel(strongSelf, didFinishWithError: AmityError(error: error) ?? .unknown)
            }
        }
    }
    
    func reportPost() {
        postController.report(withPostId: postId) { [weak self] (success, error) in
            self?.reportHandler(success: success, error: error)
        }
    }
    
    func unreportPost() {
        postController.unreport(withPostId: postId) { [weak self] (success, error) in
            self?.unreportHandler(success: success, error: error)
        }
    }
    
    // MARK: Commend
    
    func createComment(withText text: String, parentId: String?, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?) {
        commentController.createComment(withReferenceId: postId, referenceType: .post, parentId: parentId, text: text, metadata: metadata, mentionees: mentionees) { [weak self] (comment, error) in
            guard let strongSelf = self else { return }
            
            // Need to check SDK implementation.
            // found an issue where the callback is invoked in the realm write transaction.
            // so just make a workaround by dispatching it out of the transaction scope.
            DispatchQueue.main.async {
                if let comment = comment {
                    strongSelf.delegate?.screenViewModelDidCreateComment(strongSelf, comment: AmityCommentModel(comment: comment))
                } else {
                    strongSelf.delegate?.screenViewModel(strongSelf, didFinishWithError: AmityError(error: error) ?? .unknown)
                }
            }
        }
    }
    
    func deleteComment(with comment: AmityCommentModel) {
        commentController.delete(withCommentId: comment.id) { [weak self] (success, error) in
            guard let strongSelf = self else { return }
            if success {
                strongSelf.delegate?.screenViewModelDidDeleteComment(strongSelf)
            } else {
                strongSelf.delegate?.screenViewModel(strongSelf, didFinishWithError: AmityError(error: error) ?? .unknown)
            }
        }
    }
    
    func editComment(with comment: AmityCommentModel, text: String, metadata: [String : Any]?, mentionees: AmityMentioneesBuilder?) {
        commentController.edit(withComment: comment, text: text, metadata: metadata, mentionees: mentionees) { [weak self] (success, error) in
            guard let strongSelf = self else { return }
            if success {
                strongSelf.delegate?.screenViewModelDidEditComment(strongSelf)
            } else {
                strongSelf.delegate?.screenViewModel(strongSelf, didFinishWithError: AmityError(error: error) ?? .unknown)
            }
        }
    }
    
    func likeComment(withCommendId commentId: String) {
        reactionController.addReaction(withReaction: .like, referanceId: commentId, referenceType: .comment) { [weak self] (success, error) in
            guard let strongSelf = self else { return }
            if success {
                strongSelf.delegate?.screenViewModelDidLikeComment(strongSelf)
            } else {
                strongSelf.delegate?.screenViewModel(strongSelf, didFinishWithError: AmityError(error: error) ?? .unknown)
            }
        }
    }
    
    func unlikeComment(withCommendId commentId: String) {
        reactionController.removeReaction(withReaction: .like, referanceId: commentId, referenceType: .comment) { [weak self] (success, error) in
            guard let strongSelf = self else { return }
            if success {
                strongSelf.delegate?.screenViewModelDidUnLikeComment(strongSelf)
            } else {
                strongSelf.delegate?.screenViewModel(strongSelf, didFinishWithError: AmityError(error: error) ?? .unknown)
            }
        }
    }
    
    func reportComment(withCommentId commentId: String) {
        commentController.report(withCommentId: commentId) { [weak self] (success, error) in
            self?.reportHandler(success: success, error: error)
        }
    }
    
    func unreportComment(withCommentId commentId: String) {
        commentController.unreport(withCommentId: commentId) { [weak self] (success, error) in
            self?.unreportHandler(success: success, error: error)
        }
    }
    
    func getCommentReportStatus(with comment: AmityCommentModel) {
        commentController.getReportStatus(withCommentId: comment.id) { [weak self] (isReported) in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.screenViewModel(strongSelf, comment: comment, didReceiveCommentReportStatus: isReported)
        }
    }
    
    func getReplyComments(at section: Int) {
        // get parent comment at section
        guard case .comment(let comment) = viewModelArrays[section].first else { return }
        childrenController.increasePageNumber(for: comment.id)
        debouncer.run { [weak self] in
            self?.prepareData()
        }
    }

    // MARK: Report handler
    
    func reportHandler(success: Bool, error: Error?) {
        if success {
            delegate?.screenViewModel(self, didFinishWithMessage: AmityLocalizedStringSet.HUD.reportSent)
        } else {
            delegate?.screenViewModel(self, didFinishWithError: AmityError(error: error) ?? .unknown)
        }
    }
    
    func unreportHandler(success: Bool, error: Error?) {
        if success {
            delegate?.screenViewModel(self, didFinishWithMessage: AmityLocalizedStringSet.HUD.unreportSent)
        } else {
            delegate?.screenViewModel(self, didFinishWithError: AmityError(error: error) ?? .unknown)
        }
    }
    
}

// MARK: Poll
extension AmityPostDetailScreenViewModel {
    
    func vote(withPollId pollId: String?, answerIds: [String]) {
        guard let pollId = pollId else { return }
        pollRepository.votePoll(withId: pollId, answerIds: answerIds) { [weak self] success, error in
            guard let strongSelf = self else { return }
            if success {
                self?.debouncer.run {
                    self?.fetchPost()
                }
            } else {
                strongSelf.delegate?.screenViewModel(strongSelf, didFinishWithError: AmityError(error: error) ?? .unknown)
            }
        }
    }
    
    func close(withPollId pollId: String?) {
        guard let pollId = pollId else { return }
        pollRepository.closePoll(withId: pollId) { [weak self] success, error in
            guard let strongSelf = self else { return }
            if success {
                self?.debouncer.run {
                    self?.fetchPost()
                }
            } else {
                strongSelf.delegate?.screenViewModel(strongSelf, didFinishWithError: AmityError(error: error) ?? .unknown)
            }
        }
    }
    
}

// MARK: - Share to Chat
extension AmityPostDetailScreenViewModel {
    
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
