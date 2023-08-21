//
//  AmityHashtagFeedViewController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 19/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

class AmityHashtagFeedViewController: AmityViewController, AmityRefreshable {
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var tableView: AmityPostTableView!
    private var expandedIds: Set<String> = []
    private var pollAnswers: [String: [String]] = [:]
    
    // MARK: - Properties
    private var screenViewModel: AmityHashtagScreenViewModelType!
    private var keyword: String = ""
    private var count: Int = 0

    // MARK: - Post Protocol Handler
    private var postHeaderProtocolHandler: AmityPostHeaderProtocolHandler?
    private var postFooterProtocolHandler: AmityPostFooterProtocolHandler?
    private var postPostProtocolHandler: AmityPostProtocolHandler?

    private let refreshControl = UIRefreshControl()
    
    // A flag represents for loading indicator visibility
    private var shouldShowLoader: Bool = true
    
    public var headerView: FeedHeaderPresentable? {
        didSet {
            debouncer.run { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    self?.tableView.reloadData()
                }
            }
        }
    }
    var emptyView: UIView?
    var dataDidUpdateHandler: ((Int) -> Void)?
    var emptyViewHandler: ((UIView?) -> Void)?
    var pullRefreshHandler: (() -> Void)?
    
    // To determine if the vc is visible or not
    private var isVisible: Bool = true
    
    // It will be marked as dirty when data source changed on view disappear.
    private var isDataSourceDirty: Bool = false
    
    private let debouncer = Debouncer(delay: 0.3)
    
    // Reaction Picker
    private let reactionPickerView = AmityReactionPickerView()
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    
    // MARK: - View lifecycle
    deinit {
        screenViewModel.action.stopObserveFeedUpdate()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupProtocolHandler()
        setupScreenViewModel()
        setupReactionPicker()
        setupNavigationBar()
        setupPostCountTitle()
        
        // Initial ONE Krungthai Custom theme
        theme = ONEKrungthaiCustomTheme(viewController: self)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Set color navigation bar by custom theme
        theme?.setBackgroundNavigationBar()
        
        isVisible = true
        
        if isDataSourceDirty {
            isDataSourceDirty = false
            tableView.reloadData()
        }
        
        // this line solves issue where refresh control sticks to the top while switching tab
        resetRefreshControlStateIfNeeded()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isVisible = false
        refreshControl.endRefreshing()
    }
    
    private func resetRefreshControlStateIfNeeded() {
        if !refreshControl.isHidden {
            tableView.setContentOffset(.zero, animated: false)
        }
    }
    
    public static func make(feedType: AmityPostFeedType, keyword: String, count: Int) -> AmityHashtagFeedViewController {
        let postController = AmityPostController()
        let commentController = AmityCommentController()
        let reaction = AmityReactionController()
        let viewModel = AmityHashtagScreenViewModel(withFeedType: feedType,
                                                    postController: postController,
                                                    commentController: commentController,
                                                    reactionController: reaction,
                                                    keyword: keyword)
        let vc = AmityHashtagFeedViewController(nibName: AmityHashtagFeedViewController.identifier, bundle: AmityUIKitManager.bundle)
        vc.screenViewModel = viewModel
        vc.keyword = keyword
        vc.count = count
        return vc
    }

    // MARK: Setup Post Protocol Handler
    private func setupProtocolHandler() {
        postHeaderProtocolHandler = AmityPostHeaderProtocolHandler(viewController: self)
        postHeaderProtocolHandler?.delegate = self
        
        postFooterProtocolHandler = AmityPostFooterProtocolHandler(viewController: self)
        postFooterProtocolHandler?.delegate = self
        
        postPostProtocolHandler = AmityPostProtocolHandler()
        postPostProtocolHandler?.delegate = self
        postPostProtocolHandler?.viewController = self
        postPostProtocolHandler?.tableView = tableView
        
    }
    
    // MARK: - Setup ViewModel
    private func setupScreenViewModel() {
        screenViewModel.delegate = self
        screenViewModel.action.startObserveFeedUpdate()
        screenViewModel.action.fetchUserSettings()
        screenViewModel.action.fetchPosts(keyword: keyword)
    }
    
    // MARK: - Setup Views
    private func setupView() {
        setupTableView()
        setupRefreshControl()
    }
    
    private func setupTableView() {
        tableView.backgroundColor = AmityColorSet.secondary.blend(.shade4)
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.registerCustomCell()
        tableView.registerPostCell()
        tableView.register(AmityFeedHeaderTableViewCell.self, forCellReuseIdentifier: AmityFeedHeaderTableViewCell.identifier)
        tableView.register(AmityEmptyStateHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: AmityEmptyStateHeaderFooterView.identifier)
        tableView.postDataSource = self
        tableView.postDelegate = self
    }
    
    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(handleRefreshingControl), for: .valueChanged)
        refreshControl.tintColor = AmityColorSet.base.blend(.shade3)
        tableView.refreshControl = refreshControl
    }
    
    private func setupReactionPicker() {
        reactionPickerView.alpha = 0
        view.addSubview(reactionPickerView)
        
        // Setup tap gesture recognizer
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissReactionPicker))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    private func setupNavigationBar() {
        // Create a label for the navigation title
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        
        let postCountString = "\n\(count.formatUsingAbbrevation()) posts"
        
        // Create attributed string with the desired formatting
        let attributedString = NSMutableAttributedString(string: keyword)
        
        // Set the attributes for the first line (bold font)
        attributedString.setAttributes([NSAttributedString.Key.font: AmityFontSet.bodyBold], range: NSMakeRange(0, keyword.utf16.count))
        
        let attributedStringExtented = NSMutableAttributedString(string: postCountString)
        attributedStringExtented.setAttributes([NSAttributedString.Key.font: AmityFontSet.caption, NSAttributedString.Key.foregroundColor: AmityColorSet.base.blend(.shade3)], range: NSMakeRange(0, postCountString.utf16.count))

        // Set the attributes for the second line (caption font)
        attributedString.append(attributedStringExtented)
        
        // Assign the attributed string to the label
        titleLabel.attributedText = attributedString
        
        // Assign the label to the navigation item's title view
        navigationItem.titleView = titleLabel
    }
    
    func setupPostCountTitle() {
        if count == 0 {
            screenViewModel.action.fetchHashtagData(keyword: keyword)
        }
    }
    
    // MARK: SrollToTop
    private func scrollToTop() {
        guard tableView.numberOfRows(inSection: 0) > 0 else { return }
        
        let topRow = IndexPath(row: 0, section: 0)
        DispatchQueue.main.async { [weak self] in
            self?.tableView.scrollToRow(at: topRow, at: .top, animated: false)
        }
    }
    
    // MARK: - Refreshing
    func handleRefreshing() {
        // when refresh control is working, we don't need to show this loader.
        shouldShowLoader = false
        screenViewModel.action.refresh()
        screenViewModel.action.fetchPosts(keyword: keyword)
    }
    
    @objc private func handleRefreshingControl() {
        guard Reachability.shared.isConnectedToNetwork && AmityUIKitManagerInternal.shared.client.isEstablished else {
            tableView.reloadData()
            dataDidUpdateHandler?(0)
            refreshControl.endRefreshing()
            return
        }
        pullRefreshHandler?()
        screenViewModel.action.refresh()
        screenViewModel.action.fetchPosts(keyword: keyword)
    }
    
}

