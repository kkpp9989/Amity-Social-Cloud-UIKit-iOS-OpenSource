//
//  LiveStreamPlayerViewController.swift
//  AmityUIKitLiveStream
//
//  Created by Nutchaphon Rewik on 7/9/2564 BE.
//

import UIKit
import AmityUIKit
import AmitySDK
import AmityVideoPlayerKit

public class LiveStreamPlayerViewController: UIViewController {
    
    private let streamIdToWatch: String
    private let streamRepository: AmityStreamRepository
    private let postRepository: AmityPostRepository
    private let reactionRepository: AmityReactionRepository
    private let commentRepository: AmityCommentRepository
    
    private var postObject: AmityObject<AmityPost>?
    private var postToken: AmityNotificationToken?
    
    private var stream: AmityStream?
    private var getStreamToken: AmityNotificationToken?
    
    @IBOutlet private weak var renderView: UIView!
    
    @IBOutlet weak var statusContainer: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var viewerCountContainer: UIView!
    @IBOutlet weak var viewerCountLabel: UILabel!
    
    @IBOutlet weak var reactionCountContainer: UIView!
    @IBOutlet weak var reactionCountLabel: UILabel!
    
    /// The view above renderView to intercept tap gestuere for show/hide control container.
    @IBOutlet private weak var renderGestureView: UIView!
    
    @IBOutlet private weak var loadingOverlay: UIView!
    @IBOutlet private weak var loadingActivityIndicator: UIActivityIndicatorView!
    
    // MARK: - Control Container
    @IBOutlet private weak var controlContainer: UIView!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var stopButton: UIButton!
    
    // MARK: - Stream End Container
    @IBOutlet private weak var streamEndContainer: UIView!
    @IBOutlet private weak var streamEndTitleLabel: UILabel!
    @IBOutlet private weak var streamEndDescriptionLabel: UILabel!
    
    // MARK: - UI Comment tableView
    @IBOutlet private weak var commentContainer: UIView!
    @IBOutlet private weak var commentTableView: UITableView!
    @IBOutlet private weak var commentTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var commentTextView: AmityTextView!
    @IBOutlet private weak var commentTextViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var postCommentButton: UIButton!
    @IBOutlet private weak var hideCommentButton: UIButton!
    @IBOutlet private weak var showCommentButton: UIButton!
    @IBOutlet private weak var streamingViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var liveCommentView: UIView!
    @IBOutlet private weak var liveCommentViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var reactionContainerView: UIView!
    @IBOutlet private weak var reactionHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var reactionWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var reactionButton: UIButton!
    
    // MARK: - Stream Pause Container
    @IBOutlet private weak var streamPauseContainer: UIView!
    @IBOutlet private weak var streamPauseTitleLabel: UILabel!
    @IBOutlet private weak var streamPauseDescriptionLabel: UILabel!
    
    // MARK: - Keyboard Observations
    var keyboardIsHidden = true
    var keyboardHeight: CGFloat = 0
    var keyboardObservationTokens: [NSObjectProtocol] = []
    
    // MARK: - Interval timer [Custom]
    private var timer: Timer?
    
    // MARK: - Post Info [Custom]
    private var postID: String?
    private var amityPost: AmityPost?
    
    // MARK: - Viewer User Info [Custom]
    private var viewerUserID: String?
    private var viewerDisplayName: String?
    
    /// This sample app uses AmityVideoPlayer to play live videos.
    /// The player consumes the stream instance, and works automatically.
    /// At the this moment, the player only provide basic functionality, play and stop.
    ///
    /// For more rich features, it is recommend to use other video players that support RTMP streaming.
    /// You can get the RTMP url, by checking at `.watcherUrl` property.
    ///
    private var player: AmityVideoPlayer
    
    private var fetchCommentToken: AmityNotificationToken?
    private var createCommentToken: AmityNotificationToken?
    private var collection: AmityCollection<AmityComment>?
    private var subscriptionManager: AmityTopicSubscription?
    private var storedComment: [AmityCommentModel] = []
    private var viewerCount: Int = 0
    private var commentCount: Int = 0
    
    private var isFirstTime: Bool = true
    private var isPostSubscribe: Bool = false
    private var isCommentSubscribe: Bool = false
    private var isDisconnectLivestreamSuccess: Bool = false
    private var isLive: Bool = true
    
    // Reaction Picker
    private let reactionPickerView = AmityReactionPickerView()
    private var currentReactionType: String = ""
    
