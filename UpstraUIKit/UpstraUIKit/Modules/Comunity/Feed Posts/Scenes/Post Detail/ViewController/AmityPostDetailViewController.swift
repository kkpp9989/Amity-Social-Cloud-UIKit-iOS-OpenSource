//
//  AmityPostDetailViewController.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 2/14/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

/// A view controller for providing post and relevant comments.
open class AmityPostDetailViewController: AmityViewController {
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var tableView: AmityPostTableView!
    @IBOutlet private var commentComposeBarView: AmityPostDetailCompostView!
    @IBOutlet private var commentComposeBarBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var mentionTableView: AmityMentionTableView!
    @IBOutlet private var mentionTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var hashtagTableView: AmityHashtagTableView!
    @IBOutlet private var hashtagTableViewHeightConstraint: NSLayoutConstraint!
    
    private var optionButton: UIBarButtonItem!
    
    // MARK: - Post Protocol Handler
    private var postHeaderProtocolHandler: AmityPostHeaderProtocolHandler?
    private var postFooterProtocolHandler: AmityPostFooterProtocolHandler?
    private var postProtocolHandler: AmityPostProtocolHandler?
    
    // MARK: - Properties
    private var screenViewModel: AmityPostDetailScreenViewModelType
    private var selectedIndexPath: IndexPath?
    private var referenceId: String?
    private var expandedIds: Set<String> = []
    private var showReplyIds: [String] = []
    private var mentionManager: AmityMentionManager?
    private var pollAnswers: [String: [String]] = [:]
    
    private var livestreamId: String?
    
    private var parentComment: AmityCommentModel? {
        didSet {
            // [Custom for ONE Krungthai] Add check moderator user in official community for outputing
            if let currentPost = screenViewModel.post, let community = currentPost.targetCommunity, let comment = parentComment { // Case : Comment from post community
                let isModeratorUserInOfficialCommunity = AmityMemberCommunityUtilities.isModeratorUserInCommunity(withUserId: comment.userId, communityId: community.communityId)
                let isOfficialCommunity = community.isOfficial
                if isModeratorUserInOfficialCommunity, isOfficialCommunity { // Case : Comment owner is moderator in official community
                    commentComposeBarView.replyingUsername = community.displayName
                } else { // Case : Comment owner isn't moderator or not official community
                    // Original
                    commentComposeBarView.replyingUsername = parentComment?.displayName
                }
            } else { // Case : Comment from user profile post
                // Original
                commentComposeBarView.replyingUsername = parentComment?.displayName
            }
            // [Original]
//            commentComposeBarView.replyingUsername = parentComment?.displayName
        }
    }
    
    // Reaction Picker
    private let reactionPickerView = AmityReactionPickerView()
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    
    // MARK: - Initializer
    required public init(withPostId postId: String, withStreamId streamId: String?, withPollAnswers pollAnswers: [String: [String]]?) {
        let postController = AmityPostController()
        let commentController = AmityCommentController()
        let reactionController = AmityReactionController()
        let childrenController = AmityCommentChildrenController(postId: postId)
        screenViewModel = AmityPostDetailScreenViewModel(withPostId: postId,
                                                         postController: postController,
                                                         commentController: commentController,
                                                         reactionController: reactionController,
                                                         childrenController: childrenController,
                                                         withStreamId: streamId,
                                                         withPollAnswers: pollAnswers ?? [:])
        super.init(nibName: AmityPostDetailViewController.identifier, bundle: AmityUIKitManager.bundle)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func make(withPostId postId: String, withStreamId streamId: String? = nil, withPollAnswers pollAnswers: [String: [String]]? = [:]) -> Self {
        return self.init(withPostId: postId, withStreamId: streamId, withPollAnswers: pollAnswers)
    }
    
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        /* [Improvement] Move add option button of navigation bar to get post success data because of click post notification */
//        setupNavigationBar()
        setupTableView()
        setupComposeBarView()
        setupProtocolHandler()
        setupScreenViewModel()
        setupMentionTableView()
        setupHashtagTableView()
        setupReactionPicker()
        
        // Initial ONE Krungthai Custom theme
        theme = ONEKrungthaiCustomTheme(viewController: self)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setBackgroundColor(with: .white)
        AmityKeyboardService.shared.delegate = self
        mentionManager?.delegate = self
        mentionManager?.setColor(AmityColorSet.base, highlightColor: AmityColorSet.primary)
        mentionManager?.setFont(AmityFontSet.body, highlightFont: AmityFontSet.bodyBold)
        
        // Set color navigation bar by custom theme
        theme?.setBackgroundNavigationBar()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.reset()
        mentionManager?.delegate = nil
    }
    
    // MARK: Setup Post Protocol Handler
    private func setupProtocolHandler() {
        postHeaderProtocolHandler = AmityPostHeaderProtocolHandler(viewController: self)
        postHeaderProtocolHandler?.delegate = self
        
        postFooterProtocolHandler = AmityPostFooterProtocolHandler(viewController: self)
        postFooterProtocolHandler?.delegate = self
        
        postProtocolHandler = AmityPostProtocolHandler()
        postProtocolHandler?.delegate = self
        postProtocolHandler?.viewController = self
        postProtocolHandler?.tableView = tableView
    }
    