// MARK: - ReactionPickerView
extension AmityHashtagFeedViewController {
    
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
extension AmityHashtagFeedViewController: AmityPostTableViewDelegate {
    
    func tableView(_ tableView: AmityPostTableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch cell.self {
        case is AmityFeedHeaderTableViewCell:
            (cell as? AmityFeedHeaderTableViewCell)?.set(headerView: headerView?.headerView, postTabHeaderView: nil)
            break
        default:
            (cell as? AmityPostHeaderProtocol)?.delegate = postHeaderProtocolHandler
            (cell as? AmityPostFooterProtocol)?.delegate = postFooterProtocolHandler
            (cell as? AmityPostProtocol)?.delegate = postPostProtocolHandler
            (cell as? AmityPostPreviewCommentProtocol)?.delegate = self
            break
        }
    }

    func tableView(_ tableView: AmityPostTableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            guard let headerView = headerView else {
                return 0
            }
            return headerView.height
        } else {
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: AmityPostTableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView.isBottomReached {
            screenViewModel.action.loadMore()
        }
    }
    
    func tableView(_ tableView: AmityPostTableView, didSelectRowAt indexPath: IndexPath) {
        // skip header section handling
        guard indexPath.section > 0 else { return }
        
        let singleComponent = screenViewModel.dataSource.postComponents(in: indexPath.section)
        let postId = singleComponent._composable.post.postId
        AmityEventHandler.shared.postDidtap(from: self, postId: postId)
    }
    
