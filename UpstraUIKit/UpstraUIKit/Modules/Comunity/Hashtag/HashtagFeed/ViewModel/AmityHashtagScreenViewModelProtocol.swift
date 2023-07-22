//
//  AmityHashtagScreenViewModelProtocol.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 19/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityHashtagScreenViewModelDelegate: AnyObject {
    func screenViewModelDidUpdateDataSuccess(_ viewModel: AmityHashtagScreenViewModelType)
    func screenViewModelLoadingState(_ viewModel: AmityHashtagScreenViewModelType, for loadingState: AmityLoadingState)
    func screenViewModelScrollToTop(_ viewModel: AmityHashtagScreenViewModelType)
    func screenViewModelDidSuccess(_ viewModel: AmityHashtagScreenViewModelType, message: String)
    func screenViewModelDidFail(_ viewModel: AmityHashtagScreenViewModelType, failure error: AmityError)
    func screenViewModelLoadingStatusDidChange(_ viewModel: AmityHashtagScreenViewModelType, isLoading: Bool)
    func screenViewModelDidUpdateHashtagDataSuccess(_ viewModel: AmityHashtagScreenViewModelType, postCount: Int)
    
    // MARK: Post
    func screenViewModelDidLikePostSuccess(_ viewModel: AmityHashtagScreenViewModelType)
    func screenViewModelDidUnLikePostSuccess(_ viewModel: AmityHashtagScreenViewModelType)
    func screenViewModelDidGetReportStatusPost(isReported: Bool)
    
    // MARK: Comment
    func screenViewModelDidLikeCommentSuccess(_ viewModel: AmityHashtagScreenViewModelType)
    func screenViewModelDidUnLikeCommentSuccess(_ viewModel: AmityHashtagScreenViewModelType)
    func screenViewModelDidDeleteCommentSuccess(_ viewModel: AmityHashtagScreenViewModelType)
    func screenViewModelDidEditCommentSuccess(_ viewModel: AmityHashtagScreenViewModelType)
    
    // MARK: User
    func screenViewModelDidGetUserSettings(_ viewModel: AmityHashtagScreenViewModelType)
}

protocol AmityHashtagScreenViewModelDataSource {
    // MARK: PostComponents
    var isPrivate: Bool { get }
    var isLoading: Bool { get }
    func postComponents(in section: Int) -> AmityPostComponent
    func numberOfPostComponents() -> Int
    func getFeedType() -> AmityPostFeedType
}

protocol AmityHashtagScreenViewModelAction {
    
    // MARK: Fetch data
    func fetchPosts(keyword: String)
    func loadMore()
    func fetchHashtagData(keyword: String)
    func refresh()

    // MARK: PostId / CommentId
    func like(id: String, referenceType: AmityReactionReferenceType)
    func unlike(id: String, referenceType: AmityReactionReferenceType)
    
    func addReaction(id: String, reaction: AmityReactionType, referenceType: AmityReactionReferenceType)
    func removeReaction(id: String, reaction: AmityReactionType, referenceType: AmityReactionReferenceType)
    
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
}

protocol AmityHashtagScreenViewModelType: AmityHashtagScreenViewModelAction, AmityHashtagScreenViewModelDataSource {
    var delegate: AmityHashtagScreenViewModelDelegate? { get set }
    var action: AmityHashtagScreenViewModelAction { get }
    var dataSource: AmityHashtagScreenViewModelDataSource { get }
}

extension AmityHashtagScreenViewModelType {
    var action: AmityHashtagScreenViewModelAction { return self }
    var dataSource: AmityHashtagScreenViewModelDataSource { return self }
}