    // MARK: - Setup ViewModel
    private func setupScreenViewModel() {
        screenViewModel.delegate = self
        screenViewModel.action.fetchPost()
        screenViewModel.action.fetchComments()
//        screenViewModel.action.fetchReactionList() // Use post.reactions in screenviewModel instead
    }
    
    // MARK: Setup views
    private func setupView() {
        view.backgroundColor = AmityColorSet.backgroundColor
    }
    
    private func setupNavigationBar() {
        optionButton = UIBarButtonItem(image: AmityIconSet.iconOptionNavigationBar?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(optionTap)) // [Custom for ONE Krungthai] Set custom icon theme
        optionButton.tintColor = AmityColorSet.base
        navigationItem.rightBarButtonItem = optionButton
    }
    
    private func setupTableView() {
        tableView.registerCustomCell()
        tableView.registerPostCell()
        tableView.register(cell: AmityCommentTableViewCell.self)
        tableView.register(cell: AmityPostDetailDeletedTableViewCell.self)
        tableView.register(cell: AmityViewMoreReplyTableViewCell.self)
        tableView.register(cell: AmityDeletedReplyTableViewCell.self)
        tableView.backgroundColor = AmityColorSet.backgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.postDelegate = self
        tableView.postDataSource = self
        tableView.contentInsetAdjustmentBehavior = .never
    }
    
    private func setupMentionTableView() {
        mentionTableView.isHidden = true
        mentionTableView.delegate = self
        mentionTableView.dataSource = self
    }
    
    private func setupHashtagTableView() {
        hashtagTableView.isHidden = true
        hashtagTableView.delegate = self
        hashtagTableView.dataSource = self
        hashtagTableView.tag = 1
        hashtagTableView.backgroundColor = .red
    }
    
    private func setupComposeBarView() {
        commentComposeBarView.delegate = self
        commentComposeBarView.isHidden = true
    }
    
    private func setupReactionPicker() {
        
        reactionPickerView.alpha = 0
        view.addSubview(reactionPickerView)
        
        // Setup tap gesture recognizer
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissReactionPicker))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func optionTap() {
        guard let post = screenViewModel.post else {
            assertionFailure("Post should not be nil")
            return
        }
        if post.isOwner {
            
            let bottomSheet = BottomSheetViewController()
            let contentView = ItemOptionView<TextItemOption>()
            bottomSheet.isTitleHidden = true
            bottomSheet.sheetContentView = contentView
            bottomSheet.modalPresentationStyle = .overFullScreen
            
            
            let editOption = TextItemOption(title: AmityLocalizedStringSet.PostDetail.editPost.localizedString) { [weak self] in
                guard let strongSelf = self else { return }
                AmityEventHandler.shared.editPostDidTap(from: strongSelf, postId: post.postId)
            }
            
            let deleteOption = TextItemOption(title: AmityLocalizedStringSet.PostDetail.deletePost.localizedString) { [weak self] in
                // delete option
                let alert = UIAlertController(title: AmityLocalizedStringSet.PostDetail.deletePostTitle.localizedString, message: AmityLocalizedStringSet.PostDetail.deletePostMessage.localizedString, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: AmityLocalizedStringSet.General.delete.localizedString, style: .destructive, handler: { [weak self] _ in
                    self?.screenViewModel.deletePost()
                    self?.navigationController?.popViewController(animated: true)
                }))
                self?.present(alert, animated: true, completion: nil)
            }
            
            switch post.dataTypeInternal {
            case .poll:
                let closePoll = TextItemOption(title: AmityLocalizedStringSet.Poll.Option.closeTitle.localizedString) { [weak self] in
                    guard let strongSelf = self else { return }
                    let cancel = AmityAlertController.Action.cancel(style: .default, handler: nil)
                    let close = AmityAlertController.Action.custom(title: AmityLocalizedStringSet.Poll.Option.closeTitle.localizedString, style: .destructive) {
                        self?.screenViewModel.close(withPollId: post.poll?.id)
                    }
                    AmityAlertController.present(title: AmityLocalizedStringSet.Poll.Option.alertCloseTitle.localizedString, message: AmityLocalizedStringSet.Poll.Option.alertCloseDesc.localizedString, actions: [cancel, close], from: strongSelf)
                    
                }
                let deletePoll = TextItemOption(title: AmityLocalizedStringSet.Poll.Option.deleteTitle.localizedString) { [weak self] in
                    guard let strongSelf = self else { return }
                    let cancel = AmityAlertController.Action.cancel(style: .default, handler: nil)
                    let delete = AmityAlertController.Action.custom(title: AmityLocalizedStringSet.General.delete.localizedString, style: .destructive, handler: {
                        self?.screenViewModel.deletePost()
                        self?.navigationController?.popViewController(animated: true)
                    })
                    AmityAlertController.present(title: AmityLocalizedStringSet.Poll.Option.alertDeleteTitle.localizedString, message: AmityLocalizedStringSet.Poll.Option.alertDeleteDesc.localizedString, actions: [cancel, delete], from: strongSelf)
                }
                
                let items = (post.poll?.isClosed ?? false) ? [deletePoll] : [closePoll, deletePoll]
                contentView.configure(items: items, selectedItem: nil)
            case .file, .image, .text, .video, .unknown:
                contentView.configure(items: [editOption, deleteOption], selectedItem: nil)
            case .liveStream:
                // Currently we don't support edit live stream post.
                contentView.configure(items: [deleteOption], selectedItem: nil)
            }
            present(bottomSheet, animated: false, completion: nil)
            
        } else {
            screenViewModel.action.getPostReportStatus()
        }
        
    }
    
    private func showAlertForMaximumCharacters() {
        let title = parentComment == nil ? AmityLocalizedStringSet.postUnableToCommentTitle.localizedString : AmityLocalizedStringSet.postUnableToReplyTitle.localizedString
        let message = parentComment == nil ? AmityLocalizedStringSet.postUnableToCommentDescription.localizedString : AmityLocalizedStringSet.postUnableToReplyDescription.localizedString
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.done.localizedString, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func setupMentionManager() {
        if mentionManager != nil { return }
        let community = screenViewModel.community
        let isPublic = community?.isPublic ?? false
        let communityId: String? = isPublic ? nil : community?.communityId
        mentionManager = AmityMentionManager(withType: .comment(communityId: communityId))
        mentionManager?.delegate = self
    }
    
    private func createComment(withText text: String, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?, parentId: String?) {
        screenViewModel.action.createComment(withText: text, parentId: parentId, metadata: metadata, mentionees: mentionees)
        parentComment = nil
        commentComposeBarView.resetState()
        mentionManager?.resetState()
    }
    
    private func showReactionUserList(info: AmityReactionInfo, reactionList: [String: Int]) {
        let controller = AmityReactionPageViewController.make(info: [info], reactionList: reactionList)
        self.navigationController?.pushViewController(controller, animated: true)
    }
}