    func tableView(_ tableView: AmityPostTableView, heightForFooterInSection section: Int) -> CGFloat {
        let postComponentsCount = screenViewModel.dataSource.numberOfPostComponents() - (headerView == nil ? 1:0)
        return postComponentsCount > 0 ? 0 : tableView.frame.height
    }

    func tableView(_ tableView: AmityPostTableView, viewForFooterInSection section: Int) -> UIView?  {
        guard let bottomView = tableView.dequeueReusableHeaderFooterView(withIdentifier: AmityEmptyStateHeaderFooterView.identifier) as? AmityEmptyStateHeaderFooterView else {
            return nil
        }
        
        // 1) if the datasource is loading, shows loading indicator at the center of page.
        // 2) if the refresh control is working, skip showing a loading indicator.
        //    otherwise, there will be 2 spinners working together.
        if screenViewModel.dataSource.isLoading && !refreshControl.isRefreshing && shouldShowLoader {
            bottomView.setLayout(layout: .loading)
            return bottomView
        }
        
        if let emptyView = emptyView {
            bottomView.setLayout(layout: .custom(emptyView))
        } else {
            switch screenViewModel.dataSource.getFeedType() {
            case .userFeed:
                if screenViewModel.dataSource.isPrivate {
                    bottomView.setLayout(layout: .custom(AmityPrivateAccountView(frame: .zero)))
                } else {
                    bottomView.setLayout(layout: .label(title: AmityLocalizedStringSet.emptyTitleNoPosts.localizedString, subtitle: nil, image: AmityIconSet.emptyNoPosts))
                }
            default:
                bottomView.setLayout(layout: .label(title: AmityLocalizedStringSet.emptyNewsfeedTitle.localizedString,
                                                    subtitle: AmityLocalizedStringSet.emptyNewsfeedStartYourFirstPost.localizedString,
                                                    image: nil))
                emptyViewHandler?(bottomView)
                return bottomView
            }
        }
        emptyViewHandler?(bottomView)
        return bottomView
    }
    
    func tableViewWillBeginDragging(_ tableView: AmityPostTableView) {
        hideReactionPicker()
    }
}

// MARK: - AmityPostTableViewDataSource
extension AmityHashtagFeedViewController: AmityPostTableViewDataSource {
    func numberOfSections(in tableView: AmityPostTableView) -> Int {
        return screenViewModel.dataSource.numberOfPostComponents()
    }
    
    func tableView(_ tableView: AmityPostTableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return headerView == nil ? 0 : 1
        } else {
            let singleComponent = screenViewModel.dataSource.postComponents(in: section)
            if let component = tableView.feedDataSource?.getUIComponentForPost(post: singleComponent._composable.post, at: section) {
                return component.getComponentCount(for: section)
            }
            return singleComponent.getComponentCount(for: section)
        }
        
    }
    
    func tableView(_ tableView: AmityPostTableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell: AmityFeedHeaderTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            return cell
        }
        
        let singleComponent = screenViewModel.dataSource.postComponents(in: indexPath.section)
        
        if let clientComponent = tableView.feedDataSource?.getUIComponentForPost(post: singleComponent._composable.post, at: indexPath.section) {
            return clientComponent.getComponentCell(tableView, at: indexPath)
        } else {
            // HACK: inject commentExpandedIds before configuring cell
            singleComponent._composable.post.commentExpandedIds = expandedIds
            return singleComponent.getComponentCell(tableView, at: indexPath)
        }
    }
}