    /// Indicate that the user request to play the stream
    private var isStarting = true {
        didSet {
            updateContainer()
            updateControlActionButton()
        }
    }
    
    /// Indicate that the user request to play the stream, but the stream object is not yet ready.
    /// So we wait for stream object from the observe block.
    private var requestingStreamObject = true {
        didSet {
            updateContainer()
            updateControlActionButton()
        }
    }
    
    private var videoView: UIView!
    
    public init(streamIdToWatch: String, postID: String, postModel: AmityPost) {
        self.streamRepository = AmityStreamRepository(client: AmityUIKitManager.client)
        self.postRepository = AmityPostRepository(client: AmityUIKitManager.client)
        self.reactionRepository = AmityReactionRepository(client: AmityUIKitManager.client)
        self.commentRepository = AmityCommentRepository(client: AmityUIKitManager.client)
        self.streamIdToWatch = streamIdToWatch
        self.subscriptionManager = AmityTopicSubscription(client: AmityUIKitManager.client)
        self.player = AmityVideoPlayer(client: AmityUIKitManager.client)
        self.postID = postID
        self.viewerUserID = AmityUIKitManager.client.user?.snapshot?.userId ?? AmityUIKitManager.currentUserId
        self.viewerDisplayName = AmityUIKitManager.client.user?.snapshot?.displayName ?? AmityUIKitManager.displayName
        self.amityPost = postModel
        
        let bundle = Bundle(for: type(of: self))
        super.init(nibName: "LiveStreamPlayerViewController", bundle: bundle)
        
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        unobserveStreamObject()
        stopStream()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupStreamView()
        setupView()
        setupTableView()
        updateControlActionButton()
        setupKeyboardListener()
        isStarting = true
        requestingStreamObject = true
        observeStreamObject()
        setupReactionPicker()
        setBackgroundListener()
        setupStreamPauseView()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startRealTimeEventSubscribe()
        requestConnectLiveStream()
        isDisconnectLivestreamSuccess = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { [self] timerobj in
            startRealTimeEventSubscribe()
            requestGetViewerCount()
            requestGetLiveStreamStatus()
            requestCreateLiveStreamLog()
            
            viewerCountLabel.text = String(viewerCount)
            streamPauseContainer.isHidden = isLive
        })
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Invalidate all token
        unobserveStreamObject()
        
        // Stop the playing stream.
        stopStream()
        // Once we know that the stream has already end, we clean up requestToPlay / playing states.
        isStarting = false
        requestingStreamObject = false
        
        // [Custom for ONE Krungthai] Stop and delete interval timer for request stat API
        timer?.invalidate()
        timer = nil
        if !isDisconnectLivestreamSuccess { // Check disconnected success for prevent disconnected success duplicate (livestream end)
            requestDisconnectLiveStream()
        }
        
