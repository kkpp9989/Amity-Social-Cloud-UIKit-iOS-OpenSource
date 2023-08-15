//
//  LiveStreamBroadcastViewController.swift
//  AmityUIKitLiveStream
//
//  Created by Nutchaphon Rewik on 30/8/2564 BE.
//

import UIKit
import AmitySDK
import AmityLiveVideoBroadcastKit
import AmityUIKit

final public class LiveStreamBroadcastViewController: UIViewController {
    
    /// When the user finish live streaming, it will present post detail page.
    /// When the user exit post detail page, the it will dismiss back to this destination.
    public weak var destinationToUnwindBackAfterFinish: UIViewController?
    
    // MARK: - Dependencies
    
    let client: AmityClient
    let targetId: String?
    let targetType: AmityPostTargetType
    let communityRepository: AmityCommunityRepository
    let commentRepository: AmityCommentRepository
    let userRepository: AmityUserRepository
    let fileRepository: AmityFileRepository
    let streamRepository: AmityStreamRepository
    let postRepository: AmityPostRepository
    let reactionReposity: AmityReactionRepository
    var broadcaster: AmityStreamBroadcaster?

    // MARK: - Internal Const Properties
    
    /// The queue to execute go live operations.
    let goLiveOperationQueue = OperationQueue()
    
    /// Formatter to render live duration in streamingStatusLabel
    let liveDurationFormatter = DateComponentsFormatter()
    
    // MARK: - Private Const Properties
    private let mentionManager: AmityMentionManager
    // MARK: - States
    
    private var hasSetupBroadcaster = false
    
    /// Store cover image url, after the user choose cover image from the image picker.
    /// This will be used when the user press "go live" button.
    ///
    /// LiveStreamBroadcastVC+CoverImagePicker.swift
    var coverImageUrl: URL?
    
    /// Indicate current container state.
    ///
    /// LiveStreamBroadcast+UIContainerState.swift
    var containerState = ContainerState.create
    
    /// After successfully perform go live operationes, we will set the post.
    /// We use this post to start publish live stream, and navigate to post detail page, after the user finish streaming.
    var createdPost: AmityPost?
    
    /// This is set when this page start live publishing live stream.
    /// We use this state to display live stream timer.
    var startedAt: Date?
    
    /// We start this timer when we begin to publish stream.
    var liveDurationTimer: Timer?
    
    var liveObjectQueryToken: AmityNotificationToken?
    
    // MARK: - UI General
    @IBOutlet weak var renderingContainer: UIView!
    @IBOutlet private weak var overlayView: UIView!
    
    // MARK: - UI Container Create Components
    @IBOutlet weak var uiContainerCreate: UIView!
    
    // - uiContainerCreate.topRightStackView
    @IBOutlet private weak var selectCoverButton: UIButton!
    @IBOutlet private weak var coverImageContainer: UIView!
    @IBOutlet private weak var coverImageView: UIImageView!
    
    // - uiContainerCreate.detailStackView
    @IBOutlet weak var targetImageView: UIImageView!
    @IBOutlet weak var targetNameLabel: UILabel!
    @IBOutlet weak var titleTextField: AmityTextField!
    @IBOutlet weak var descriptionTextView: AmityTextView!
    
    @IBOutlet weak var goLiveButton: UIButton!
    
    // MARK: - UI Container Streaming Components
    @IBOutlet weak var uiContainerStreaming: UIView!
    @IBOutlet weak var streamingContainer: UIView!
    @IBOutlet weak var streamingStatusLabel: UILabel!
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var viewerCountLabel: UILabel!

    // MARK: - UI Container End Components
    @IBOutlet weak var uiContainerEnd: UIView!
    @IBOutlet weak var streamEndActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var streamEndLabel: UILabel!
    
    // MARK: - UI Mention tableView
    @IBOutlet private var mentionTableView: AmityMentionTableView!
    @IBOutlet private var mentionTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var mentionTableViewBottomConstraint: NSLayoutConstraint!
    