// MARK: - AmityHashtagScreenViewModelDelegate
extension AmityHashtagFeedViewController: AmityHashtagScreenViewModelDelegate {
    func screenViewModelDidUpdateHashtagDataSuccess(_ viewModel: AmityHashtagScreenViewModelType, postCount: Int) {
        count = postCount == 0 ? screenViewModel.dataSource.numberOfPostComponents() : postCount
        DispatchQueue.main.async { [self] in
            setupNavigationBar()
        }
    }
    
    func screenViewModelDidUpdateDataSuccess(_ viewModel: AmityHashtagScreenViewModelType) {
        // When view is invisible but data source request updates, mark it as a dirty data source.
        // Then after view already appear, reload table view for refreshing data.
        guard isVisible else {
            isDataSourceDirty = true
            return
        }
        debouncer.run { [weak self] in
            self?.tableView.reloadData()
        }
        dataDidUpdateHandler?(screenViewModel.dataSource.numberOfPostComponents())
        refreshControl.endRefreshing()
    }
    
    func screenViewModelLoadingState(_ viewModel: AmityHashtagScreenViewModelType, for loadingState: AmityLoadingState) {
        switch loadingState {
        case .loading:
            tableView.showLoadingIndicator()
        case .loaded:
            tableView.tableFooterView = UIView()
        case .initial:
            break
        }
    }
    
    func screenViewModelScrollToTop(_ viewModel: AmityHashtagScreenViewModelType) {
        scrollToTop()
    }
    
    func screenViewModelDidSuccess(_ viewModel: AmityHashtagScreenViewModelType, message: String) {
        AmityHUD.show(.success(message: message.localizedString))
    }
    
    func screenViewModelDidFail(_ viewModel: AmityHashtagScreenViewModelType, failure error: AmityError) {
        switch error {
        case .unknown:
            AmityHUD.show(.error(message: AmityLocalizedStringSet.HUD.somethingWentWrong.localizedString))
        case .noUserAccessPermission:
            debouncer.run { [weak self] in
                self?.tableView.reloadData()
            }
        default:
            break
        }
    }
    
    // MARK: - Post
    func screenViewModelDidLikePostSuccess(_ viewModel: AmityHashtagScreenViewModelType) {
        tableView.feedDelegate?.didPerformActionLikePost()
    }
    
    func screenViewModelDidUnLikePostSuccess(_ viewModel: AmityHashtagScreenViewModelType) {
        tableView.feedDelegate?.didPerformActionUnLikePost()
    }
    
    func screenViewModelDidGetReportStatusPost(isReported: Bool) {
        postHeaderProtocolHandler?.showOptions(withReportStatus: isReported)
    }
    
    // MARK: - Comment
    func screenViewModelDidLikeCommentSuccess(_ viewModel: AmityHashtagScreenViewModelType) {
        tableView.feedDelegate?.didPerformActionLikeComment()
    }
    
    func screenViewModelDidUnLikeCommentSuccess(_ viewModel: AmityHashtagScreenViewModelType) {
        tableView.feedDelegate?.didPerformActionUnLikeComment()
    }
    
    func screenViewModelDidDeleteCommentSuccess(_ viewModel: AmityHashtagScreenViewModelType) {
        // Do something with success
    }
    
    func screenViewModelDidEditCommentSuccess(_ viewModel: AmityHashtagScreenViewModelType) {
        // Do something with success
    }
    