        guard let currentPost = amityPost else { return }
        currentPost.unsubscribeEvent(.comments) { _, _ in }
    }
    
    func setBackgroundListener() {
        NotificationCenter.default.addObserver(self, selector: #selector(stopStream), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playStream), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    private func setupStreamView() {
        // Create video view and embed in playerContainer
        videoView = UIView(frame: renderView.bounds)
        // We don't want to receive touch event for video view.
        // The touch event should pass through to the playerContainer.
        videoView.isUserInteractionEnabled = false
        videoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        renderView.addSubview(videoView)
        // Tell the player to render the video in this view.
        player.renderView = videoView
        player.delegate = self
    }
    
    private func setupView() {
        statusContainer.clipsToBounds = true
        statusContainer.layer.cornerRadius = 4
        statusContainer.backgroundColor = UIColor(red: 1, green: 0.188, blue: 0.353, alpha: 1)
        statusLabel.textColor = .white
        statusLabel.font = AmityFontSet.captionBold
        statusLabel.text = "LIVE"
        
        // We show "LIVE" static label while playing.
        statusContainer.isHidden = true
        
        viewerCountContainer.clipsToBounds = true
        viewerCountContainer.layer.cornerRadius = 4
        viewerCountLabel.font = AmityFontSet.captionBold
        viewerCountLabel.textColor = .white
        
        reactionCountContainer.clipsToBounds = true
        reactionCountContainer.layer.cornerRadius = 4
        reactionCountLabel.font = AmityFontSet.captionBold
        reactionCountLabel.textColor = .white
        
        streamEndTitleLabel.font = AmityFontSet.title
        streamEndDescriptionLabel.font = AmityFontSet.body
        
        loadingOverlay.isHidden = true
        
        // Show control at start by default
        controlContainer.isHidden = false
        
        loadingActivityIndicator.stopAnimating()
        
        // [Custom for ONE Krungthai] Set player view (controler container) hidden when open livestream
        controlContainerDidTap()
        
        controlContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(controlContainerDidTap)))
        
        renderGestureView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(playerContainerDidTap)))
        
        // Create a long press gesture recognizer
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(likeHoldTap(_:)))
        longPressRecognizer.minimumPressDuration = 0.2
        reactionButton.addGestureRecognizer(longPressRecognizer)
        
        let dismissKeyboard = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(dismissKeyboard)
        liveCommentView.addGestureRecognizer(dismissKeyboard)
        commentContainer.addGestureRecognizer(dismissKeyboard)
    }
    
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
        commentTextView.backgroundColor = UIColor(hex: "#292B32")
        commentTextView.layer.cornerRadius = 4
        commentTextView.font = AmityFontSet.body
        commentTextView.textColor = .white
        commentTextView.layer.cornerRadius = commentTextView.bounds.height / 2
        commentTextView.customTextViewDelegate = self
        commentTextView.textContainer.lineBreakMode = .byTruncatingTail
        commentTextView.placeholder = "Comment"
        commentTextView.tag = 1
        commentTextView.autocorrectionType = .no
        commentTextView.spellCheckingType = .no
        commentTextView.inputAccessoryView = UIView()
        
        liveCommentView.backgroundColor = .clear
        
        postCommentButton.titleLabel?.font = AmityFontSet.body
        postCommentButton.addTarget(self, action: #selector(self.sendComment), for: .touchUpInside)
        
        let reactionType = findReactionType()
        if !reactionType.isEmpty {
            reactionButton.isSelected = false
            setReactionType(reactionType: AmityReactionType(rawValue: reactionType) ?? .like)
        } else {
            reactionButton.setImage(UIImage(named: "like_dna_icon"), for: .selected)
        }
    }
    
    private func setupReactionPicker() {
        reactionPickerView.alpha = 0
        reactionContainerView.isHidden = true
        reactionContainerView.addSubview(reactionPickerView)
        
        // Setup tap gesture recognizer
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissReactionPicker))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        liveCommentView.addGestureRecognizer(tap)
        commentContainer.addGestureRecognizer(tap)
        
        reactionHeightConstraint.constant = reactionPickerView.viewHeight
        reactionWidthConstraint.constant = reactionPickerView.viewWidth
        
        let reactionType = findReactionType()
        if !reactionType.isEmpty {
            setReactionType(reactionType: AmityReactionType(rawValue: reactionType) ?? .like)
            reactionButton.isSelected = true
        } else {
            reactionButton.isSelected = false
        }
    }
    
    private func setupStreamPauseView() {
        streamPauseContainer.isHidden = true
        streamPauseTitleLabel.font = AmityFontSet.title
        streamPauseTitleLabel.textColor = .white
        streamPauseTitleLabel.text = "LIVE paused"
        
        streamPauseDescriptionLabel.font = AmityFontSet.body
        streamPauseDescriptionLabel.textColor = .white
        streamPauseDescriptionLabel.text = "The host will be back soon."
    }
    
    @objc private func playerContainerDidTap() {
        dismissKeyboard()
        hideReactionPicker()
        UIView.animate(withDuration: 0.15, animations: {
            self.controlContainer.alpha = 1
        }, completion: { finish in
            self.controlContainer.isUserInteractionEnabled = true
        })
    }
    
    @objc private func controlContainerDidTap() {
        controlContainer.isUserInteractionEnabled = false
        dismissKeyboard()
        hideReactionPicker()
        UIView.animate(withDuration: 0.15) {
            self.controlContainer.alpha = 0
        }
    }
    
    @objc func cancelInput() {
        view.endEditing(true)
    }
    
    @objc func likeHoldTap(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            var reactionType = findReactionType()
            if reactionType.isEmpty {
                reactionType = currentReactionType
            }
            reactionPickerView.onSelect = { [weak self] reactionValue in
                self?.reactionButton.isEnabled = false
                self?.hideReactionPicker()
                if reactionType == reactionValue.rawValue {
                    self?.animateReactionButton()
                    return // Do nothing
                }
                if !reactionType.isEmpty || !(self?.currentReactionType.isEmpty ?? true) {
                    self?.removeReaction(withReaction: reactionType, referanceId: self?.postID ?? "", referenceType: .post) { [weak self] (success, error) in
                        self?.reactionButton.isSelected = false
                        if success {
                            DispatchQueue.main.async {
                                self?.addReaction(withReaction: reactionValue.rawValue, referanceId: self?.postID ?? "", referenceType: .post) { [weak self] (success, error) in
                                    if success {
                                        self?.reactionButton.isSelected = true
                                        self?.setReactionType(reactionType: reactionValue)
                                        self?.currentReactionType = reactionValue.rawValue
                                        self?.animateReactionButton()
                                    } else {
                                        self?.reactionButton.isEnabled = true
                                    }
                                }
                            }
                        }
                    }
                } else {
                    self?.addReaction(withReaction: reactionValue.rawValue, referanceId: self?.postID ?? "", referenceType: .post) { [weak self] (success, error) in
                        if success {
                            self?.reactionButton.isSelected = true
                            self?.setReactionType(reactionType: reactionValue)
                            self?.currentReactionType = reactionValue.rawValue
                            self?.animateReactionButton()
                        } else {
                            self?.reactionButton.isEnabled = true
                        }
                    }
                }
            }
            showReactionPicker()
        }
    }
    
    private func updateControlActionButton() {
        switch stream?.status {
        case .ended, .recorded, .idle:
            // Stream has already end, no need to show play and stop button.
            streamPauseContainer.isHidden = isLive
            playButton.isHidden = true
            stopButton.isHidden = true
        default:
            // Stream end has not determine, play and stop button rely on player.mediaState.
            switch player.mediaState {
            case .playing:
                playButton.isHidden = true
                stopButton.isHidden = false
                statusContainer.isHidden = false
            case .stopped:
                playButton.isHidden = false
                stopButton.isHidden = true
                statusContainer.isHidden = true
            @unknown default:
                assertionFailure("Unexpected state")
            }
        }
    }
    
    private func updateContainer() {
        let status: AmityStreamStatus?
        
        if let isDeleted = stream?.isDeleted, isDeleted {
            // NOTE: If stream is deleted, we show the idle state UI.
            status = .idle
        } else {
            status = stream?.status
        }
        
        switch status {
        case .ended, .recorded:
            // Stream End Container will obseceure all views to show title and description.
            streamEndContainer.isHidden = false
            streamEndTitleLabel.text = "This livestream has ended."
            streamEndDescriptionLabel.text = "Playback will be available for you to watch shortly."
            streamEndDescriptionLabel.isHidden = false
        case .idle:
            // Stream End Container will obseceure all views to show title and description.
            streamEndContainer.isHidden = false
            streamEndTitleLabel.text = "The stream is currently unavailable."
            streamEndDescriptionLabel.text = nil
            streamEndDescriptionLabel.isHidden = true
        case .live, .none:
            // If stream end has not yet determined
            // - We hide streamEndContainer.
            streamEndContainer.isHidden = true
            // - We hide/show loadingOverlay based on loading states.
            if isStarting || requestingStreamObject {
                if !loadingActivityIndicator.isAnimating {
                    loadingActivityIndicator.startAnimating()
                }
                loadingOverlay.isHidden = false
            } else {
                loadingOverlay.isHidden = true
                loadingActivityIndicator.stopAnimating()
            }
        default:
            assertionFailure("Unexpected state")
        }
        
        
    }
    
    private func observeStreamObject() {
        getStreamToken = streamRepository.getStreamById(streamIdToWatch).observe { [weak self] data, error in
            
            guard let strongSelf = self else { return }
            
            if let error = error {
                self?.presentUnableToPlayLiveStreamError(reason: error.localizedDescription)
                return
            }
            
            guard let streamToWatch = data.object else {
                self?.presentUnableToPlayLiveStreamError(reason: nil)
                return
            }
            
            strongSelf.stream = streamToWatch
            
            let streamIsUnavailable: Bool
            
            if streamToWatch.isDeleted {
                streamIsUnavailable = true
            } else {
                switch streamToWatch.status {
                case .ended, .recorded:
                    streamIsUnavailable = true
                default:
                    streamIsUnavailable = false
                }
            }
            
            // stream is unavailable to watch.
            if streamIsUnavailable {
                // No longer need to observe stream update, it is already end.
                strongSelf.getStreamToken = nil
                // Stop the playing stream.
                strongSelf.stopStream()
                // Once we know that the stream has already end, we clean up requestToPlay / playing states.
                strongSelf.isStarting = false
                strongSelf.requestingStreamObject = false
                // Update container, this will trigger stream end container to obsecure all the views.
                strongSelf.updateContainer()
                
                // [Custom for ONE Krungthai] Stop and delete interval timer for request stat API
                self?.timer?.invalidate()
                self?.timer = nil
                self?.requestDisconnectLiveStream()
                
                return
            }
            
            // stream is available to watch.
            switch streamToWatch.status {
            case .idle, .live:
                // Once we know that the stream is now .idle/.live
                // We check the requestingStreamObject that wait for stream object to be ready.
                // So we trigger `playStream` again, because the stream info is ready for the player to play.
                if strongSelf.requestingStreamObject {
                    // We turnoff the flag, so if the stream object is updated.
                    // It will not trigger playStream again.
                    strongSelf.requestingStreamObject = false
                    strongSelf.playStream()
                }
            default:
                break
            }
            
        }
        
    }
    
    private func unobserveStreamObject() {
        getStreamToken = nil
        subscriptionManager = nil
        postToken?.invalidate()
        postToken = nil
        fetchCommentToken?.invalidate()
        fetchCommentToken = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func playStream() {
        
        isStarting = true
        
        guard let stream = stream else {
            // Stream object is not yet ready, so we set this flag, when the stream object is ready.
            // We will trigger this function again.
            requestingStreamObject = true
            return
        }
        
        switch stream.status {
        case .ended, .recorded:
            isStarting = false
            return
        default:
            break
        }
        
        player.play(stream, completion: { [weak self] result in
            self?.isStarting = false
            switch result {
            case .failure(let error):
                self?.presentUnableToPlayLiveStreamError(reason: error.localizedDescription)
            case .success:
                break
            }
        })
        
    }
    
    private func presentUnableToPlayLiveStreamError(reason: String?) {
        presentErrorDialogue(title: "Unable to play live stream.", message: reason, ok: { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        })
    }
    
    @objc private func stopStream() {
        player.stop()
    }
    
    @IBAction private func stopButtonDidTouch() {
        stopStream()
    }
    
    @IBAction private func playButtonDidTouch() {
        playStream()
    }
    
    @IBAction func closeButtonDidTouch() {
        dismiss(animated: true, completion: nil)
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
    
    @IBAction func showReactionView() {
        reactionButton.isEnabled = false
        hideReactionPicker()
        
        let reactionType = findReactionType()
        if isFirstTime && !reactionType.isEmpty {
            currentReactionType = reactionType
            isFirstTime = false
        }
        
        if reactionType == currentReactionType && !reactionType.isEmpty {
            animateReactionButton()
            return // Do nothing
        }
        
        addReaction(withReaction: "create", referanceId: postID ?? "", referenceType: .post) { [weak self] (success, error) in
            if success {
                self?.reactionButton.isSelected = true
                self?.setReactionType(reactionType: .create)
                self?.currentReactionType = "create"
                self?.animateReactionButton()
            } else {
                self?.reactionButton.isEnabled = true
            }
        }
    }
    
    private func findReactionType() -> String {
        let reactionTypes: [AmityReactionType] = [.create, .honest, .harmony, .success, .society, .like, .love]
        let filteredArray = amityPost?.myReactions.filter { reactionTypes.contains(AmityReactionType(rawValue: $0) ?? .like) }
        guard filteredArray?.count ?? 0 > 0 else { return "" }
        return filteredArray?[0] ?? "like"
    }
    
    private func animateReactionButton() {
        reactionButton.isEnabled = true
        
        let bubbleWidth: CGFloat = 40
        let bubbleHeight: CGFloat = 40
        
        let randomXOffset = CGFloat.random(in: -20...20) // Adjust the range as needed
        let randomYOffset = CGFloat.random(in: 8...20) // Adjust the range as needed
        
        let likeButtonFrameInSuperview = reactionButton.convert(reactionButton.bounds, to: self.view)
        
        let newOrigin = CGPoint(
            x: likeButtonFrameInSuperview.origin.x + randomXOffset,
            y: likeButtonFrameInSuperview.origin.y - bubbleHeight + randomYOffset
        )
        
        let bubbleView = FloatingBubbleView(frame: CGRect(origin: newOrigin, size: CGSize(width: bubbleWidth, height: bubbleHeight)))
        bubbleView.reactionType = currentReactionType
        bubbleView.runAnimate()
        view.addSubview(bubbleView)
        
        // Set the amplitude and frequency for the wave animation
        let amplitude: CGFloat = 10 // Adjust the amplitude of the wave
        let frequency: CGFloat = 0.5 // Adjust the frequency of the wave
        
        UIView.animate(withDuration: 3.0, delay: 0, options: [.curveEaseInOut], animations: {
            bubbleView.center.y -= 600
            bubbleView.center.x += amplitude * sin(bubbleView.center.y * frequency)
            bubbleView.center.y -= amplitude * sin(bubbleView.center.x * frequency)
            bubbleView.alpha = 0.0
        }) { (_) in
            bubbleView.removeFromSuperview()
        }
    }
    
    private func setReactionType(reactionType: AmityReactionType) {
        switch reactionType {
        case .create:
            reactionButton.setImage(AmityIconSet.iconBadgeDNASangsun, for: .selected)
            reactionButton.setImage(AmityIconSet.iconBadgeDNASangsun, for: .normal)
        case .honest:
            reactionButton.setImage(AmityIconSet.iconBadgeDNASatsue, for: .selected)
            reactionButton.setImage(AmityIconSet.iconBadgeDNASatsue, for: .normal)
        case .harmony:
            reactionButton.setImage(AmityIconSet.iconBadgeDNASamakki, for: .selected)
            reactionButton.setImage(AmityIconSet.iconBadgeDNASamakki, for: .normal)
        case .success:
            reactionButton.setImage(AmityIconSet.iconBadgeDNASumrej, for: .selected)
            reactionButton.setImage(AmityIconSet.iconBadgeDNASumrej, for: .normal)
        case .society:
            reactionButton.setImage(AmityIconSet.iconBadgeDNASangkom, for: .selected)
            reactionButton.setImage(AmityIconSet.iconBadgeDNASangkom, for: .normal)
        case .like:
            reactionButton.setImage(AmityIconSet.iconLikeFill, for: .selected)
            reactionButton.setImage(AmityIconSet.iconLikeFill, for: .normal)
        case .love:
            reactionButton.setImage(AmityIconSet.iconBadgeDNALove, for: .selected)
            reactionButton.setImage(AmityIconSet.iconBadgeDNALove, for: .normal)
        @unknown default:
            reactionButton.setImage(AmityIconSet.iconBadgeDNALove, for: .selected)
            reactionButton.setImage(AmityIconSet.iconBadgeDNALove, for: .normal)
        }
    }
}

// MARK: - ReactionPickerView
extension LiveStreamPlayerViewController {
    
    @objc private func dismissReactionPicker(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: view)
        if !reactionPickerView.frame.contains(location) {
            hideReactionPicker()
        }
    }
    
    private func showReactionPicker() {
        UIView.animate(withDuration: 0.1) {
            self.reactionPickerView.alpha = 1 // Fade in
            self.reactionContainerView.isHidden = false
        }
    }
    
    private func hideReactionPicker() {
        UIView.animate(withDuration: 0.1) {
            self.reactionPickerView.alpha = 0 // Fade out
            self.reactionContainerView.isHidden = true
        }
    }
}

