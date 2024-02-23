//
//  OneKTBActivityDetailViewController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 22/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

public protocol OneKTBActivityDetailViewControllerDelegate: AnyObject {
    func childViewController(_ childViewController: OneKTBActivityDetailViewController, didUpdateContentHeight height: CGFloat)
}

open class OneKTBActivityDetailViewController: AmityViewController {
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var tableView: AmityPostTableView!
    @IBOutlet private var commentComposeBarView: AmityPostDetailCompostView!
    @IBOutlet private var commentComposeBarBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var mentionTableView: AmityMentionTableView!
    @IBOutlet private var mentionTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var hashtagTableView: AmityHashtagTableView!
    @IBOutlet private var hashtagTableViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Post Protocol Handler
    private var postFooterProtocolHandler: AmityPostFooterProtocolHandler?
    private var postProtocolHandler: AmityPostProtocolHandler?
    
    // MARK: - Properties
    private var screenViewModel: OneKTBActivityDetailScreenViewModelType
    private var selectedIndexPath: IndexPath?
    private var referenceId: String?
    private var expandedIds: Set<String> = []
    private var showReplyIds: [String] = []
    private var mentionManager: AmityMentionManager?
    
    private var postId: String?
    private var isComment: Bool

    private var parentComment: AmityCommentModel? {
        didSet {
            commentComposeBarView.replyingUsername = parentComment?.displayName
        }
    }
    
    // Reaction Picker
    private let reactionPickerView = AmityReactionPickerView()
    
    public weak var delegate: OneKTBActivityDetailViewControllerDelegate?
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    
    // MARK: - Initializer
    required public init(withPostId postId: String, withIsComment isComment: Bool) {
        self.isComment = isComment
        self.postId = postId
        let postController = AmityPostController()
        let commentController = AmityCommentController()
        let reactionController = AmityReactionController()
        let childrenController = AmityCommentChildrenController(postId: postId)
        screenViewModel = OneKTBActivityDetailScreenViewModel(withPostId: postId,
                                                              postController: postController,
                                                              commentController: commentController,
                                                              reactionController: reactionController,
                                                              childrenController: childrenController,
                                                              withIsComment: isComment)
        super.init(nibName: OneKTBActivityDetailViewController.identifier, bundle: AmityUIKitManager.bundle)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // Remove observer when the view controller is deallocated
        tableView.removeObserver(self, forKeyPath: "contentSize")
    }
    
    public class func make(withPostId postId: String, withIsComment isComment: Bool) -> Self {
        return self.init(withPostId: postId, withIsComment: isComment)
    }
    
    // Observe content size changes and update the height constraint
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                    change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize", object as? UITableView == tableView {
            updateContentHeight()
        }
    }
    
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
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
        screenViewModel.action.fetchReactionList()
    }
    
    // MARK: Setup views
    private func setupView() {
        view.backgroundColor = AmityColorSet.backgroundColor
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
        
        // Observe content size changes of the table view
        tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
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
        
        if !isComment {
            NSLayoutConstraint.activate([
                commentComposeBarView.heightAnchor.constraint(equalToConstant: 0),
            ])
        }
    }
    
    private func setupReactionPicker() {
        
        reactionPickerView.alpha = 0
        view.addSubview(reactionPickerView)
        
        // Setup tap gesture recognizer
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissReactionPicker))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
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
        controller.modalPresentationStyle = .popover
        present(controller, animated: true, completion: nil)
    }
    
    private func updateContentHeight() {
        let screenHeight = UIScreen.main.bounds.height
        let contentHeight = tableView.contentSize.height
        let maxHeight = screenHeight // Custom offset if needed
        
        if contentHeight > maxHeight {
            delegate?.childViewController(self, didUpdateContentHeight: maxHeight)
        } else {
            delegate?.childViewController(self, didUpdateContentHeight: contentHeight + 50)
        }
    }
    
    private func openCommentView() {
        let amityCommentVC = OneKTBActivityDetailViewController.make(withPostId: postId ?? "", withIsComment: true)
        amityCommentVC.modalPresentationStyle = .popover
        present(amityCommentVC, animated: true, completion: nil)
    }
}