// MARK: - ReactionPickerView
extension AmityPostDetailViewController {
    
    @objc private func dismissReactionPicker(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: view)
        if !reactionPickerView.frame.contains(location) {
            hideReactionPicker()
        }
    }
    
    private func showReactionPicker() {
        UIView.animate(withDuration: 0.1) {
            self.reactionPickerView.alpha = 1 // Fade in
        }
    }
    
    private func hideReactionPicker() {
        UIView.animate(withDuration: 0.1) {
            self.reactionPickerView.alpha = 0 // Fade out
        }
    }
}

// MARK: - AmityPostTableViewDelegate
extension AmityPostDetailViewController: AmityPostTableViewDelegate {
    
    func tableView(_ tableView: AmityPostTableView, didSelectRowAt indexPath: IndexPath) {
        // load more reply did tap
        if tableView.cellForRow(at: indexPath)?.reuseIdentifier == AmityViewMoreReplyTableViewCell.identifier {
            screenViewModel.action.getReplyComments(at: indexPath.section)
        }
    }
    
    func tableView(_ tableView: AmityPostTableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 ? 0 : 1.0
    }
    
    func tableView(_ tableView: AmityPostTableView, viewForFooterInSection section: Int) -> UIView? {
        let separatorView = UIView(frame: CGRect(x: tableView.separatorInset.left, y: 0.0, width: tableView.frame.width - tableView.separatorInset.right - tableView.separatorInset.left, height: 1.0))
        separatorView.backgroundColor = AmityColorSet.secondary.blend(.shade4)
        return separatorView
    }
    
    func tableView(_ tableView: AmityPostTableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView.isBottomReached {
            screenViewModel.loadMoreComments()
        }
        
        // [Custom for ONE Krungthai][Improvement][URL Preview] Set protocol handler to willDisplay same as AmityFeedViewController
        (cell as? AmityPostHeaderProtocol)?.delegate = postHeaderProtocolHandler
        (cell as? AmityPostFooterProtocol)?.delegate = postFooterProtocolHandler
        (cell as? AmityPostProtocol)?.delegate = postProtocolHandler

    }
    
    func tableView(_ tableView: AmityPostTableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
       
        // [Custom for ONE Krungthai][Improvement][URL Preview] Change height of row to automatic dimension for url preview can show success
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: AmityPostTableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
    
    func tableViewWillBeginDragging(_ tableView: AmityPostTableView) {
        hideReactionPicker()
    }
    
}

// MARK: - AmityPostTableViewDataSource
extension AmityPostDetailViewController: AmityPostTableViewDataSource {
    
    func numberOfSections(in tableView: AmityPostTableView) -> Int {
        return screenViewModel.dataSource.numberOfSection()
    }
    
    func tableView(_ tableView: AmityPostTableView, numberOfRowsInSection section: Int) -> Int {
        return screenViewModel.dataSource.numberOfItems(tableView, in: section)
    }
    