extension LiveStreamPlayerViewController: AmityVideoPlayerDelegate {
    
    public func amityVideoPlayerMediaStateChanged(_ player: AmityVideoPlayer) {
        updateControlActionButton()
    }
    
}

extension LiveStreamPlayerViewController: AmityTextViewDelegate {
    public func textViewDidChangeSelection(_ textView: AmityTextView) {
    }
    
    public func textView(_ textView: AmityTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView.text?.count ?? 0 > AmityMentionManager.maximumCharacterCountForPost {
            return false
        }
        return true
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
    
    public func textFieldShouldReturn(_ textField: AmityTextView) -> Bool {
        textField.resignFirstResponder()
        dismissKeyboard()
        return true
    }
}

// MARK: - UITableViewDataSource
extension LiveStreamPlayerViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return storedComment.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LiveStreamCommentTableViewCell.identifier) as? LiveStreamCommentTableViewCell else { return UITableViewCell() }
        cell.display(comment: storedComment[indexPath.row], post: amityPost)
        cell.delegate = self
        return cell
        
    }
}

// MARK: - UITableViewDelegate
extension LiveStreamPlayerViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row < storedComment.count {
            let currentComment = storedComment[indexPath.row]
            return LiveStreamCommentTableViewCell.height(for: currentComment, boundingWidth: commentTableView.bounds.width - 40)
        }
        return UITableView.automaticDimension
    }
}

