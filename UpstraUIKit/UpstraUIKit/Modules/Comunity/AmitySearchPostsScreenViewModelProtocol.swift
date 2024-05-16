//
//  AmitySearchPostsScreenViewModelProtocol.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 12/4/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import AmitySDK

protocol AmitySearchPostsScreenViewModelDelegate: AnyObject {
    func screenViewModelDidUpdateDataSuccess(_ viewModel: AmitySearchPostsScreenViewModelType)
    func screenViewModelLoadingState(_ viewModel: AmitySearchPostsScreenViewModelType, for loadingState: AmityLoadingState)
    func screenViewModelScrollToTop(_ viewModel: AmitySearchPostsScreenViewModelType)
    func screenViewModelDidSuccess(_ viewModel: AmitySearchPostsScreenViewModelType, message: String)
    func screenViewModelDidFail(_ viewModel: AmitySearchPostsScreenViewModelType, failure error: AmityError)
    func screenViewModelLoadingStatusDidChange(_ viewModel: AmitySearchPostsScreenViewModelType, isLoading: Bool)
    
    // MARK: Post
    func screenViewModelDidLikePostSuccess(_ viewModel: AmitySearchPostsScreenViewModelType)
    func screenViewModelDidUnLikePostSuccess(_ viewModel: AmitySearchPostsScreenViewModelType)
    func screenViewModelDidGetReportStatusPost(isReported: Bool)
    
    // MARK: Comment
    func screenViewModelDidLikeCommentSuccess(_ viewModel: AmitySearchPostsScreenViewModelType)
    func screenViewModelDidUnLikeCommentSuccess(_ viewModel: AmitySearchPostsScreenViewModelType)
    func screenViewModelDidDeleteCommentSuccess(_ viewModel: AmitySearchPostsScreenViewModelType)
    func screenViewModelDidEditCommentSuccess(_ viewModel: AmitySearchPostsScreenViewModelType)
    
    // MARK: User
    func screenViewModelDidGetUserSettings(_ viewModel: AmitySearchPostsScreenViewModelType)
}

protocol AmitySearchPostsScreenViewModelDataSource {
    // MARK: PostComponents
    var isPrivate: Bool { get }
    var isLoading: Bool { get }
    func postComponents(in section: Int) -> AmityPostComponent
    func numberOfPostComponents() -> Int
    func getFeedType() -> AmityPostFeedType
}

protocol AmitySearchPostsScreenViewModelAction {
    
    // MARK: Fetch data
    func fetchPosts(keyword: String)
    func loadMore()
    func refresh()

    // MARK: PostId / CommentId
    func like(id: String, referenceType: AmityReactionReferenceType)
    func unlike(id: String, referenceType: AmityReactionReferenceType)
    
    func addReaction(id: String, reaction: AmityReactionType, referenceType: AmityReactionReferenceType)
    func removeReaction(id: String, reaction: AmityReactionType, referenceType: AmityReactionReferenceType)
    func removeHoldReaction(id: String, reaction: AmityReactionType, referenceType: AmityReactionReferenceType, reactionSelect: AmityReactionType)
    
    // MARK: Post
    func delete(withPostId postId: String)
    func report(withPostId postId: String)
    func unreport(withPostId postId: String)
    func getReportStatus(withPostId postId: String)
    
    // MARK: Comment
    func delete(withCommentId commentId: String)
    func edit(withComment comment: AmityCommentModel, text: String, metadata: [String : Any]?, mentionees: AmityMentioneesBuilder?)
    func report(withCommentId commentId: String)
    func unreport(withCommentId commentId: String)
    func getReportStatus(withCommendId commendId: String, completion: ((Bool) -> Void)?)
    
    // MARK: Poll
    func vote(withPollId pollId: String?, answerIds: [String])
    func close(withPollId pollId: String?)
    
    // MARK: Observer
    func startObserveFeedUpdate()
    func stopObserveFeedUpdate()
    
    // MARK: User Settings
    func fetchUserSettings()
    
    // MARK: Share
    func forward(withChannelIdList channelIdList: [String], post: AmityPostModel)
    func checkChannelId(withSelectChannel selectChannel: [AmitySelectMemberModel], post: AmityPostModel)
}

protocol AmitySearchPostsScreenViewModelType: AmitySearchPostsScreenViewModelAction, AmitySearchPostsScreenViewModelDataSource {
    var delegate: AmitySearchPostsScreenViewModelDelegate? { get set }
    var action: AmitySearchPostsScreenViewModelAction { get }
    var dataSource: AmitySearchPostsScreenViewModelDataSource { get }
}

extension AmitySearchPostsScreenViewModelType {
    var action: AmitySearchPostsScreenViewModelAction { return self }
    var dataSource: AmitySearchPostsScreenViewModelDataSource { return self }
}