// MARK: - ReactionPickerView
extension OneKTBActivityDetailViewController {
    
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
    
    public func hideReactionPicker() {
        UIView.animate(withDuration: 0.1) {
            self.reactionPickerView.alpha = 0 // Fade out
        }
    }
}

// MARK: - AmityPostTableViewDelegate
extension OneKTBActivityDetailViewController: AmityPostTableViewDelegate {
    
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
        
        let viewModel = screenViewModel.item(at: indexPath)
        switch viewModel {
        case .post(let postComponent):
            (cell as? AmityPostFooterProtocol)?.delegate = postFooterProtocolHandler
            (cell as? AmityPostProtocol)?.delegate = postProtocolHandler
        case .comment(let comment):
            if comment.isDeleted {
                let _cell = cell as! AmityPostDetailDeletedTableViewCell
                _cell.configure(deletedAt: comment.updatedAt)
            } else {
                let _cell = cell as! AmityCommentTableViewCell
                let layout = AmityCommentView.Layout(
                    type: .comment,
                    isExpanded: expandedIds.contains(comment.id),
                    shouldShowActions: screenViewModel.post?.isCommentable ?? false,
                    shouldLineShow: viewModel.isReplyType
                )
                _cell.configure(with: comment, layout: layout, indexPath: indexPath)
                _cell.labelDelegate = self
                _cell.actionDelegate = self
            }
            
        case .replyComment(let comment):
            if comment.isDeleted {
                return
            }
            let _cell = cell as! AmityCommentTableViewCell
            let layout = AmityCommentView.Layout(
                type: .reply,
                isExpanded: expandedIds.contains(comment.id),
                shouldShowActions: screenViewModel.post?.isCommentable ?? false,
                shouldLineShow: viewModel.isReplyType
            )
            _cell.configure(with: comment, layout: layout, indexPath: indexPath)
            _cell.labelDelegate = self
            _cell.actionDelegate = self
            
        case .loadMoreReply:
            break
        }
        
    }
    
    func tableView(_ tableView: AmityPostTableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let viewModel = screenViewModel.item(at: indexPath)
        switch viewModel {
        case .post, .loadMoreReply:
            return UITableView.automaticDimension
        case .comment(let comment):
            if comment.isDeleted {
                return AmityPostDetailDeletedTableViewCell.height
            }
            // Although AmityCommentTableViewCell is a self-sizing cell.
            // Due to the layout glitch, we need to calculate cell height manually here.
            let layout = AmityCommentView.Layout(
                type: .comment,
                isExpanded: expandedIds.contains(comment.id),
                shouldShowActions: screenViewModel.post?.isCommentable ?? false,
                shouldLineShow: viewModel.isReplyType
            )
            return AmityCommentTableViewCell.height(with: comment, layout: layout, boundingWidth: tableView.bounds.width)
        case .replyComment(let comment):
            if comment.isDeleted {
                return AmityPostDetailDeletedTableViewCell.height
            }
            // Although AmityCommentTableViewCell is a self-sizing cell.
            // Due to the layout glitch, we need to calculate cell height manually here.
            let layout = AmityCommentView.Layout(
                type: .reply,
                isExpanded: expandedIds.contains(comment.id),
                shouldShowActions: screenViewModel.post?.isCommentable ?? false,
                shouldLineShow: viewModel.isReplyType
            )
            return AmityCommentTableViewCell.height(with: comment, layout: layout, boundingWidth: tableView.bounds.width)
        }
    }
    
    func tableView(_ tableView: AmityPostTableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
    
    func tableViewWillBeginDragging(_ tableView: AmityPostTableView) {
        hideReactionPicker()
    }
    
}

// MARK: - AmityPostTableViewDataSource
extension OneKTBActivityDetailViewController: AmityPostTableViewDataSource {
    
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
            if comment.isDeleted {
                let cell: AmityPostDetailDeletedTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                return cell
            }
            
            let cell: AmityCommentTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            return cell
        case .replyComment(let comment):
            if comment.isDeleted {
                let cell: AmityDeletedReplyTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                return cell
            }
            let cell: AmityCommentTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            return cell
        case .loadMoreReply:
            let cell: AmityViewMoreReplyTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            return cell
        }
    }
}