    func tableView(_ tableView: AmityPostTableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = screenViewModel.item(at: indexPath)
        switch viewModel {
        case .post(let postComponent):
            var cell: UITableViewCell
            if let clientComponent = tableView.feedDataSource?.getUIComponentForPost(post: postComponent._composable.post, at: indexPath.section) {
                cell = clientComponent.getComponentCell(tableView, at: indexPath)
            } else {
                cell = postComponent.getComponentCell(tableView, at: indexPath)
            }
            
            return cell
        case .comment(let comment):
            
            // [Custom for ONE Krungthai][Improvement][URL Preview] Move configure cell to cellForRowAt same as AmityFeedViewController for can adjust size with url preview success
            if comment.isDeleted {
                let cell: AmityPostDetailDeletedTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.configure(deletedAt: comment.updatedAt)
                return cell
            } else {
                let cell: AmityCommentTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                let layout = AmityCommentView.Layout(
                    type: .comment,
                    isExpanded: expandedIds.contains(comment.id),
                    shouldShowActions: screenViewModel.post?.isCommentable ?? false,
                    shouldLineShow: viewModel.isReplyType
                )
                // [Custom for ONE Krungthai] Modify function for use post model for check moderator user in official community for outputing and handle after displaying URL preview
                cell.configure(with: comment, layout: layout, indexPath: indexPath, post: screenViewModel.post)
                cell.labelDelegate = self
                cell.actionDelegate = self
                
                return cell
            }
        case .replyComment(let comment):
            
            // [Custom for ONE Krungthai][Improvement][URL Preview] Move configure cell to cellForRowAt same as AmityFeedViewController for can adjust size with url preview success
            if comment.isDeleted {
                let cell: AmityDeletedReplyTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                return cell
            } else {
                let cell: AmityCommentTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                let layout = AmityCommentView.Layout(
                    type: .reply,
                    isExpanded: expandedIds.contains(comment.id),
                    shouldShowActions: screenViewModel.post?.isCommentable ?? false,
                    shouldLineShow: viewModel.isReplyType
                )
                // [Custom for ONE Krungthai] Modify function for use post model for check moderator user in official community for outputing and handle after displaying URL preview
                cell.configure(with: comment, layout: layout, indexPath: indexPath, post: screenViewModel.post)
                cell.labelDelegate = self
                cell.actionDelegate = self
                
                return cell
            }
            
        case .loadMoreReply:
            let cell: AmityViewMoreReplyTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            return cell
        }
    }   
}

extension AmityPostDetailViewController: AmityPostDetailScreenViewModelDelegate {
    
    // MARK: - Loading state
    func screenViewModel(_ viewModel: AmityPostDetailScreenViewModelType, didUpdateloadingState state: AmityLoadingState) {
        switch state {
        case .loading:
            tableView.showLoadingIndicator()
        case .loaded:
            tableView.tableFooterView = nil
        case .initial:
            break
        }
    }
    
    // MARK: - Post
    func screenViewModelDidUpdateData(_ viewModel: AmityPostDetailScreenViewModelType) {
        tableView.reloadData()
        if let post = screenViewModel.post {
            /* [Improvement] Move add option button of navigation bar to get post success data because of click post notification */
            setupNavigationBar()
            commentComposeBarView.configure(with: post)
        }
        
        setupMentionManager()
    }
    
    func screenViewModelDidUpdatePost(_ viewModel: AmityPostDetailScreenViewModelType) {
        // Do something with success
    }
    
    func screenViewModelDidLikePost(_ viewModel: AmityPostDetailScreenViewModelType) {
        tableView.feedDelegate?.didPerformActionLikePost()
    }
    
    func screenViewModelDidUnLikePost(_ viewModel: AmityPostDetailScreenViewModelType) {
        tableView.feedDelegate?.didPerformActionUnLikePost()
    }
    
    func screenViewModel(_ viewModel: AmityPostDetailScreenViewModelType, didReceiveReportStatus isReported: Bool) {
        let bottomSheet = BottomSheetViewController()
        let contentView = ItemOptionView<TextItemOption>()
        bottomSheet.isTitleHidden = true
        bottomSheet.sheetContentView = contentView
        bottomSheet.modalPresentationStyle = .overFullScreen
        
        if isReported {
            let unreportOption = TextItemOption(title: AmityLocalizedStringSet.General.undoReport.localizedString) { [weak self] in
                self?.screenViewModel.action.unreportPost()
            }
            contentView.configure(items: [unreportOption], selectedItem: nil)
        } else {
            let reportOption = TextItemOption(title: AmityLocalizedStringSet.General.report.localizedString) { [weak self] in
                self?.screenViewModel.action.reportPost()
            }
            contentView.configure(items: [reportOption], selectedItem: nil)
        }
        present(bottomSheet, animated: false, completion: nil)
    }
    
    // MARK: - Comment
    func screenViewModelDidCreateComment(_ viewModel: AmityPostDetailScreenViewModelType, comment: AmityCommentModel) {
        
        if comment.parentId == nil {
            // When new parent comment is created, it will not show in query stream.
            // We forcibly fetch a comment list to include new added comments.
            screenViewModel.action.fetchComments()
        }
    }
    
    func screenViewModelDidDeleteComment(_ viewModel: AmityPostDetailScreenViewModelType) {
        // Do something with success
    }
    func screenViewModelDidEditComment(_ viewModel: AmityPostDetailScreenViewModelType) {
        // Do something with success
    }
    
    func screenViewModelDidLikeComment(_ viewModel: AmityPostDetailScreenViewModelType) {
        tableView.feedDelegate?.didPerformActionLikeComment()
    }
    
    func screenViewModelDidUnLikeComment(_ viewModel: AmityPostDetailScreenViewModelType) {
        tableView.feedDelegate?.didPerformActionUnLikeComment()
    }
    