    // MARK: - UI Comment tableView
    @IBOutlet private weak var commentTableView: UITableView!
    @IBOutlet private weak var commentTextView: AmityTextView!
    @IBOutlet private weak var commentTextViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var postCommentButton: UIButton!
    @IBOutlet private weak var hideCommentButton: UIButton!
    @IBOutlet private weak var showCommentButton: UIButton!
    @IBOutlet private weak var streamingViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var liveCommentView: UIView!
    @IBOutlet private weak var liveCommentViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Keyboard Observations
    // LiveStreamBroadcastVC+Keyboard.swift
    var keyboardIsHidden = true
    var keyboardHeight: CGFloat = 0
    var keyboardObservationTokens: [NSObjectProtocol] = []
    
    // MARK: - Comment properties
    private var timer = Timer()
    private var fetchCommentToken: AmityNotificationToken?
    private var createCommentToken: AmityNotificationToken?
    private var collection: AmityCollection<AmityComment>?
    private var subscriptionManager: AmityTopicSubscription?
    private var commentSet: Set<String> = []
    private var storedComment: [AmityCommentModel] = []
    private var viewerCount: Int = 0

    // MARK: - Init / Deinit
    
    public init(client: AmityClient, targetId: String?, targetType: AmityPostTargetType) {
        
        self.client = client
        self.targetId = targetId
        self.targetType = targetType
         
        communityRepository = AmityCommunityRepository(client: client)
        commentRepository = AmityCommentRepository(client: client)
        userRepository = AmityUserRepository(client: client)
        fileRepository = AmityFileRepository(client: client)
        streamRepository = AmityStreamRepository(client: client)
        postRepository = AmityPostRepository(client: client)
        broadcaster = AmityStreamBroadcaster(client: client)
        reactionReposity = AmityReactionRepository(client: client)
        subscriptionManager = AmityTopicSubscription(client: client)
        mentionManager = AmityMentionManager(withType: .post(communityId: targetId))
        
        let bundle = Bundle(for: type(of: self))
        super.init(nibName: "LiveStreamBroadcastViewController", bundle: bundle)
        
        goLiveOperationQueue.maxConcurrentOperationCount = 1
        // It's fine to set the underlyingQueue to main thread.
        // The work items will be schedule and pickup on the main thread.
        // While the actual work will be run in the background thread.
        // See the detail of main() functions of GoLive operations.
        goLiveOperationQueue.underlyingQueue = .main
        
        liveDurationFormatter.allowedUnits = [.minute, .second]
        liveDurationFormatter.unitsStyle = .positional
        liveDurationFormatter.zeroFormattingBehavior = .pad
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        liveObjectQueryToken = nil
        unobserveKeyboardFrame()
        stopLiveDurationTimer()
    }
    
