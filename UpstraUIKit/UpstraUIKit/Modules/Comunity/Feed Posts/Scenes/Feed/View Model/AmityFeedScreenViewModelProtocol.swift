//
//  AmityFeedScreenViewModelProtocol.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 2/13/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityFeedScreenViewModelDelegate: AnyObject {
    func screenViewModelDidClearDataSuccess(_ viewModel: AmityFeedScreenViewModelType) // [Improvement] add did clear data success function for fetch post when scroll refresh from feed have post with URL Preview
    func screenViewModelDidUpdateDataSuccess(_ viewModel: AmityFeedScreenViewModelType)
    func screenViewModelLoadingState(_ viewModel: AmityFeedScreenViewModelType, for loadingState: AmityLoadingState)
    func screenViewModelScrollToTop(_ viewModel: AmityFeedScreenViewModelType)
    func screenViewModelDidSuccess(_ viewModel: AmityFeedScreenViewModelType, message: String)
    func screenViewModelDidFail(_ viewModel: AmityFeedScreenViewModelType, failure error: AmityError)
    func screenViewModelLoadingStatusDidChange(_ viewModel: AmityFeedScreenViewModelType, isLoading: Bool)
    func screenViewModelRouteToPostDetail(_ postId: String, viewModel: AmityFeedScreenViewModelType)
    
    // MARK: Post
    func screenViewModelDidLikePostSuccess(_ viewModel: AmityFeedScreenViewModelType)
    func screenViewModelDidUnLikePostSuccess(_ viewModel: AmityFeedScreenViewModelType)
    func screenViewModelDidGetReportStatusPost(isReported: Bool)

    // MARK: Comment
    func screenViewModelDidLikeCommentSuccess(_ viewModel: AmityFeedScreenViewModelType)
    func screenViewModelDidUnLikeCommentSuccess(_ viewModel: AmityFeedScreenViewModelType)
    func screenViewModelDidDeleteCommentSuccess(_ viewModel: AmityFeedScreenViewModelType)
    func screenViewModelDidEditCommentSuccess(_ viewModel: AmityFeedScreenViewModelType)
    
    // MARK: User
    func screenViewModelDidGetUserSettings(_ viewModel: AmityFeedScreenViewModelType)
}

protocol AmityFeedScreenViewModelDataSource {
    // MARK: PostComponents
    var isPrivate: Bool { get }
    var isLoading: Bool { get }
    func postComponents(in section: Int) -> AmityPostComponent
    func numberOfPostComponents() -> Int
    func getFeedType() -> AmityPostFeedType
}

protocol AmityFeedScreenViewModelAction {
    
    // MARK: Fetch data
    func fetchPosts()
    func loadMore()
    func clearOldPosts() // [Improvement] clear old post function for scroll to refresh with post URL preview for fix app crash because of invalid batch updates detected
    
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
}

protocol AmityFeedScreenViewModelType: AmityFeedScreenViewModelAction, AmityFeedScreenViewModelDataSource {
    var delegate: AmityFeedScreenViewModelDelegate? { get set }
    var action: AmityFeedScreenViewModelAction { get }
    var dataSource: AmityFeedScreenViewModelDataSource { get }
}

extension AmityFeedScreenViewModelType {
    var action: AmityFeedScreenViewModelAction { return self }
    var dataSource: AmityFeedScreenViewModelDataSource { return self }
}