// MARK: - Observer comment repository
extension LiveStreamPlayerViewController {
    func startRealTimeEventSubscribe() {
        if !isPostSubscribe && !isCommentSubscribe {
            guard let currentPost = amityPost else { return }
            if !isCommentSubscribe {
                let eventTopic = AmityPostTopic(post: currentPost, andEvent: .comments)
                subscriptionManager?.subscribeTopic(eventTopic) { isSuccess,_ in self.isCommentSubscribe = isSuccess }
            }
            if !isPostSubscribe {
                let eventPostTopic = AmityPostTopic(post: currentPost, andEvent: .post)
                subscriptionManager?.subscribeTopic(eventPostTopic) { isSuccess,_ in }
            }
            getCommentsForPostId(withReferenceId: postID ?? "", referenceType: .post, filterByParentId: false, parentId: currentPost.parentPostId, orderBy: .descending, includeDeleted: false)
            getPostForPostId(withPostId: postID ?? "")
        }
    }
    
    @objc func sendComment() {
        //Reset all constant
        self.view.endEditing(true)
        commentTextViewHeight.constant = 36
        liveCommentViewHeightConstraint.constant = 70
        
        guard let currentPost = amityPost else { return }
        if commentTextView.text != "" || commentTextView.text == nil {
            guard let currentText = commentTextView.text else { return }
            self.commentTextView.text = ""
            self.postCommentButton.isEnabled = false
            createComment(withReferenceId: postID ?? "", referenceType: .post, parentId: currentPost.parentPostId, text: currentText)
        } else {
            return
        }
    }
    