    // MARK: - View Controller Life Cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupTableView()
        queryTargetDetail()
        observeKeyboardFrame()
        updateCoverImageSelection()
        switchToUIState(.create)
        setupKeyboardListener()
        mentionManager.delegate = self
        mentionManager.setFont(AmityFontSet.body, highlightFont: AmityFontSet.bodyBold)
        mentionManager.setColor(.white, highlightColor: .white)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //
        updateUIBaseOnKeyboardFrame()
        //
        // If the permission is authorized, we can try setup broadcaster now.
        if permissionsGranted() {
            trySetupBroadcaster()
        } else if permissionsNotDetermined() {
            requestPermissions { [weak self] granted in
                if granted {
                    self?.trySetupBroadcaster()
                } else {
                    self?.presentPermissionRequiredDialogue()
                }
            }
        } else {
            presentPermissionRequiredDialogue()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { [self] timerobj in
            startRealTimeEventSubscribe()
            requestSendViewerStatisticsAPI()
            
            viewerCountLabel.text = String(viewerCount)
        })
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateUIBaseOnKeyboardFrame()
    }
    
    // MARK: - Internal Functions
    
    /// goLiveButtomSpace will change base on keyboard frame.
    func updateUIBaseOnKeyboardFrame() {
        
        // Currently we don't do update UI base on keyboard.
        
        guard isViewLoaded, view.window != nil else {
            // only perform this logic, when view controller is visible.
            return
        }
        if keyboardIsHidden {
            mentionTableViewBottomConstraint.constant = 0
        } else {
            mentionTableViewBottomConstraint.constant = keyboardHeight
        }
        view.setNeedsLayout()
        
    }
    
    /// Call this function to update UI state, when the user select / unselect cover image
    func updateCoverImageSelection() {
        if let coverImageUrl = coverImageUrl {
            coverImageView.image = UIImage(contentsOfFile: coverImageUrl.path)
            selectCoverButton.isHidden = true
            coverImageContainer.isHidden = false
        } else {
            selectCoverButton.isHidden = false
            coverImageContainer.isHidden = false
        }
    }
    
    // MARK: - Private Functions
    
    func setupKeyboardListener() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func setupTableView(){
        guard let nibName = NSStringFromClass(LiveStreamCommentTableViewCell.self).components(separatedBy: ".").last else {
            fatalError("Class name not found")
        }
        let bundle = Bundle(for: LiveStreamCommentTableViewCell.self)
        let uiNib = UINib(nibName: nibName, bundle: bundle)
        commentTableView.register(uiNib, forCellReuseIdentifier: LiveStreamCommentTableViewCell.identifier)
        commentTableView.delegate = self
        commentTableView.dataSource = self
        commentTableView.separatorStyle = .none
        commentTableView.backgroundColor = .clear
        commentTableView.allowsSelection = false
        commentTableView.showsVerticalScrollIndicator = false
        commentTableView.showsHorizontalScrollIndicator = false
        commentTableView.tag = 1
        
        let textViewToolbar: UIToolbar = UIToolbar()
        textViewToolbar.barStyle = .default
        textViewToolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: AmityLocalizedStringSet.General.done.localizedString, style: .done, target: self, action: #selector(cancelInput))
        ]
        textViewToolbar.sizeToFit()
        commentTextView.backgroundColor = UIColor(hex: "#FFFFFF")?.withAlphaComponent(0.1)
        commentTextView.layer.cornerRadius = 4
        commentTextView.font = AmityFontSet.body
        commentTextView.textColor = .white
        commentTextView.layer.cornerRadius = commentTextView.bounds.height / 2
        commentTextView.customTextViewDelegate = self
        commentTextView.textContainer.lineBreakMode = .byTruncatingTail
        commentTextView.placeholder = "Comment"
        commentTextView.autocorrectionType = .no
        commentTextView.spellCheckingType = .no
        commentTextView.inputAccessoryView = UIView()
        commentTextView.tag = 1
        
        liveCommentView.backgroundColor = .clear
        
        postCommentButton.titleLabel?.font = AmityFontSet.body
        postCommentButton.addTarget(self, action: #selector(self.sendComment), for: .touchUpInside)
    }
    
    private func setupViews() {
        
        targetNameLabel.textColor = .white
        targetNameLabel.font = AmityFontSet.bodyBold
        
        targetImageView.contentMode = .scaleAspectFill
        targetImageView.layer.cornerRadius = targetImageView.bounds.height * 0.5
        targetImageView.backgroundColor = UIColor.lightGray
        
        titleTextField.maxLength = 30
        titleTextField.font = AmityFontSet.headerLine
        titleTextField.textColor = .white
        titleTextField.returnKeyType = .done
        titleTextField.delegate = self
        titleTextField.autocorrectionType = .no
        titleTextField.spellCheckingType = .no
        titleTextField.inputAccessoryView = UIView()
        
        // [Custom for ONE Krungthai] Change placeholder text and set color white
        titleTextField.attributedPlaceholder = NSAttributedString(string: "Livestream title", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white] )
        
        descriptionTextView.text = nil
        descriptionTextView.padding = .zero
        descriptionTextView.backgroundColor = .clear
        descriptionTextView.font = AmityFontSet.body
        descriptionTextView.placeholder = "Tap to add post description..."
        descriptionTextView.textColor = .white
        descriptionTextView.returnKeyType = .done
        descriptionTextView.customTextViewDelegate = self
        descriptionTextView.typingAttributes = [.font: AmityFontSet.body, .foregroundColor: UIColor.white]
        descriptionTextView.autocorrectionType = .no
        descriptionTextView.spellCheckingType = .no
        descriptionTextView.inputAccessoryView = UIView()
        
        let textViewToolbar: UIToolbar = UIToolbar()
        textViewToolbar.barStyle = .default
        textViewToolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(cancelInput))
        ]
        textViewToolbar.sizeToFit()
        descriptionTextView.inputAccessoryView = textViewToolbar
        
        selectCoverButton.setTitle("Select cover", for: .normal)
        selectCoverButton.setTitleColor(.white, for: .normal)
        selectCoverButton.titleLabel?.font = AmityFontSet.body
        selectCoverButton.backgroundColor = .black
        selectCoverButton.layer.cornerRadius = 8
        selectCoverButton.clipsToBounds = true
        
        coverImageView.clipsToBounds = true
        coverImageView.layer.cornerRadius = 4
        coverImageView.isUserInteractionEnabled = true
        coverImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectCoverButtonDidTouch)))
        
        goLiveButton.backgroundColor = .white
        goLiveButton.clipsToBounds = true
        goLiveButton.layer.cornerRadius = 4
        goLiveButton.layer.borderWidth = 1
        goLiveButton.layer.borderColor = UIColor(red: 0.647, green: 0.663, blue: 0.71, alpha: 1).cgColor
        goLiveButton.setAttributedTitle(NSAttributedString(string: "Go live", attributes: [
            .foregroundColor: UIColor.black,
            .font: AmityFontSet.bodyBold
        ]), for: .normal)
        
        streamingContainer.clipsToBounds = true
        streamingContainer.layer.cornerRadius = 4
        streamingContainer.backgroundColor = UIColor(red: 1, green: 0.188, blue: 0.353, alpha: 1)
        streamingStatusLabel.textColor = .white
        streamingStatusLabel.font = AmityFontSet.captionBold
        
        viewerCountLabel.font = AmityFontSet.captionBold
        viewerCountLabel.textColor = .white

        setupMentionTableView()
    }
    
    private func trySetupBroadcaster() {
        if !hasSetupBroadcaster && permissionsGranted() {
            hasSetupBroadcaster = true
            setupBroadcaster()
        }
    }
    
    private func setupBroadcaster() {
        
        guard let broadcaster = broadcaster else {
            assertionFailure("broadcaster must exist at this point.")
            return
        }
        
        let config = AmityStreamBroadcasterConfiguration()
        config.canvasFitting = .fill
        config.bitrate = 3_000_000 // 3mbps
        config.frameRate = .fps30
        
        broadcaster.delegate = self
        broadcaster.videoResolution = renderingContainer.bounds.size
        broadcaster.setup(with: config)
        
        // [Custom for ONE Krungthai] Set default to front camera same as Android
        broadcaster.cameraPosition = .front
        
        // Embed broadcaster.previewView
        broadcaster.previewView.translatesAutoresizingMaskIntoConstraints = false
        renderingContainer.addSubview(broadcaster.previewView)
        
        NSLayoutConstraint.activate([
            broadcaster.previewView.centerYAnchor.constraint(equalTo: renderingContainer.centerYAnchor),
            broadcaster.previewView.centerXAnchor.constraint(equalTo: renderingContainer.centerXAnchor),
            broadcaster.previewView.widthAnchor.constraint(equalToConstant: renderingContainer.bounds.width),
            broadcaster.previewView.heightAnchor.constraint(equalToConstant: renderingContainer.bounds.height)
        ])
        
    }
    
    private func switchCamera() {
        
        guard let broadcaster = broadcaster else {
            assertionFailure("broadcaster must exist at this point.")
            return
        }
        
        switch broadcaster.cameraPosition {
        case .front:
            broadcaster.cameraPosition = .back
        case .back:
            broadcaster.cameraPosition = .front
        @unknown default:
            assertionFailure("Unhandled case")
        }
        
    }
    
    private func presentEndLiveStreamConfirmationDialogue() {
        let title = "Do yo want to end the live stream?"
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        let end = UIAlertAction(title: "End", style: .default) { [weak self] action in
            self?.finishLive()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(end)
        alertController.addAction(cancel)
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func cancelInput() {
        view.endEditing(true)
    }
    
    private func setupMentionTableView() {
        mentionTableView.isHidden = true
        mentionTableView.delegate = self
        mentionTableView.dataSource = self
        mentionTableView.register(AmityMentionTableViewCell.nib, forCellReuseIdentifier: AmityMentionTableViewCell.identifier)
    }
    
    private func showAlertForMaximumCharacters() {
        let title = "Unable to post"
        let message = "You have reached maximum 20,000 characters in a post."
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Done", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func updateTableViewHeightConstraints() {
        let contentHeight = commentTableView.contentSize.height
        let maxHeight = 270.0
        
        if contentHeight > maxHeight {
            
        } else {
            
        }
    }
    
    func formatTimeInterval(_ minutes: Int) -> String {
        let hours = minutes / 60
        let minutesRemainder = minutes % 60
        return String(format: "%02d:%02d", hours, minutesRemainder)
    }
    
    // MARK: - IBActions
    
    @IBAction private func switchCameraButtonDidTouch() {
        switchCamera()
    }
    
    @IBAction private func selectCoverButtonDidTouch() {
        if coverImageUrl != nil {
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let selectImagesAction = UIAlertAction(title: "Change cover image", style: .default) { [weak self] _ in
                self?.presentCoverImagePicker()
            }
            
            actionSheet.addAction(selectImagesAction)
            
            let removeCoverPhotoAction = UIAlertAction(title: "Remove cover image", style: .destructive) { [weak self] _ in
                // Handle removing the cover photo
                self?.coverImageUrl = nil
                self?.updateCoverImageSelection()
            }
            
            actionSheet.addAction(removeCoverPhotoAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            actionSheet.addAction(cancelAction)
            
            if let popoverController = actionSheet.popoverPresentationController {
                popoverController.sourceView = selectCoverButton // Set the button that triggered the action sheet
                popoverController.sourceRect = selectCoverButton.bounds
            }
            
            present(actionSheet, animated: true, completion: nil)
            
        } else {
            self.presentCoverImagePicker()
        }
      
    }
    
    @IBAction private func closeButtonDidTouch() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func goLiveButtonDidTouch() {
        let titleCount = "\(titleTextField.text ?? "")\n\n".count
        let metadata = mentionManager.getMetadata(shift: titleCount)
        let mentionees = mentionManager.getMentionees()
        
        mentionManager.resetState()
        
        goLive(metadata: metadata, mentionees: mentionees)
    }
    
    @IBAction func finishButtonDidTouch() {
        presentEndLiveStreamConfirmationDialogue()
    }
    
    @IBAction func hideCommentTable() {
        commentTableView.isHidden = true
        hideCommentButton.isHidden = true
        showCommentButton.isHidden = false
    }
    
    @IBAction func showCommentTable() {
        commentTableView.isHidden = false
        hideCommentButton.isHidden = false
        showCommentButton.isHidden = true
    }
    
}

extension LiveStreamBroadcastViewController: AmityTextViewDelegate {
    public func textViewDidChangeSelection(_ textView: AmityTextView) {
        if textView.tag != 1 {
            mentionManager.changeSelection(textView)
        }
    }
    
    public func textView(_ textView: AmityTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView.text?.count ?? 0 > AmityMentionManager.maximumCharacterCountForPost {
            showAlertForMaximumCharacters()
            return false
        }
        if textView != commentTextView {
            return mentionManager.shouldChangeTextIn(textView, inRange: range, replacementText: text, currentText: textView.text ?? "")
        } else {
            return true
        }
    }
    
    public func textViewDidChange(_ textView: AmityTextView) {
        if textView == commentTextView {
            if !textView.text.isEmpty {
                postCommentButton.isEnabled = true
            }
            let contentSize = textView.sizeThatFits(textView.bounds.size)
            if contentSize.height < 70 {
                commentTextViewHeight.constant = contentSize.height
                liveCommentViewHeightConstraint.constant = 70 + contentSize.height - 36
                textView.isScrollEnabled = false
            } else {
                textView.isScrollEnabled = true
            }
        }
    }
}

extension LiveStreamBroadcastViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        switch textField {
        case titleTextField:
            return titleTextField.verifyFields(shouldChangeCharactersIn: range, replacementString: string)
            
        default:
            return true
        }
    }
    
}