    func screenViewModel(_ viewModel: AmityPostDetailScreenViewModelType, didFinishWithMessage message: String) {
        AmityHUD.show(.success(message: message.localizedString))
    }
    
    func screenViewModel(_ viewModel: AmityPostDetailScreenViewModelType, comment: AmityCommentModel, didReceiveCommentReportStatus isReported: Bool) {
        let bottomSheet = BottomSheetViewController()
        let contentView = ItemOptionView<TextItemOption>()
        bottomSheet.sheetContentView = contentView
        bottomSheet.isTitleHidden = true
        bottomSheet.modalPresentationStyle = .overFullScreen
        
        if isReported {
            let unreportOption = TextItemOption(title: AmityLocalizedStringSet.General.undoReport.localizedString) {
                self.screenViewModel.action.unreportComment(withCommentId: comment.id)
            }
            contentView.configure(items: [unreportOption], selectedItem: nil)
        } else {
            let reportOption = TextItemOption(title: AmityLocalizedStringSet.General.report.localizedString) {
                self.screenViewModel.action.reportComment(withCommentId: comment.id)
            }
            contentView.configure(items: [reportOption], selectedItem: nil)
        }
        present(bottomSheet, animated: false, completion: nil)
    }
    
    func screenViewModel(_ viewModel: AmityPostDetailScreenViewModelType, didFinishWithError error: AmityError) {
        switch error {
        case .unknown:
//            AmityHUD.show(.error(message: AmityLocalizedStringSet.HUD.somethingWentWrong.localizedString)) // [Back up]
            if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
                ToastView.shared.showToast(message: AmityLocalizedStringSet.HUD.somethingWentWrong.localizedString, in: window)
            }
        case .bannedWord:
//            AmityHUD.show(.error(message: AmityLocalizedStringSet.PostDetail.banndedCommentErrorMessage.localizedString)) // [Back up]
            if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
                ToastView.shared.showToast(message: AmityLocalizedStringSet.PostDetail.banndedCommentErrorMessage.localizedString, in: window)
            }
        case .linkNotAllowed:
//            AmityHUD.show(.error(message: AmityLocalizedStringSet.PostDetail.linkNotAllowedErrorMessage.localizedString)) // [Back up]
            if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
                ToastView.shared.showToast(message: AmityLocalizedStringSet.PostDetail.linkNotAllowedErrorMessage.localizedString, in: window)
            }
        default:
            break
        }
    }
    
}

// MARK: - AmityPostHeaderProtocolHandlerDelegate
extension AmityPostDetailViewController: AmityPostHeaderProtocolHandlerDelegate {
    
    func headerProtocolHandlerDidPerformAction(_ handler: AmityPostHeaderProtocolHandler, action: AmityPostProtocolHeaderHandlerAction, withPost post: AmityPostModel) {
        switch action {
        case .tapOption:
            screenViewModel.action.getPostReportStatus()
        case .tapDelete:
            screenViewModel.action.deletePost()
        case .tapReport:
            screenViewModel.action.reportPost()
        case .tapUnreport:
            screenViewModel.action.reportPost()
        case .tapClosePoll:
            screenViewModel.action.close(withPollId: post.poll?.id)
        case .TapPinpost:
            if post.isPinPost {
//                screenViewModel.action.unpinpost(withpostId: postId)
            } else {
//                screenViewModel.action.pinpost(withpostId: postId)
            }
        }
    }
    
}

// MARK: - AmityPostProtocolHandlerDelegate
extension AmityPostDetailViewController: AmityPostProtocolHandlerDelegate {
    func amityPostProtocolHandlerDidTapPollAnswers(_ cell: AmityPostProtocol, postId: String, pollAnswers: [String : [String]]) {
        self.pollAnswers = pollAnswers
    }
    
    func amityPostProtocolHandlerDidTapSubmit(_ cell: AmityPostProtocol) {
        if let cell = cell as? AmityPostPollTableViewCell {
            screenViewModel.action.vote(withPollId: cell.post?.poll?.id, answerIds: cell.selectedAnswerIds)
        }
    }
}


// MARK: - AmityPostFooterProtocolHandlerDelegate
extension AmityPostDetailViewController: AmityPostFooterProtocolHandlerDelegate {
    func footerProtocolHandlerDidPerformView(_ handler: AmityPostFooterProtocolHandler, view: UIView) {
        let likeButtonFrameInSuperview = view.convert(view.bounds, to: self.view)
        reactionPickerView.frame.origin = CGPoint(x: 16, y: likeButtonFrameInSuperview.maxY - likeButtonFrameInSuperview.height - self.reactionPickerView.frame.height)
    }
    