    // [Deprecated][Custom for ONE Krungthai] Request send viewer statistic to custom API for dashboard
    private func requestSendViewerStatisticsAPI() {
        let serviceRequest = RequestViewerStatistics()
        serviceRequest.sendViewerStatistics(postId: postID ?? "", viewerUserId: viewerUserID ?? "", viewerDisplayName: viewerDisplayName ?? "", isTrack: true, streamId: streamIdToWatch) { result in
            switch result {
            case .success(let dataResponse):
                self.viewerCount = dataResponse.data?.viewerCount ?? 0
                break
            case .failure(_):
                break
            }
        }
    }
    
    // [Current use][Custom for ONE Krungthai] Request get viewer count from custom API
    private func requestGetViewerCount() {
        DispatchQueue.main.async { [self] in
            let serviceRequest = RequestViewerStatistics()
            serviceRequest.getViewerCount(postId: postID ?? "") { result in
                switch result {
                case .success(let dataResponse):
                    self.viewerCount = dataResponse.viewerCount ?? 0
                    break
                case .failure(let error):
                    break
                }
            }
        }
    }
    
    // [Current use][Custom for ONE Krungthai] Request connect livestream to backend by custom API
    private func requestConnectLiveStream() {
        let serviceRequest = RequestViewerStatistics()
        serviceRequest.connectLivestream(postId: postID ?? "", viewerUserId: viewerUserID ?? "", viewerDisplayName: viewerDisplayName ?? "", streamId: streamIdToWatch) { result in
            switch result {
            case .success(_):
                break
            case .failure(let error):
                break
            }
        }
    }
    