    func screenViewModelDidGetUserSettings(_ viewModel: AmityHashtagScreenViewModelType) {
        debouncer.run { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    func screenViewModelLoadingStatusDidChange(_ viewModel: AmityHashtagScreenViewModelType, isLoading: Bool) {
        tableView.reloadData()
    }
    
}

// MARK: - AmityPostHeaderProtocolHandlerDelegate
extension AmityHashtagFeedViewController: AmityPostHeaderProtocolHandlerDelegate {
    func headerProtocolHandlerDidPerformAction(_ handler: AmityPostHeaderProtocolHandler, action: AmityPostProtocolHeaderHandlerAction, withPost post: AmityPostModel) {
        let postId: String = post.postId
        switch action {
        case .tapOption:
            screenViewModel.action.getReportStatus(withPostId: post.postId)
        case .tapDelete:
            screenViewModel.action.delete(withPostId: postId)
        case .tapReport:
            screenViewModel.action.report(withPostId: postId)
        case .tapUnreport:
            screenViewModel.action.unreport(withPostId: postId)
        case .tapClosePoll:
            screenViewModel.action.close(withPollId: post.poll?.id)
        }
    }
    
}

// MARK: - AmityPostProtocolHandlerDelegate
extension AmityHashtagFeedViewController: AmityPostProtocolHandlerDelegate {
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
extension AmityHashtagFeedViewController: AmityPostFooterProtocolHandlerDelegate {
    
    func footerProtocolHandlerDidPerformView(_ handler: AmityPostFooterProtocolHandler, view: UIView) {
        let likeButtonFrameInSuperview = view.convert(view.bounds, to: self.view)
        reactionPickerView.frame.origin = CGPoint(x: 16, y: likeButtonFrameInSuperview.maxY - likeButtonFrameInSuperview.height - self.reactionPickerView.frame.height)
    }
    
    func footerProtocolHandlerDidPerformAction(_ handler: AmityPostFooterProtocolHandler, action: AmityPostFooterProtocolHandlerAction, withPost post: AmityPostModel) {
        switch action {
        case .tapLike:
            if let reactionType = post.reacted {
                screenViewModel.action.removeReaction(id: post.postId, reaction: reactionType, referenceType: .post)
            } else {
                screenViewModel.action.addReaction(id: post.postId, reaction: .create, referenceType: .post)
            }
        case .tapComment, .tapReactionDetails:
            AmityEventHandler.shared.postDidtap(from: self, postId: post.postId)
        case .tapHoldLike:
            if let reactionType = post.reacted {
                screenViewModel.action.removeReaction(id: post.postId, reaction: reactionType, referenceType: .post)
            }
            else {
                reactionPickerView.onSelect = { [weak self] reactionType in
                    self?.hideReactionPicker()
                    self?.screenViewModel.action.addReaction(id: post.postId, reaction: reactionType, referenceType: .post)
                }
                showReactionPicker()
            }
        }
    }
}

// MARK: AmityPostPreviewCommentDelegate
extension AmityHashtagFeedViewController: AmityPostPreviewCommentDelegate {
    
    public func didPerformAction(_ cell: AmityPostPreviewCommentProtocol, action: AmityPostPreviewCommentAction) {
        guard let post = cell.post else { return }
        switch action {
        case .tapAvatar(let comment):
            AmityEventHandler.shared.userDidTap(from: self, userId: comment.userId)
        case .tapLike(let comment):
            if let comment = post.latestComments.first(where: { $0.id == comment.id}) {
                comment.isLiked ? screenViewModel.action.unlike(id: comment.id, referenceType: .comment) : screenViewModel.action.like(id: comment.id, referenceType: .comment)
            }
        case .tapOption(let comment):
            if let comment = post.latestComments.first(where: { $0.id == comment.id }) {
                handleCommentOption(comment: comment)
            }
        case .tapReply:
            AmityEventHandler.shared.postDidtap(from: self, postId: post.postId)
        case .tapExpandableLabel, .tapOnReactionDetail:
            AmityEventHandler.shared.postDidtap(from: self, postId: post.postId)
        case .willExpandExpandableLabel:
            tableView.beginUpdates()
        case .didExpandExpandableLabel(let label):
            let point = label.convert(CGPoint.zero, to: tableView)
            if let indexPath = tableView.indexPathForRow(at: point) as IndexPath? {
                // expand label in comment preview cell
                if let commentPreviewCell = tableView.cellForRow(at: indexPath) as?  AmityPostPreviewCommentTableViewCell,
                   let comment = commentPreviewCell.comment {
                    expandedIds.insert(comment.id)
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [weak self] in
                        self?.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                    }
                }
            }
            tableView.endUpdates()
        case .willCollapseExpandableLabel:
            tableView.beginUpdates()
        case .didCollapseExpandableLabel(let label):
            let point = label.convert(CGPoint.zero, to: tableView)
            if let indexPath = tableView.indexPathForRow(at: point) as IndexPath? {
                // expand label in comment preview cell
                if let commentPreviewCell = tableView.cellForRow(at: indexPath) as?  AmityPostPreviewCommentTableViewCell,
                   let comment = commentPreviewCell.comment {
                    expandedIds.remove(comment.id)
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [weak self] in
                        self?.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                    }
                }
            }
            tableView.endUpdates()
        case .tapOnMention(let userId):
            AmityEventHandler.shared.userDidTap(from: self, userId: userId)
        case .tapOnHashtag(keyword: let keyword, count: let count):
            AmityEventHandler.shared.hashtagDidTap(from: self, keyword: keyword, count: count)
        case .tapCommunityName(post: let post): // [Custom for ONE Krungthai] Add tap to community for moderator user in official community action
            break // Nothing happen for hashtag
        }
    }
   
    private func handleCommentOption(comment: AmityCommentModel) {
        let bottomSheet = BottomSheetViewController()
        let contentView = ItemOptionView<TextItemOption>()
        bottomSheet.sheetContentView = contentView
        bottomSheet.isTitleHidden = true
        bottomSheet.modalPresentationStyle = .overFullScreen
        
        let editOption = TextItemOption(title: AmityLocalizedStringSet.PostDetail.editComment.localizedString) { [weak self] in
            guard let strongSelf = self else { return }
            let feedType = strongSelf.screenViewModel.getFeedType()
            var commId: String? = nil
            switch feedType {
            case .communityFeed(let communityId), .pendingPostsFeed(let communityId):
                commId = communityId
            default: break
            }
            let editTextViewController = AmityCommentEditorViewController.make(comment: comment, communityId: commId)
            editTextViewController.title = AmityLocalizedStringSet.PostDetail.editComment.localizedString
            editTextViewController.editHandler = { [weak self] text, metadata, mentionees in
                self?.screenViewModel.action.edit(withComment: comment, text: text, metadata: metadata, mentionees: mentionees)
                editTextViewController.dismiss(animated: true, completion: nil)
            }
            editTextViewController.dismissHandler = {
                editTextViewController.dismiss(animated: true, completion: nil)
            }
            let nvc = UINavigationController(rootViewController: editTextViewController)
            nvc.modalPresentationStyle = .fullScreen
            strongSelf.present(nvc, animated: true, completion: nil)
        }
        
        let deleteOption = TextItemOption(title: AmityLocalizedStringSet.PostDetail.deleteComment.localizedString) { [weak self] in
            let alert = UIAlertController(title: AmityLocalizedStringSet.PostDetail.deleteCommentTitle.localizedString, message: AmityLocalizedStringSet.PostDetail.deleteCommentMessage.localizedString, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: AmityLocalizedStringSet.General.delete.localizedString, style: .destructive) { [weak self] _ in
                self?.screenViewModel.action.delete(withCommentId: comment.id)
            })
            self?.present(alert, animated: true, completion: nil)
        }
        
        let unreportOption = TextItemOption(title: AmityLocalizedStringSet.General.undoReport.localizedString) { [weak self] in
            self?.screenViewModel.action.unreport(withCommentId: comment.id)
        }
        
        let reportOption = TextItemOption(title: AmityLocalizedStringSet.General.report.localizedString) { [weak self] in
            self?.screenViewModel.action.report(withCommentId: comment.id)
        }
        
        // Comment options
        if comment.isOwner {
            contentView.configure(items: [editOption, deleteOption], selectedItem: nil)
            present(bottomSheet, animated: false, completion: nil)
        } else {
            screenViewModel.action.getReportStatus(withCommendId: comment.id) { [weak self] (isReported) in
                
                var items: [TextItemOption] = isReported ? [unreportOption] : [reportOption]
                contentView.configure(items: items, selectedItem: nil)
                
                // if it is in community feed, check permission before options
                if case .communityFeed(let communityId) = self?.screenViewModel.dataSource.getFeedType() {
                    AmityUIKitManagerInternal.shared.client.hasPermission(.editCommunity, forCommunity: communityId) { [weak self] (hasPermission) in
                        if hasPermission {
                            items.insert(deleteOption, at: 0)
                        }
                        contentView.configure(items: items, selectedItem: nil)
                        self?.present(bottomSheet, animated: false, completion: nil)
                    }
                } else {
                    self?.present(bottomSheet, animated: false, completion: nil)
                }
            }
            
        }
        
    }
}