    func footerProtocolHandlerDidPerformAction(_ handler: AmityPostFooterProtocolHandler, action: AmityPostFooterProtocolHandlerAction, withPost post: AmityPostModel) {
        switch action {
        case .tapLike:
            if let reactionType = post.reacted {
                screenViewModel.action.removeReactionPost(type: reactionType)
            } else {
                screenViewModel.action.addReactionPost(type: .create)
            }
        case .tapComment:
            parentComment = nil
            if post.isGroupMember {
                _ = commentComposeBarView.becomeFirstResponder()
            }
        case .tapReactionDetails:
            let info = AmityReactionInfo(referenceId: post.postId, referenceType: .post, reactionsCount: post.reactionsCount)
            let reactionList = screenViewModel.dataSource.getReactionList()
            
            self.showReactionUserList(info: info, reactionList: reactionList)
        case .tapHoldLike:
            reactionPickerView.onSelect = { [weak self] reactionType in
                self?.hideReactionPicker()
                if let reacted = post.reacted, reactionType == reacted {
                    return
                } else {
                    if let reacted = post.reacted, !reacted.rawValue.isEmpty {
                        self?.screenViewModel.action.removeHoldReactionPost(type: reacted, typeSelect: reactionType)
                    } else {
                        self?.screenViewModel.action.addReactionPost(type: reactionType)
                    }
                }
            }
            showReactionPicker()
        }
    }
    
}

// MARK: - AmityPostDetailCompostViewDelegate
extension AmityPostDetailViewController: AmityPostDetailCompostViewDelegate {
    
    func composeViewDidTapReplyDismiss(_ view: AmityPostDetailCompostView) {
        parentComment = nil
    }
    
    func composeViewDidTapExpand(_ view: AmityPostDetailCompostView) {
        var editTextViewController: AmityEditTextViewController
        let communityId = (screenViewModel.dataSource.community?.isPublic ?? false) ? nil : screenViewModel.dataSource.community?.communityId
        if let parentComment = parentComment {
            // create reply
            let header = String.localizedStringWithFormat(AmityLocalizedStringSet.PostDetail.replyingTo.localizedString, parentComment.displayName)
            editTextViewController = AmityEditTextViewController.make(headerTitle: header, text: commentComposeBarView.text, editMode: .create(communityId: communityId, isReply: true))
            editTextViewController.title = AmityLocalizedStringSet.PostDetail.createReply.localizedString
        } else {
            // create comment
            editTextViewController = AmityEditTextViewController.make(text: commentComposeBarView.text, editMode: .create(communityId: communityId, isReply: false))
            editTextViewController.title = AmityLocalizedStringSet.PostDetail.createComment.localizedString
        }
        editTextViewController.editHandler = { [weak self, weak editTextViewController] text, metadata, mentionees in
            self?.createComment(withText: text, metadata: metadata, mentionees: mentionees, parentId: self?.parentComment?.id)
            editTextViewController?.dismiss(animated: true, completion: nil)
        }
        editTextViewController.dismissHandler = { [weak self, weak editTextViewController] in
            let alertTitle = (self?.parentComment == nil) ? AmityLocalizedStringSet.PostDetail.discardCommentTitle.localizedString : AmityLocalizedStringSet.PostDetail.discardReplyTitle.localizedString
            let alertMessage = (self?.parentComment == nil) ? AmityLocalizedStringSet.PostDetail.discardCommentMessage.localizedString : AmityLocalizedStringSet.PostDetail.discardReplyMessage.localizedString
            let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel, handler: nil)
            let discardAction = UIAlertAction(title: AmityLocalizedStringSet.General.discard.localizedString, style: .destructive) { _ in
                editTextViewController?.dismiss(animated: true, completion: nil)
            }
            alertController.addAction(cancelAction)
            alertController.addAction(discardAction)
            editTextViewController?.present(alertController, animated: true, completion: nil)
        }
        let navigationController = UINavigationController(rootViewController: editTextViewController)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true, completion: nil)
    }
    
    func composeView(_ view: AmityPostDetailCompostView, didPostText text: String) {
        let metadata = mentionManager?.getMetadata()
        let mentionees = mentionManager?.getMentionees()
        createComment(withText: text, metadata: metadata, mentionees: mentionees, parentId: parentComment?.id)
    }
    
    func composeViewDidChangeSelection(_ view: AmityPostDetailCompostView) {
        mentionManager?.changeSelection(view.textView)
    }
    
    func composeView(_ view: AmityPostDetailCompostView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if view.textView.text.count > AmityMentionManager.maximumCharacterCountForPost {
            showAlertForMaximumCharacters()
            return false
        }
        return mentionManager?.shouldChangeTextIn(view.textView, inRange: range, replacementText: text, currentText: view.textView.text) ?? true
    }
}

// MARK: - AmityKeyboardServiceDelegate
extension AmityPostDetailViewController: AmityKeyboardServiceDelegate {
    
    func keyboardWillChange(service: AmityKeyboardService, height: CGFloat, animationDuration: TimeInterval) {
        let offset = height > 0 ? view.safeAreaInsets.bottom : 0
        commentComposeBarBottomConstraint.constant = -height + offset
        view.setNeedsUpdateConstraints()
        view.layoutIfNeeded()
    }
    
}

extension AmityPostDetailViewController: AmityExpandableLabelDelegate {
    
    public func didTapOnHashtag(_ label: AmityExpandableLabel, withKeyword keyword: String, count: Int) {
        AmityEventHandler.shared.hashtagDidTap(from: self, keyword: keyword, count: count)
    }
    
    public func expandableLabeldidTap(_ label: AmityExpandableLabel) {
        // Intentionally left empty
    }
    