    // [Current use][Custom for ONE Krungthai] Request disconnect livestream to backend by custom API
    private func requestDisconnectLiveStream() {
        let serviceRequest = RequestViewerStatistics()
        serviceRequest.disconnectLivestream(postId: postID ?? "", viewerUserId: viewerUserID ?? "", viewerDisplayName: viewerDisplayName ?? "", streamId: streamIdToWatch) { result in
            switch result {
            case .success(let isSuccess):
                self.isDisconnectLivestreamSuccess = isSuccess
                break
            case .failure(let error):
                break
            }
        }
    }
    
    private func requestGetLiveStreamStatus() {
        DispatchQueue.main.async { [self] in
            let serviceRequest = RequestViewerStatistics()
            serviceRequest.getLiveStreamStatus(postId: postID ?? "") { [weak self] (result) in
                guard let strongSelf = self else { return }
                switch result {
                case .success(let isLive):
                    strongSelf.isLive = isLive
                case .failure(let error):
                    break
                }
            }
        }
    }
    
    private func requestCreateLiveStreamLog() {
        let serviceRequest = RequestViewerStatistics()
        serviceRequest.createLiveStreamLog(postId: postID ?? "", viewerUserId: viewerUserID ?? "", viewerDisplayName: viewerDisplayName ?? "", streamId: streamIdToWatch) { result in
            switch result {
            case .success(_):
                break
            case .failure(let error):
                break
            }
        }
    }
}