extension OneKTBActivityDetailViewController: OneKTBActivityDetailScreenViewModelDelegate {
    
    // MARK: - Loading state
    func screenViewModel(_ viewModel: OneKTBActivityDetailScreenViewModelType, didUpdateloadingState state: AmityLoadingState) {
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
    func screenViewModelDidUpdateData(_ viewModel: OneKTBActivityDetailScreenViewModelType) {
        tableView.reloadData()
        if let post = screenViewModel.post {
            if isComment {
                commentComposeBarView.configure(with: post)
            }
        }
        
        setupMentionManager()
        updateContentHeight()
    }
    
    func screenViewModelDidUpdatePost(_ viewModel: OneKTBActivityDetailScreenViewModelType) {
        // Do something with success
    }
    
    func screenViewModelDidLikePost(_ viewModel: OneKTBActivityDetailScreenViewModelType) {
        tableView.feedDelegate?.didPerformActionLikePost()
    }
    
    func screenViewModelDidUnLikePost(_ viewModel: OneKTBActivityDetailScreenViewModelType) {
        tableView.feedDelegate?.didPerformActionUnLikePost()
    }
    
    func screenViewModel(_ viewModel: OneKTBActivityDetailScreenViewModelType, didReceiveReportStatus isReported: Bool) {
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
    func screenViewModelDidCreateComment(_ viewModel: OneKTBActivityDetailScreenViewModelType, comment: AmityCommentModel) {
        
        if comment.parentId == nil {
            // When new parent comment is created, it will not show in query stream.
            // We forcibly fetch a comment list to include new added comments.
            screenViewModel.action.fetchComments()
        }
    }
    
    func screenViewModelDidDeleteComment(_ viewModel: OneKTBActivityDetailScreenViewModelType) {
        // Do something with success
    }
    func screenViewModelDidEditComment(_ viewModel: OneKTBActivityDetailScreenViewModelType) {
        // Do something with success
    }
    
    func screenViewModelDidLikeComment(_ viewModel: OneKTBActivityDetailScreenViewModelType) {
        tableView.feedDelegate?.didPerformActionLikeComment()
    }
    
    func screenViewModelDidUnLikeComment(_ viewModel: OneKTBActivityDetailScreenViewModelType) {
        tableView.feedDelegate?.didPerformActionUnLikeComment()
    }
    
    func screenViewModel(_ viewModel: OneKTBActivityDetailScreenViewModelType, didFinishWithMessage message: String) {
        AmityHUD.show(.success(message: message.localizedString))
    }
    
    func screenViewModel(_ viewModel: OneKTBActivityDetailScreenViewModelType, comment: AmityCommentModel, didReceiveCommentReportStatus isReported: Bool) {
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
    
    func screenViewModel(_ viewModel: OneKTBActivityDetailScreenViewModelType, didFinishWithError error: AmityError) {
        switch error {
        case .unknown:
            AmityHUD.show(.error(message: AmityLocalizedStringSet.HUD.somethingWentWrong.localizedString))
        case .bannedWord:
            AmityHUD.show(.error(message: AmityLocalizedStringSet.PostDetail.banndedCommentErrorMessage.localizedString))
        default:
            break
        }
    }
    
}

// MARK: - AmityPostProtocolHandlerDelegate
extension OneKTBActivityDetailViewController: AmityPostProtocolHandlerDelegate {
    func amityPostProtocolHandlerDidTapPollAnswers(_ cell: AmityPostProtocol, postId: String, pollAnswers: [String : [String]]) {
    }
    
    func amityPostProtocolHandlerDidTapSubmit(_ cell: AmityPostProtocol) {
        if let cell = cell as? AmityPostPollTableViewCell {
            screenViewModel.action.vote(withPollId: cell.post?.poll?.id, answerIds: cell.selectedAnswerIds)
        }
    }
}


// MARK: - AmityPostFooterProtocolHandlerDelegate
extension OneKTBActivityDetailViewController: AmityPostFooterProtocolHandlerDelegate {
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
            if isComment {
                parentComment = nil
                if post.isGroupMember {
                    _ = commentComposeBarView.becomeFirstResponder()
                }
            } else {
                openCommentView()
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
        case .tapShare:
            // ktb kk v1.21.0 re menu share
            AmityFeedEventHandler.shared.sharePostDidTap(from: self, post: post)
            /*
            let bottomSheet = BottomSheetViewController()
            let contentView = ItemOptionView<TextItemOption>()
            bottomSheet.sheetContentView = contentView
            bottomSheet.isTitleHidden = true
            bottomSheet.modalPresentationStyle = .overFullScreen
            var options: [TextItemOption] = []
            
            let shareOption = TextItemOption(title: "Share to Chat") {
                AmityChannelEventHandler.shared.channelOpenChannelListForForwardMessage(from: self) { selectedChannels in
                    print(selectedChannels)
                    self.screenViewModel.action.checkChannelId(withSelectChannel: selectedChannels, post: post)
                }
            }
            options.append(shareOption)
            
            // ktb kk custom qr menu
            let qrOption = TextItemOption(title: "Share content via QR code") {
                AmityFeedEventHandler.shared.sharePostDidTap(from: self, post: post)
            }
            options.append(qrOption)
            
            contentView.configure(items: options, selectedItem: nil)
            present(bottomSheet, animated: false, completion: nil)
             */
        }
    }
    
}

// MARK: - AmityPostDetailCompostViewDelegate
extension OneKTBActivityDetailViewController: AmityPostDetailCompostViewDelegate {
    
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
extension OneKTBActivityDetailViewController: AmityKeyboardServiceDelegate {
    
    func keyboardWillChange(service: AmityKeyboardService, height: CGFloat, animationDuration: TimeInterval) {
        let offset = height > 0 ? view.safeAreaInsets.bottom : 0
        commentComposeBarBottomConstraint.constant = -height + offset
        view.setNeedsUpdateConstraints()
        view.layoutIfNeeded()
    }
    
}

extension OneKTBActivityDetailViewController: AmityExpandableLabelDelegate {
    public func didTapOnPostIdLink(_ label: AmityExpandableLabel, withPostId postId: String) {
        AmityEventHandler.shared.postDidtap(from: self, postId: postId)
    }
    
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
        AmityEventHandler.shared.userKTBDidTap(from: self, userId: userId)
    }
}

extension OneKTBActivityDetailViewController: AmityCommentTableViewCellDelegate {
    func commentCellDidTapAvatar(_ cell: AmityCommentTableViewCell, userId: String, communityId: String?) {
        AmityEventHandler.shared.userKTBDidTap(from: self, userId: userId)
    }
    
    func commentCellDidTapReadMore(_ cell: AmityCommentTableViewCell) {
        //
    }
    
    func commentCellDidTapLike(_ cell: AmityCommentTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        switch screenViewModel.item(at: indexPath) {
        case .comment(let comment), .replyComment(let comment):
            if isComment {
                if comment.isLiked {
                    screenViewModel.action.unlikeComment(withCommendId: comment.id)
                } else {
                    screenViewModel.action.likeComment(withCommendId: comment.id)
                }
            } else {
                openCommentView()
            }
        case .post, .loadMoreReply:
            break
        }
    }
    
    func commentCellDidTapReply(_ cell: AmityCommentTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell),
            case .comment(let comment) = screenViewModel.item(at: indexPath) else { return }
        parentComment = comment
        if isComment {
            _ = commentComposeBarView.becomeFirstResponder()
        } else {
            openCommentView()
        }
    }
    
    func commentCellDidTapOption(_ cell: AmityCommentTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        switch screenViewModel.item(at: indexPath) {
        case .comment(let comment), .replyComment(let comment):
            if isComment {
                presentOptionBottomSheet(comment: comment)
            } else {
                openCommentView()
            }
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
            
            self.showReactionUserList(info: info, reactionList: reactionList)
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
extension OneKTBActivityDetailViewController: UITableViewDataSource {
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
extension OneKTBActivityDetailViewController: UITableViewDelegate {
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
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Do not anything
    }
}

// MARK: - AmityMentionManagerDelegate
extension OneKTBActivityDetailViewController: AmityMentionManagerDelegate {
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