extension LiveStreamBroadcastViewController: AmityStreamBroadcasterDelegate {
    
    public func amityStreamBroadcasterDidUpdateState(_ broadcaster: AmityStreamBroadcaster) {
        updateStreamingStatusText()
    }
    
}

// MARK: - AmityMentionManagerDelegate
extension LiveStreamBroadcastViewController: AmityMentionManagerDelegate {
    public func didGetHashtag(keywords: [AmityHashtagModel]) {
        
    }
    
    public func didGetUsers(users: [AmityMentionUserModel]) {
        if users.isEmpty {
            mentionTableViewHeightConstraint.constant = 0
            mentionTableView.isHidden = true
        } else {
            var heightConstant:CGFloat = 240.0
            if users.count < 5 {
                heightConstant = CGFloat(users.count) * 52.0
            }
            mentionTableViewHeightConstraint.constant = heightConstant
            mentionTableView.isHidden = false
            mentionTableView.reloadData()
        }
    }
    
    public func didCreateAttributedString(attributedString: NSAttributedString) {
        descriptionTextView.attributedText = attributedString
        descriptionTextView.typingAttributes = [.font: AmityFontSet.body, .foregroundColor: UIColor.white]
    }
    
    public func didMentionsReachToMaximumLimit() {
        let alertController = UIAlertController(title: AmityLocalizedStringSet.Mention.unableToMentionTitle.localizedString, message: AmityLocalizedStringSet.Mention.unableToMentionReplyDescription.localizedString, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.done.localizedString, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    public func didCharactersReachToMaximumLimit() {
        showAlertForMaximumCharacters()
    }
}

// MARK: - UITableViewDataSource
extension LiveStreamBroadcastViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 1 {
            return storedComment.count
        }
        
        return mentionManager.users.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag == 1 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: LiveStreamCommentTableViewCell.identifier) as? LiveStreamCommentTableViewCell else { return UITableViewCell() }
            cell.display(comment: storedComment[indexPath.row])
            cell.delegate = self
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AmityMentionTableViewCell.identifier) as? AmityMentionTableViewCell else { return UITableViewCell() }
        if let model = mentionManager.item(at: indexPath) {
            cell.display(with: model)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension LiveStreamBroadcastViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView.tag == 1 {
            if indexPath.row < storedComment.count {
                let currentComment = storedComment[indexPath.row]
                return LiveStreamCommentTableViewCell.height(for: currentComment, boundingWidth: commentTableView.bounds.width - 40)
            }
        }
        return AmityMentionTableViewCell.height
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.tag != 1 {
            var textInput: UITextInput = titleTextField
            var text = titleTextField.text
            if !titleTextField.isFirstResponder {
                textInput = descriptionTextView
                text = descriptionTextView.text
            }
            
            mentionManager.addMention(from: textInput, in: text ?? "", at: indexPath)
        }
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView.isBottomReached {
            if tableView.tag == 1 {
                
            } else {
                mentionManager.loadMore()
            }
        }
    }
}