    public func willExpandLabel(_ label: AmityExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) as IndexPath? {
            switch screenViewModel.dataSource.item(at: indexPath) {
            case .comment(let comment), .replyComment(let comment):
                expandedIds.insert(comment.id)
            default:
                break
            }
            let delayToScroll: DispatchTime = .now() + .milliseconds(300)
            DispatchQueue.main.asyncAfter(deadline: delayToScroll) { [weak self] in
                self?.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
            
        }
        tableView.beginUpdates()
    }
    
    public func didExpandLabel(_ label: AmityExpandableLabel) {
        tableView.endUpdates()
    }
    
    public func willCollapseLabel(_ label: AmityExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) as IndexPath? {
            switch screenViewModel.dataSource.item(at: indexPath) {
            case .comment(let comment), .replyComment(let comment):
                expandedIds.remove(comment.id)
            default:
                break
            }
            let delayToScroll: DispatchTime = .now() + .milliseconds(300)
            DispatchQueue.main.asyncAfter(deadline: delayToScroll) { [weak self] in
                self?.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        }
        tableView.beginUpdates()
    }
    
    public func didCollapseLabel(_ label: AmityExpandableLabel) {
        tableView.endUpdates()
    }
    
    public func didTapOnMention(_ label: AmityExpandableLabel, withUserId userId: String) {
        AmityEventHandler.shared.userDidTap(from: self, userId: userId)
    }
}

extension AmityPostDetailViewController: AmityCommentTableViewCellDelegate {    
    func commentCellDidTapAvatar(_ cell: AmityCommentTableViewCell, userId: String, communityId: String?) {
        // [Custom for ONE Krungthai] Add check condition for tap to community for moderator user in official community action
        if let currentCommunityId = communityId {
            AmityEventHandler.shared.communityDidTap(from: self, communityId: currentCommunityId)
        } else {
            AmityEventHandler.shared.userDidTap(from: self, userId: userId)
        }
    }
    
    func commentCellDidTapReadMore(_ cell: AmityCommentTableViewCell) {
        //
    }
    
    func commentCellDidTapLike(_ cell: AmityCommentTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        switch screenViewModel.item(at: indexPath) {
        case .comment(let comment), .replyComment(let comment):
            if comment.isLiked {
                screenViewModel.action.unlikeComment(withCommendId: comment.id)
            } else {
                screenViewModel.action.likeComment(withCommendId: comment.id)
            }
        case .post, .loadMoreReply:
            break
        }
    }
    
    func commentCellDidTapReply(_ cell: AmityCommentTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell),
            case .comment(let comment) = screenViewModel.item(at: indexPath) else { return }
        parentComment = comment
        _ = commentComposeBarView.becomeFirstResponder()
    }
    
    func commentCellDidTapOption(_ cell: AmityCommentTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        switch screenViewModel.item(at: indexPath) {
        case .comment(let comment), .replyComment(let comment):
            presentOptionBottomSheet(comment: comment)
        case .post, .loadMoreReply:
            break
        }
    }
    
    func commentCellDidTapReactionDetails(_ cell: AmityCommentTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        switch screenViewModel.item(at: indexPath) {
        case .comment(let comment), .replyComment(let comment):
            let info = AmityReactionInfo(referenceId: comment.id, referenceType: .comment, reactionsCount: comment.reactionsCount)
            let reactionList = screenViewModel.dataSource.getReactionList()
            
            self.showReactionUserList(info: info, reactionList: [:])
        case .post, .loadMoreReply:
            break
        }
    }
    
    private func presentOptionBottomSheet(comment: AmityCommentModel) {
        let communityId = (screenViewModel.dataSource.community?.isPublic ?? false) ? nil : screenViewModel.dataSource.community?.communityId
        // Comment options
        if comment.isOwner {
            let bottomSheet = BottomSheetViewController()
            let contentView = ItemOptionView<TextItemOption>()
            bottomSheet.sheetContentView = contentView
            bottomSheet.isTitleHidden = true
            bottomSheet.modalPresentationStyle = .overFullScreen
            
            let editOptionTitle = comment.isParent ? AmityLocalizedStringSet.PostDetail.editComment.localizedString : AmityLocalizedStringSet.PostDetail.editReply.localizedString
            let deleteOptionTitle = comment.isParent ? AmityLocalizedStringSet.PostDetail.deleteComment.localizedString : AmityLocalizedStringSet.PostDetail.deleteReply.localizedString
            
            let editOption = TextItemOption(title: editOptionTitle) { [weak self] in
                guard let strongSelf = self else { return }
                let editTextViewController = AmityCommentEditorViewController.make(comment: comment, communityId: communityId)
                editTextViewController.title = comment.isParent ? AmityLocalizedStringSet.PostDetail.editComment.localizedString : AmityLocalizedStringSet.PostDetail.editReply.localizedString
                editTextViewController.editHandler = { [weak self] text, metadata, mentionees in
                    self?.screenViewModel.action.editComment(with: comment, text: text, metadata: metadata, mentionees: mentionees)
                    editTextViewController.dismiss(animated: true, completion: nil)
                }
                editTextViewController.dismissHandler = { [weak editTextViewController] in
                    let alertTitle = comment.isParent ? AmityLocalizedStringSet.PostDetail.discardCommentTitle.localizedString : AmityLocalizedStringSet.PostDetail.discardReplyTitle.localizedString
                    let alertMessage = comment.isParent ? AmityLocalizedStringSet.PostDetail.discardEditedCommentMessage.localizedString : AmityLocalizedStringSet.PostDetail.discardEditedReplyMessage.localizedString
                    let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel, handler: nil)
                    let discardAction = UIAlertAction(title: AmityLocalizedStringSet.General.discard.localizedString, style: .destructive) { _ in
                        editTextViewController?.dismiss(animated: true, completion: nil)
                    }
                    alertController.addAction(cancelAction)
                    alertController.addAction(discardAction)
                    editTextViewController?.present(alertController, animated: true, completion: nil)
                }
                let nvc = UINavigationController(rootViewController: editTextViewController)
                nvc.modalPresentationStyle = .fullScreen
                strongSelf.present(nvc, animated: true, completion: nil)
            }
            let deleteOption = TextItemOption(title: deleteOptionTitle) { [weak self] in
                let alertTitle = comment.isParent ? AmityLocalizedStringSet.PostDetail.deleteCommentTitle.localizedString : AmityLocalizedStringSet.PostDetail.deleteReplyTitle.localizedString
                let alertMessage = comment.isParent ? AmityLocalizedStringSet.PostDetail.deleteCommentMessage.localizedString : AmityLocalizedStringSet.PostDetail.deleteReplyMessage.localizedString
                let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: AmityLocalizedStringSet.General.delete.localizedString, style: .destructive) { [weak self] _ in
                    self?.screenViewModel.action.deleteComment(with: comment)
                })
                self?.present(alert, animated: true, completion: nil)
            }
            
            contentView.configure(items: [editOption, deleteOption], selectedItem: nil)
            present(bottomSheet, animated: false, completion: nil)
        } else {
            // get report status for comment and then trigger didReceiveCommentReportStatus on delegate
            screenViewModel.action.getCommentReportStatus(with: comment)
        }
    }
}