// MARK: - Repository observer
extension LiveStreamPlayerViewController {
    func getPostForPostId(withPostId postId: String) {
        postToken?.invalidate()
        postObject = postRepository.getPost(withId: postId)
        postToken = postObject?.observe { [weak self] (_, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                print(error.localizedDescription)
            } else {
                let post = strongSelf.preparePostData()
                strongSelf.amityPost = post?.post
                strongSelf.updateReactionCount(reactionCount: post?.reactionsCount ?? 0)
            }
        }
    }
    
    private func preparePostData() -> AmityPostModel? {
        guard let _post = postObject?.object else { return nil }
        let post = AmityPostModel(post: _post)
        return post
    }
    
    func getCommentsForPostId(withReferenceId postId: String, referenceType: AmityCommentReferenceType, filterByParentId isParent: Bool, parentId: String?, orderBy: AmityOrderBy, includeDeleted: Bool) {
        
        let queryOptions = AmityCommentQueryOptions(referenceId: postId, referenceType: referenceType, filterByParentId: isParent, parentId: parentId, orderBy: orderBy, includeDeleted: includeDeleted)
        collection = commentRepository.getComments(with: queryOptions)

        fetchCommentToken = collection?.observe { [weak self] (commentCollection, _, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                print(error.localizedDescription)
            } else {
                strongSelf.storedComment = strongSelf.prepareData()
                strongSelf.reloadData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    strongSelf.updateTableViewHeight()
                }
            }
        }
    }
    
    private func prepareData() -> [AmityCommentModel] {
        guard let collection = collection else { return [] }
        var models = [AmityCommentModel]()
        for i in 0..<collection.count() {
            guard let comment = collection.object(at: i) else { continue }
            let model = AmityCommentModel(comment: comment)
            
            // Check if a model with the same id already exists in the models array
            if models.contains(where: { $0.id == model.id }) {
                continue  // Skip appending the model if the id already exists
            }
            
//            models.append(model)
            models.insert(model, at: 0)
        }
        return models
    }
    
    func reloadData() {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            
            guard let collection = strongSelf.collection else { return }
            if collection.hasPrevious {
                collection.previousPage()
            } else {
                // Get the initial number of rows before reloading
                let initNumberOfRows = strongSelf.commentTableView.numberOfRows(inSection: 0)
                
                // Update stored comments based on the new collection data
                strongSelf.storedComment = strongSelf.prepareData()
                
                // Update comment count based on the stored comment count
                strongSelf.commentCount = strongSelf.storedComment.count
                
                // Reload the table view
                strongSelf.commentTableView.reloadData()
                
                // Get the updated number of rows after reloading
                let updatedNumberOfRows = strongSelf.commentTableView.numberOfRows(inSection: 0)
                
                // Check if new comments were added (scroll only in that case)
                if updatedNumberOfRows > initNumberOfRows {
                    // Scroll to the last row if necessary
                    strongSelf.commentTableView.scrollToRow(at: IndexPath(row: updatedNumberOfRows - 1, section: 0), at: .bottom, animated: true)
                }
            }
//            guard let collection = strongSelf.collection else { return }
//            if collection.hasNext {
//                collection.nextPage()
//            }
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
    
    func updateTableViewHeight() {
        if storedComment.count > 5 {
            commentTableViewHeightConstraint.constant = 270
        } else {
            commentTableViewHeightConstraint.constant = commentTableView.contentSize.height
        }
    }
    
    func updateReactionCount(reactionCount: Int) {
        reactionCountLabel.text = String(reactionCount)
    }
}

//Move view when keyboard show and hide
extension LiveStreamPlayerViewController {
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
        reactionRepository.addReaction(reaction, referenceId: referanceId, referenceType: referenceType, completion: completion)
    }
    
    func removeReaction(withReaction reaction: String, referanceId: String, referenceType: AmityReactionReferenceType, completion: AmityRequestCompletion?) {
        reactionRepository.removeReaction(reaction, referenceId: referanceId, referenceType: referenceType, completion: completion)
    }
}

extension LiveStreamPlayerViewController: LiveStreamCommentTableViewCellProtocol {
    func didReactionTap(reaction: String, isLike: Bool) {
        DispatchQueue.main.async { [self] in
            if isLike {
                removeReaction(withReaction: "like", referanceId: reaction, referenceType: .comment) { [weak self] (success, error) in }
            } else {
                addReaction(withReaction: "like", referanceId: reaction, referenceType: .comment) { [weak self] (success, error) in }
            }
        }
    }
}