// MARK: - Observer comment repository
extension LiveStreamBroadcastViewController {
    func startRealTimeEventSubscribe() {
        DispatchQueue.main.async { [self] in
            guard let currentPost = createdPost else { return }
            let eventTopic = AmityPostTopic(post: currentPost, andEvent: .comments)
            subscriptionManager?.subscribeTopic(eventTopic) { success, error in
                if let error = error {
                    print("[RTE]Error: \(error.localizedDescription)")
                } else {
                    print("[RTE] Sucess")
                }
            }
            
            getCommentsForPostId(withReferenceId: currentPost.postId, referenceType: .post, filterByParentId: false, parentId: currentPost.parentPostId, orderBy: .ascending, includeDeleted: false)
        }
    }
    
    @objc func sendComment() {
        //Reset all constant
        self.view.endEditing(true)
        commentTextViewHeight.constant = 36
        liveCommentViewHeightConstraint.constant = 70
        
        guard let currentPost = createdPost else { return }
        if commentTextView.text != "" || commentTextView.text == nil {
            guard let currentText = commentTextView.text else { return }
            self.commentTextView.text = ""
            self.postCommentButton.isEnabled = false
            createComment(withReferenceId: currentPost.postId, referenceType: .post, parentId: currentPost.parentPostId, text: currentText)
        } else {
            return
        }
    }
    