// MARK: - UITableViewDataSource
extension AmityPostDetailViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag != 1 {
            return mentionManager?.users.count ?? 0
        } else {
            return mentionManager?.keywords.count ?? 0
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag != 1 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: AmityMentionTableViewCell.identifier) as? AmityMentionTableViewCell, let model = mentionManager?.item(at: indexPath) else { return UITableViewCell() }
            cell.display(with: model)
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: AmityHashtagTableViewCell.identifier) as? AmityHashtagTableViewCell, let model = mentionManager?.itemHashtag(at: indexPath) else { return UITableViewCell() }
            cell.display(with: model)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension AmityPostDetailViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView.tag != 1 {
            return AmityMentionTableViewCell.height
        } else {
            return AmityHashtagTableViewCell.height
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.tag != 1 {
            mentionManager?.addMention(from: commentComposeBarView.textView, in: commentComposeBarView.textView.text, at: indexPath)
        } else {
            mentionManager?.addHashtag(from: commentComposeBarView.textView, in: commentComposeBarView.textView.text, at: indexPath)
        }
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView.tag != 1 {
            if indexPath.row == (mentionManager?.users.count ?? 0) - 4 {
                mentionManager?.loadMore()
            }
        } else {
            if indexPath.row == (mentionManager?.users.count ?? 0) - 4 {
                mentionManager?.loadMoreHashtag()
            }
        }
    }
}

// MARK: - AmityMentionManagerDelegate
extension AmityPostDetailViewController: AmityMentionManagerDelegate {
    public func didRemoveAttributedString() {
        commentComposeBarView.textView.typingAttributes = [.font: AmityFontSet.body, .foregroundColor: AmityColorSet.base]
    }
    
    public func didGetHashtag(keywords: [AmityHashtagModel]) {
        if keywords.isEmpty {
            hashtagTableViewHeightConstraint.constant = 0
            hashtagTableView.isHidden = true
        } else {
            var heightConstant:CGFloat = 240.0
            if keywords.count < 5 {
                heightConstant = CGFloat(keywords.count) * 52.0
            }
            hashtagTableViewHeightConstraint.constant = heightConstant
            hashtagTableView.isHidden = false
            hashtagTableView.reloadData()
        }
    }
    
    public func didCreateAttributedString(attributedString: NSAttributedString) {
        commentComposeBarView.textView.attributedText = attributedString
        commentComposeBarView.textView.typingAttributes = [.font: AmityFontSet.body, .foregroundColor: AmityColorSet.base]
    }
    
    public func didGetUsers(users: [AmityMentionUserModel]) {
        if users.isEmpty {
            mentionTableViewHeightConstraint.constant = 0
            mentionTableView.isHidden = true
        } else {
            var heightConstant:CGFloat = 200.0
            mentionTableViewHeightConstraint.constant = heightConstant
            mentionTableView.isHidden = false
            mentionTableView.reloadData()
        }
    }
    
    public func didMentionsReachToMaximumLimit() {
        let message = parentComment == nil ? AmityLocalizedStringSet.Mention.unableToMentionCommentDescription.localizedString : AmityLocalizedStringSet.Mention.unableToMentionReplyDescription.localizedString
        let alertController = UIAlertController(title: AmityLocalizedStringSet.Mention.unableToMentionTitle.localizedString, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.done.localizedString, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    public func didCharactersReachToMaximumLimit() {
        showAlertForMaximumCharacters()
    }
}
