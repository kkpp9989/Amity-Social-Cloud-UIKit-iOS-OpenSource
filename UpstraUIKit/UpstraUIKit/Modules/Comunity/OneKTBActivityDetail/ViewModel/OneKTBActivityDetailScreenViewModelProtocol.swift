//
//  OneKTBActivityDetailScreenViewModelProtocol.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 22/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol OneKTBActivityDetailScreenViewModelDelegate: AnyObject {
    // MARK: - Loading state
    func screenViewModel(_ viewModel: OneKTBActivityDetailScreenViewModelType, didUpdateloadingState state: AmityLoadingState)
    
    // MARK: - Post
    func screenViewModelDidUpdateData(_ viewModel: OneKTBActivityDetailScreenViewModelType)
    func screenViewModelDidUpdatePost(_ viewModel: OneKTBActivityDetailScreenViewModelType)
    func screenViewModelDidLikePost(_ viewModel: OneKTBActivityDetailScreenViewModelType)
    func screenViewModelDidUnLikePost(_ viewModel: OneKTBActivityDetailScreenViewModelType)
    func screenViewModel(_ viewModel: OneKTBActivityDetailScreenViewModelType, didReceiveReportStatus isReported: Bool)
    
    // MARK: - Comment
    func screenViewModelDidDeleteComment(_ viewModel: OneKTBActivityDetailScreenViewModelType)
    func screenViewModelDidEditComment(_ viewModel: OneKTBActivityDetailScreenViewModelType)
    func screenViewModelDidLikeComment(_ viewModel: OneKTBActivityDetailScreenViewModelType)
    func screenViewModelDidUnLikeComment(_ viewModel: OneKTBActivityDetailScreenViewModelType)
    func screenViewModelDidCreateComment(_ viewModel: OneKTBActivityDetailScreenViewModelType, comment: AmityCommentModel)
    func screenViewModel(_ viewModel: OneKTBActivityDetailScreenViewModelType, comment: AmityCommentModel, didReceiveCommentReportStatus isReported: Bool)
    func screenViewModel(_ viewModel: OneKTBActivityDetailScreenViewModelType, didFinishWithMessage message: String)
    func screenViewModel(_ viewModel: OneKTBActivityDetailScreenViewModelType, didFinishWithError error: AmityError)
}

protocol OneKTBActivityDetailScreenViewModelDataSource {
    var post: AmityPostModel? { get }
    var community: AmityCommunity? { get }
    func numberOfSection() -> Int
    func numberOfItems(_ tableView: AmityPostTableView, in section: Int) -> Int
    func item(at indexPath: IndexPath) -> PostDetailViewModel
    func getReactionList() -> [String: Int]
}

protocol OneKTBActivityDetailScreenViewModelAction {
    
    // MARK: Fetch data
    func fetchPost()
    func fetchComments()
    func loadMoreComments()
    func fetchReactionList()

    // MARK: Post
    func updatePost(withText text: String)
    func likePost()
    func unlikePost()
    func addReactionPost(type: AmityReactionType)
    func removeReactionPost(type: AmityReactionType)
    func removeHoldReactionPost(type: AmityReactionType, typeSelect: AmityReactionType)
    func deletePost()
    func reportPost()
    func unreportPost()
    func getPostReportStatus()
    
    // MARK: Comment
    func createComment(withText text: String, parentId: String?, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?)
    func editComment(with comment: AmityCommentModel, text: String, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?)
    func deleteComment(with comment: AmityCommentModel)
    func likeComment(withCommendId commentId: String)
    func unlikeComment(withCommendId commentId: String)
    func reportComment(withCommentId commentId: String)
    func unreportComment(withCommentId commentId: String)
    func getCommentReportStatus(with comment: AmityCommentModel)
    func getReplyComments(at section: Int)
    
    // MARK: Poll
    func vote(withPollId pollId: String?, answerIds: [String])
    func close(withPollId pollId: String?)
    
    // MARK: Share
    func forward(withChannelIdList channelIdList: [String], post: AmityPostModel)
    func checkChannelId(withSelectChannel selectChannel: [AmitySelectMemberModel], post: AmityPostModel)
}

protocol OneKTBActivityDetailScreenViewModelType: OneKTBActivityDetailScreenViewModelAction, OneKTBActivityDetailScreenViewModelDataSource {
    var delegate: OneKTBActivityDetailScreenViewModelDelegate? { get set }
    var action: OneKTBActivityDetailScreenViewModelAction { get }
    var dataSource: OneKTBActivityDetailScreenViewModelDataSource { get }
}

extension OneKTBActivityDetailScreenViewModelType {
    var action: OneKTBActivityDetailScreenViewModelAction { return self }
    var dataSource: OneKTBActivityDetailScreenViewModelDataSource { return self }
}