    private func requestSendViewerStatisticsAPI() {
        DispatchQueue.main.async { [self] in
            guard let currentPost = createdPost else { return }
            let serviceRequest = RequestViewerStatistics()
            serviceRequest.sendViewerStatistics(postId: currentPost.postId, viewerUserId: client.currentUserId ?? "", viewerDisplayName: client.user?.object?.displayName ?? "", isTrack: false, streamId: "") { result in
                switch result {
                case .success(let dataResponse):
                    self.viewerCount = dataResponse.viewerCount ?? 0
                    break
                case .failure(_):
                    break
                }
            }
        }
    }
}

// MARK: - Repository observer
extension LiveStreamBroadcastViewController {
    func getCommentsForPostId(withReferenceId postId: String, referenceType: AmityCommentReferenceType, filterByParentId isParent: Bool, parentId: String?, orderBy: AmityOrderBy, includeDeleted: Bool) {
        
        fetchCommentToken?.invalidate()
        let queryOptions = AmityCommentQueryOptions(referenceId: postId, referenceType: referenceType, filterByParentId: isParent, parentId: parentId, orderBy: orderBy, includeDeleted: includeDeleted)
        collection = commentRepository.getComments(with: queryOptions)
        
        fetchCommentToken = collection?.observe { [weak self] (commentCollection, _, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                print(error.localizedDescription)
            } else {
                strongSelf.storedComment = strongSelf.prepareData()
                strongSelf.reloadData()
            }
        }
    }
        
    private func prepareData() -> [AmityCommentModel] {
        guard let collection = collection else { return [] }
        var models = [AmityCommentModel]()
        for i in 0..<collection.count() {
            guard let comment = collection.object(at: i) else { continue }
            let model = AmityCommentModel(comment: comment)
            models.append(model)
        }
        return models
    }
    
    func reloadData() {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.commentTableView.reloadData()
            
            if !strongSelf.storedComment.isEmpty {
                strongSelf.commentTableView.scrollToRow(at: IndexPath(row: strongSelf.commentTableView.numberOfRows(inSection: 0) - 1, section: 0), at: .bottom, animated: true)

                guard let collection = strongSelf.collection else { return }
                if collection.hasNext {
                    collection.nextPage()
                }
            }
        }
    }
    
    func createComment(withReferenceId postId: String, referenceType: AmityCommentReferenceType, parentId: String?, text: String) {
        let createOptions: AmityCommentCreateOptions
        createOptions = AmityCommentCreateOptions(referenceId: postId, referenceType: referenceType, text: text, parentId: parentId)
        
        commentRepository.createComment(with: createOptions) { comment, error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
}

//Move view when keyboard show and hide
extension LiveStreamBroadcastViewController {
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        
        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let endFrameY = endFrame?.origin.y ?? 0
        
        if endFrameY >= UIScreen.main.bounds.size.height {
            self.streamingViewBottomConstraint?.constant = 0.0
        } else {
            self.streamingViewBottomConstraint?.constant = endFrame?.size.height ?? 0.0
        }
        
        UIView.animate(withDuration: 0) {
            self.view.layoutIfNeeded()
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if streamingViewBottomConstraint.constant != 0.0 {
            streamingViewBottomConstraint.constant = 0.0
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func addReaction(withReaction reaction: String, referanceId: String, referenceType: AmityReactionReferenceType, completion: AmityRequestCompletion?) {
        reactionReposity.addReaction(reaction, referenceId: referanceId, referenceType: referenceType, completion: completion)
    }
    
    func removeReaction(withReaction reaction: String, referanceId: String, referenceType: AmityReactionReferenceType, completion: AmityRequestCompletion?) {
        reactionReposity.removeReaction(reaction, referenceId: referanceId, referenceType: referenceType, completion: completion)
    }
}

extension LiveStreamBroadcastViewController: LiveStreamCommentTableViewCellProtocol {
    func didReactionTap(reaction: String, isLike: Bool) {
        DispatchQueue.main.async { [self] in
            if isLike {
                removeReaction(withReaction: "like", referanceId: reaction, referenceType: .comment) { [weak self] (success, error) in
                    guard let strongSelf = self else { return }
                    strongSelf.startRealTimeEventSubscribe()
                }
            } else {
                addReaction(withReaction: "like", referanceId: reaction, referenceType: .comment) { [weak self] (success, error) in
                    guard let strongSelf = self else { return }
                    strongSelf.startRealTimeEventSubscribe()
                }
            }
        }
    }    
}
