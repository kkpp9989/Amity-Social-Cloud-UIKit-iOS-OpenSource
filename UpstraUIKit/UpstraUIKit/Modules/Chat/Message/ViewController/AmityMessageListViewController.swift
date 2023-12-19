//
//  AmityMessageListViewController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 7/7/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit
import AmitySDK
import MobileCoreServices
import AVFoundation
import Photos

public protocol AmityMessageListDataSource: AnyObject {
    func cellForMessageTypes() -> [AmityMessageTypes: AmityMessageCellProtocol.Type]
}

public extension AmityMessageListViewController {
    
    /// The settings of `AmityMessageListViewController`, you can specify this in `.make(...).
    struct Settings {
        /// Set compose bar style. The default value is `ComposeBarStyle.default`.
        public var composeBarStyle = ComposeBarStyle.default
        public var shouldHideAudioButton: Bool = false
        public var shouldShowChatSettingBarButton: Bool = true // [Custom for ONE Krungthai] Open chat setting bar to default
        public var enableConnectionBar: Bool = true
        public init() {
            // Intentionally left empty
        }
        
    }
    
    /// This enum represent compose bar style.
    enum ComposeBarStyle {
        /// The default compose bar that support text / media / audio record input.
        case `default`
        /// The compose bar that support only text input.
        case textOnly
    }
    
}

/// Amity Message List
public final class AmityMessageListViewController: AmityViewController {
    
    public weak var dataSource: AmityMessageListDataSource?
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var messageContainerView: UIView!
    @IBOutlet private var composeBarContainerView: UIView!
    @IBOutlet private var bottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var connectionStatusBar: UIView!
    @IBOutlet weak var connectionStatusBarTopSpace: NSLayoutConstraint!
    @IBOutlet weak var connectionStatusBarHeight: NSLayoutConstraint!
    
	@IBOutlet private var mentionTableView: AmityMentionTableView!
	@IBOutlet private var mentionTableViewHeightConstraint: NSLayoutConstraint!
	
    @IBOutlet private var replyAvatarView: AmityAvatarView!
    @IBOutlet private var replyContentImageView: UIImageView!
    @IBOutlet private var replyDisplayNameLabel: UILabel!
    @IBOutlet private var replyDescLabel: UILabel!
    @IBOutlet private var replyContainerView: UIView!
    @IBOutlet private var replySeparatorContainerView: UIView!
    @IBOutlet private var replyContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var replyCloseViewButton: UIButton!
    
    @IBOutlet private var alertErrorView: UIView!
    @IBOutlet private var alertErrorLabel: UILabel!

    // MARK: - Properties
    private var screenViewModel: AmityMessageListScreenViewModelType!
    private var connectionStatatusObservation: NSKeyValueObservation?
	private var mentionManager: AmityMentionManager?
    private var filePicker: AmityFilePicker?
    private var isFromNotification: Bool = false
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    
    // MARK: - Container View
    private var navigationHeaderViewController: AmityMessageListHeaderView!
    private var messageViewController: AmityMessageListTableViewController!
    private var composeBar: AmityComposeBar!

    // MARK: - Refresh Overlay
    @IBOutlet weak var refreshOverlay: UIView!
    @IBOutlet weak var refreshActivityIndicator: UIActivityIndicatorView!
    
    private var audioRecordingViewController: AmityMessageListRecordingViewController?
    
    private let circular = AmityCircularTransition()
    
    private var settings = Settings()
    
    private var didEnterBackgroundObservation: NSObjectProtocol?
    private var willEnterForegroundObservation: NSObjectProtocol?
    
    private var message: AmityMessageModel?
    
    private var messageId: String?
    
    public var backHandler: (() -> Void)?
    
    // MARK: - View lifecyle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConnectionStatusBar()
        buildViewModel()
        shouldCellOverride()
		
		setupMentionTableView()
        setupFilePicker()
        setupReplyView()
        
        // Set swipe back gesture if from notification
        if isFromNotification {
            setupCustomSwipeBackGesture()
        }
        
        // Initial ONE Krungthai Custom theme
        theme = ONEKrungthaiCustomTheme(viewController: self)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startObserver()
		mentionManager?.delegate = self
		mentionManager?.setColor(AmityColorSet.base, highlightColor: AmityColorSet.primary)
		mentionManager?.setFont(AmityFontSet.body, highlightFont: AmityFontSet.bodyBold)
		
        AmityKeyboardService.shared.delegate = self
        
        bottomConstraint.constant = .zero
        view.endEditing(true)
        
        // Set color navigation bar by custom theme
        theme?.setBackgroundNavigationBar()
        
        // Set default swipe back to disabled if from notification when view will Appear | For from notification case
        if isFromNotification {
            setDefaultSwipeBackGestureEnabled(isEnabled: false) // ** Set to disabled (Temp) **
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AmityAudioPlayer.shared.stop()
		mentionManager?.delegate = nil
        AmityKeyboardService.shared.delegate = nil
        
        screenViewModel.action.toggleKeyboardVisible(visible: false)
        screenViewModel.action.inputSource(for: .default)
        screenViewModel.action.stopReading()
        screenViewModel.action.stopRealtimeSubscription()
        
        AmityAudioPlayer.shared.stop()
        bottomConstraint.constant = .zero
        view.endEditing(true)
        
        // Set default swipe back to enabled when viewWillDisappear | For from notification case
        if isFromNotification {
            setDefaultSwipeBackGestureEnabled(isEnabled: true)
        }
    }
    
    /// Create `AmityMessageListViewController` instance.
    /// - Parameters:
    ///   - channelId: The channel id.
    ///   - settings: Specify the custom settings, or leave to use the default settings.
    /// - Returns: An instance of `AmityMessageListViewController`.
    public static func make(
        channelId: String,
        subChannelId: String,
        settings: AmityMessageListViewController.Settings = .init(),
        messageId: String? = "",
        isFromNotification: Bool = false
    ) -> AmityMessageListViewController {
        let viewModel = AmityMessageListScreenViewModel(channelId: channelId, subChannelId: subChannelId)
        let vc = AmityMessageListViewController(nibName: AmityMessageListViewController.identifier, bundle: AmityUIKitManager.bundle)
        vc.screenViewModel = viewModel
        vc.settings = settings
		vc.mentionManager = AmityMentionManager(withType: .message(channelId: channelId))
        vc.messageId = messageId
        vc.isFromNotification = isFromNotification
        return vc
    }
    
    private func shouldCellOverride() {
        screenViewModel.action.registerCellNibs()
        
        if let dataSource = dataSource {
            screenViewModel.action.register(items: dataSource.cellForMessageTypes())
        }
        messageViewController.setupView()
    }
	
	private func setupMentionTableView() {
		mentionTableView.isHidden = true
		mentionTableView.delegate = self
		mentionTableView.dataSource = self
		mentionTableView.register(AmityMentionTableViewCell.nib, forCellReuseIdentifier: AmityMentionTableViewCell.identifier)
	}
    
    private func setupReplyView() {
        replySeparatorContainerView.backgroundColor = AmityColorSet.secondary.blend(.shade4)
        replyCloseViewButton.setImage(AmityIconSet.iconCloseReply, for: .normal)
        
        replyContentImageView.contentMode = .center
        replyContentImageView.layer.cornerRadius = 4

        replyAvatarView.placeholder = AmityIconSet.defaultAvatar
        replyDisplayNameLabel.font = AmityFontSet.bodyBold
        replyDescLabel.font = AmityFontSet.body
        replyDescLabel.textColor = AmityColorSet.base.blend(.shade3)
    }
    
    private func setupCustomSwipeBackGesture() {
        setDefaultSwipeBackGestureEnabled(isEnabled: false) // ** Set to disabled (Temp) **
        
        let swipeBack = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleCustomSwipeBackAction(_:)))
        swipeBack.edges = .left // Set the edge to recognize the swipe from the left
        view.addGestureRecognizer(swipeBack)
    }
    
    private func setDefaultSwipeBackGestureEnabled(isEnabled: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = isEnabled
    }
    
    private func startObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshPresence(notification:)),
                                               name: Notification.Name("RefreshChannelPresence"),
                                               object: nil)
    }
    
    private func stopObserver() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("RefreshChannelPresence"), object: nil)
    }
    
    @objc func refreshPresence(notification: Notification) {
        DispatchQueue.main.async() { [self] in
            screenViewModel.action.getChannel()
        }
    }
    
    @objc func handleCustomSwipeBackAction(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        // Get width of screen
        let screenWidth = UIScreen.main.bounds.width
        // Get current x position of touch gesture
        let translation = gestureRecognizer.translation(in: view)
        // Set threshold for allow to back
        let swipeThreshold: CGFloat = 0.8
        
        // Check if state == .end, translation.x is more than theshold, is from notification and have back handler
        if gestureRecognizer.state == .ended,
           translation.x >= swipeThreshold * screenWidth,
           isFromNotification,
           let completion = backHandler {
            // Back handler working
            completion()
            // Set default swipe back to enabled
            setDefaultSwipeBackGestureEnabled(isEnabled: true)
        }
    }
}

// MARK: - Action
private extension AmityMessageListViewController {
    
    func cameraTap() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            // Permission has already been granted. Proceed with opening the camera.
            openCamera()
        case .notDetermined:
            // Request camera permission
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    // Permission granted, open the camera
                    self?.openCamera()
                } else {
                    // Permission denied, show an alert to guide the user to settings
                    self?.showPermissionDeniedAlert()
                }
            }
        case .denied, .restricted:
            // Permission is denied or restricted, show an alert to guide the user to settings
            showPermissionDeniedAlert()
        @unknown default:
            break
        }
    }
    
    func showPermissionDeniedAlert() {
        DispatchQueue.main.async { [self] in
            let alert = UIAlertController(title: "Camera Permission Denied", message: "To use the camera, please enable camera access in Settings.", preferredStyle: .alert)
            
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            alert.addAction(settingsAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            
            present(alert, animated: true, completion: nil)
        }
    }

    func openCamera() {
        DispatchQueue.main.async {
            let cameraPicker = UIImagePickerController()
            cameraPicker.sourceType = .camera
            cameraPicker.videoQuality = .typeHigh
            cameraPicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
            cameraPicker.delegate = self
            self.present(cameraPicker, animated: true, completion: nil)
        }
    }
    
    func albumTap() {
        let imagePicker = AmityImagePickerPreviewController(selectedAssets: [])
        imagePicker.settings.theme.selectionStyle = .checked
        imagePicker.settings.fetch.assets.supportedMediaTypes = [.image]
        imagePicker.settings.selection.max = 20
        imagePicker.settings.selection.unselectOnReachingMax = false
        imagePicker.settings.theme.selectionStyle = .numbered
        presentAmityUIKitImagePickerPreview(imagePicker, select: nil, deselect: nil, cancel: nil, finish: { [weak self] assets in
//            let media = assets.map { asset in
//                AmityMedia(state: .image(self?.getAssetThumbnail(asset: asset) ?? UIImage()), type: .image)
//            }
            
            let medias = assets.map { AmityMedia(state: .localAsset($0), type: .image) }
            
            let vc = PreviewImagePickerController.make(media: medias,
                                                       viewModel: (self?.screenViewModel)!,
                                                       mediaType: .image,
                                                       title: AmityLocalizedStringSet.General.selectedImages.localizedString,
                                                       asset: assets)
            vc.modalPresentationStyle = .fullScreen
            vc.tabBarController?.tabBar.isHidden = true
            imagePicker.present(vc, animated: false, completion: nil)
        })
    }
    
    func videoAlbumTap() {
        let imagePicker = AmityImagePickerPreviewController(selectedAssets: [])
        imagePicker.settings.theme.selectionStyle = .checked
        imagePicker.settings.fetch.assets.supportedMediaTypes = [.video]
        imagePicker.settings.selection.max = 10
        imagePicker.settings.selection.unselectOnReachingMax = false
        imagePicker.settings.theme.selectionStyle = .numbered
        presentAmityUIKitImagePickerPreview(imagePicker, select: nil, deselect: nil, cancel: nil, finish: { [weak self] assets in
            let medias = assets.map { AmityMedia(state: .localAsset($0), type: .video) }
            let vc = PreviewImagePickerController.make(media: medias,
                                                       viewModel: (self?.screenViewModel)!,
                                                       mediaType: .video,
                                                       title: AmityLocalizedStringSet.General.selectedVideos.localizedString,
                                                       asset: assets)
            vc.modalPresentationStyle = .fullScreen
            vc.tabBarController?.tabBar.isHidden = true
            imagePicker.present(vc, animated: false, completion: nil)
        })
    }
    
    func getAssetThumbnail(asset: PHAsset) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var thumbnail = UIImage()
        option.isSynchronous = true
        manager.requestImage(for: asset, targetSize: CGSize(width: 100.0, height: 100.0), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
                thumbnail = result!
        })
        return thumbnail
    }
    
    func fileTap() {
        filePicker?.present(from: UIView(), files: [])
    }
    
    func locationTap() {
        
    }
    
    @IBAction func closeReplyContainerTap(_ sender: UIButton) {
        hideReplyContainerView()
    }
    
    private func openAssetPreviewController(_ selectedAssets: [PHAsset]) {
        let previewController = AssetPreviewViewController()
        previewController.assets = selectedAssets
        previewController.modalPresentationStyle = .overFullScreen
        previewController.didFinishPickingAsset = { assets in
            let medias = assets.map { asset in
                return AmityMedia(state: .localAsset(asset), type: .image)
            }
            self.screenViewModel.action.send(withMedias: medias, type: .image)
        }
        self.present(previewController, animated: true, completion: nil)
    }

}

// MARK: - Setup File picker
private extension AmityMessageListViewController {
    func setupFilePicker() {
        filePicker = AmityFilePicker(presentationController: self, delegate: self)
    }
}

// MARK: - Setup View
private extension AmityMessageListViewController {
    
    func setupView() {
        view.backgroundColor = AmityColorSet.backgroundColor
        setRefreshOverlay(visible: false)
        setupCustomNavigationBar()
        setupMessageContainer()
        setupComposeBarContainer()
        setupAudioRecordingView()
        setupAlertView()
    }
    
    func setupCustomNavigationBar() {
        if settings.shouldShowChatSettingBarButton {
            // Just using the view form this
            navigationBarType = .custom
            navigationHeaderViewController = AmityMessageListHeaderView(viewModel: screenViewModel)
            let item = UIBarButtonItem(customView: navigationHeaderViewController)
            navigationItem.leftBarButtonItem = item
            let image = AmityIconSet.Chat.iconSetting
            let barButton = UIBarButtonItem(image: image,
                                            style: .plain,
                                            target: self,
                                            action: #selector(didTapSetting))
            navigationItem.rightBarButtonItem = barButton
        }
    }
    
    func setupConnectionStatusBar() {
        
        if !settings.enableConnectionBar {
            connectionStatusBar.isHidden = true
            return
        }
        
        updateConnectionStatusBar(animated: false)
        
        // Start observing connection status to update the UI.
        observeConnectionStatus()
        
        // When we go background, the connection status update might notify, but we don't care.
        // Since we can't update the UI.
        didEnterBackgroundObservation = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] notification in
            self?.unobserveConnectionStatus()
        }
        
        // When the app enter foreground, we now re-observe connection status, to update the UI.
        willEnterForegroundObservation = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] notification in
            self?.updateConnectionStatusBar(animated: false)
            self?.observeConnectionStatus()
        }
        
    }
    
    private func observeConnectionStatus() {
        connectionStatatusObservation = Reachability.shared.observe(\.isConnectedToNetwork, options: [.initial]) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.updateConnectionStatusBar(animated: true)
            }
        }
    }
    
    private func unobserveConnectionStatus() {
        connectionStatatusObservation = nil
    }
    
    private func setupAlertView() {
        alertErrorView.alpha = 0
        alertErrorView.backgroundColor = .black.withAlphaComponent(0.8)
        alertErrorView.layer.cornerRadius = 4
        alertErrorView.clipsToBounds = true
        
        alertErrorLabel.text = "Unable to send link This link isn't allowed in this chat."
        alertErrorLabel.font = AmityFontSet.bodyBold
        alertErrorLabel.textColor = AmityColorSet.baseInverse
    }
    
    private func updateConnectionStatusBar(animated: Bool) {
        var barVisibilityIsUpdate = false
        let barIsShowing = (connectionStatusBarTopSpace.constant == -connectionStatusBarHeight.constant)
        if Reachability.shared.isConnectedToNetwork {
            // online
            if !barIsShowing {
                connectionStatusBarTopSpace.constant = -connectionStatusBarHeight.constant
                view.setNeedsLayout()
                barVisibilityIsUpdate = true
            }
        } else {
            // not online
            if barIsShowing {
                connectionStatusBarTopSpace.constant = 0
                view.setNeedsLayout()
                barVisibilityIsUpdate = true
            }
        }
        if barVisibilityIsUpdate, animated {
            UIView.animate(withDuration: 0.15, animations: { [weak self] in
                self?.view.layoutIfNeeded()
            }, completion: nil)
        }
        
    }
    
    private func setRefreshOverlay(visible: Bool) {
        refreshOverlay.isHidden = !visible
        if visible {
            refreshActivityIndicator.startAnimating()
        } else {
            refreshActivityIndicator.stopAnimating()
        }
    }
    
    @objc func didTapSetting() {
        let vc = AmityChatSettingsViewController.make(channelId: screenViewModel.dataSource.getChannelId())
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func setupMessageContainer() {
        messageViewController = AmityMessageListTableViewController.make(viewModel: screenViewModel)
        addContainerView(messageViewController, to: messageContainerView)
    }
    
    func setupComposeBarContainer() {
        // Switch compose bar view controller based on styling.
        let composeBarViewController: UIViewController & AmityComposeBar
        switch settings.composeBarStyle {
        case .default:
            composeBarViewController = AmityMessageListComposeBarViewController.make(
				viewModel: screenViewModel,
				setting: settings,
				delegate: self)
        case .textOnly:
            composeBarViewController = AmityComposeBarOnlyTextViewController.make(
				viewModel: screenViewModel,
				delegate: self)
        }
        
        // Manage view controller
        addContainerView(composeBarViewController, to: composeBarContainerView)
        
        // Keep reference to the AmityComposeBar
        composeBar = composeBarViewController
        
        composeBar.selectedMenuHandler = { [weak self] menu in
            self?.view.endEditing(true)
            switch menu {
            case .camera:
                self?.cameraTap()
            case .album:
                self?.albumTap()
            case .file:
                self?.fileTap()
            case .location:
                self?.locationTap()
            case .videoAlbum:
                self?.videoAlbumTap()
            }
        }
        
    }
    
    func setupAudioRecordingView() {
        
        let screenSize = UIScreen.main.bounds
        audioRecordingViewController = AmityMessageListRecordingViewController.make()
        audioRecordingViewController?.presenter = self
        circular.duration = 0.3
        circular.startingPoint = CGPoint(x: screenSize.width / 2, y: screenSize.height)
        circular.circleColor = UIColor.black.withAlphaComponent(0.70)
        circular.presentedView = audioRecordingViewController?.view
        
        audioRecordingViewController?.finishRecordingHandler = { [weak self] state in
            switch state {
            case .finish:
                self?.circular.hide()
                self?.screenViewModel.action.sendAudio()
            case .finishWithMaximumTime:
                self?.circular.hide()
                self?.alertMaxAudio()
            case .notFinish:
                break
            case .timeTooShort:
                self?.circular.hide()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self?.composeBar.showPopoverMessage()
                }
            case .deleteAndClose:
                self?.circular.hide()
            }
        }
        
        composeBar.deletingTarget = audioRecordingViewController?.deleteButton
        
    }
    
}

extension AmityMessageListViewController {
    
    func alertMaxAudio() {
        let alert = UIAlertController(title: "Voice Recording Stopped", message: "The Maximum length for this voice message is 59 minutes.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] action in
            self?.screenViewModel.action.sendAudio()
            Log.add("finishWithMaximumTime")
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
}

// MARK: - Binding ViewModel
private extension AmityMessageListViewController {
    func buildViewModel() {
        screenViewModel.delegate = self
        screenViewModel.action.getChannel()
        screenViewModel.action.getSubChannel()
        screenViewModel.action.getTotalUnreadCount()
    }
}

extension AmityMessageListViewController: AmityKeyboardServiceDelegate {
    func keyboardWillChange(service: AmityKeyboardService, height: CGFloat, animationDuration: TimeInterval) {
        
        let offset = height > 0 ? view.safeAreaInsets.bottom : 0
        bottomConstraint.constant = -height + offset
        
        view.setNeedsUpdateConstraints()
        view.layoutIfNeeded()
        
        if height == 0 {
            screenViewModel.action.toggleKeyboardVisible(visible: false)
            screenViewModel.action.inputSource(for: .default)
        } else {
            screenViewModel.action.toggleKeyboardVisible(visible: true)
            screenViewModel.shouldScrollToBottom(force: true)
        }
    }
}

extension AmityMessageListViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
//    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//
//        guard let image = info[.originalImage] as? UIImage else { return }
//
//        picker.dismiss(animated: true) { [weak self] in
//            do {
//                let resizedImage = image
//                    .scalePreservingAspectRatio()
//                let media = AmityMedia(state: .image(resizedImage), type: .image)
//                self?.screenViewModel.action.send(withMedias: [media], type: .image)
//            } catch {
//                Log.add(error.localizedDescription)
//            }
//        }
//    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let mediaType = info[.mediaType] as? String else {
            return
        }
        
        var selectedMedia: AmityMedia?
        
        switch mediaType {
        case String(kUTTypeImage):
            if let image = info[.originalImage] as? UIImage {
                selectedMedia = AmityMedia(state: .image(image), type: .image)
            }
        case String(kUTTypeMovie):
            if let mediaURL = info[.mediaURL] as? URL {
                let media = AmityMedia(state: .localURL(url: mediaURL), type: .video)
                media.localUrl = mediaURL
                
                if let thumbnailImage = generateThumbnailImage(fromVideoAt: mediaURL) {
                    media.generatedThumbnailImage = thumbnailImage
                }
                
                selectedMedia = media
            }
        default:
            assertionFailure("Unsupported media type")
            break
        }
        
        // We want to process selected media only after the default UI for selecting media
        // dismisses completely. Otherwise, we see `Attempt to present ....` error
        picker.dismiss(animated: true) { [weak self] in
            guard let media = selectedMedia else { return }
            self?.screenViewModel.action.send(withMedias: [media], type: media.type)
        }
    }
    
    func generateThumbnailImage(fromVideoAt url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 1.0, preferredTimescale: 1)
        var actualTime: CMTime = CMTime.zero
        
        do {
            let imageRef = try assetImageGenerator.copyCGImage(at: time, actualTime: &actualTime)
            return UIImage(cgImage: imageRef)
        } catch {
            print("Unable to generate thumbnail image for kUTTypeMovie.")
            return nil
        }
    }

}

extension AmityMessageListViewController: AmityMessageListScreenViewModelDelegate {
    
    func screenViewModelAudioRecordingEvents(for events: AmityMessageListScreenViewModel.AudioRecordingEvents) {
        switch events {
        case .show:
            composeBar.isTimeout = false
            let keyWindow = UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }
            guard let window = keyWindow else { return }
            AmityAudioPlayer.shared.stopAudio()
            circular.show(for: window)
        case .permissionDenied:
            let alertTitle = AmityLocalizedStringSet.MessageList.alertMicrophoneDisabledTitle.localizedString
            let description = AmityLocalizedStringSet.MessageList.alertMicrophoneDisabledDesc.localizedString
            
            AmityAlertController.present(
                title: alertTitle,
                message: description,
                actions: [.cancel(handler: nil), .custom(title: AmityLocalizedStringSet.General.openSettings.localizedString, style: .default, handler: {
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) else { return }
                    UIApplication.shared.open(settingsUrl)
                })],
                from: self)
        case .hide:
            circular.hide()
            audioRecordingViewController?.stopRecording()
        case .deleting:
            audioRecordingViewController?.deletingRecording()
        case .cancelingDelete:
            audioRecordingViewController?.cancelingDelete()
        case .delete:
            circular.hide()
            audioRecordingViewController?.deleteRecording()
        case .record:
            circular.hide()
            audioRecordingViewController?.stopRecording()
        case .timeoutRecord:
            circular.hide()
            screenViewModel.action.sendAudio()
            composeBar.isTimeout = true
        }
    }
    
    func screenViewModelRoute(route: AmityMessageListScreenViewModel.Route) {
        switch route {
        case .pop:
            if isFromNotification,
               let completion = backHandler {
                completion()
            } else {
                navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func screenViewModelShouldUpdateScrollPosition(to indexPath: IndexPath) {
        messageViewController.updateScrollPosition(to: indexPath)
    }
    
    func screenViewModelDidGetChannel(channel: AmityChannelModel) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            let isOnline = AmityUIKitManager.checkOnlinePresence(channelId: channel.channelId)
            navigationHeaderViewController?.updateViews(channel: channel, isOnline: isOnline)
        }
        
        if channel.object.currentUserMembership != .member {
            composeBar.showJoinMenuButton(show: true)
            
            if #available(iOS 16.0, *) {
                // iOS 16.0 and newer
                navigationItem.rightBarButtonItem?.isHidden = true
            } else {
                // iOS version prior to 16.0
                navigationItem.rightBarButtonItem = nil // Hide the right bar button item
            }
        }
        
        // Update interaction of compose bar view
        if channel.isMuted || channel.isDeleted {
            composeBar.updateViewDidMuteOrStopChannelStatusChanged(isCanInteract: false)
        } else {
            composeBar.updateViewDidMuteOrStopChannelStatusChanged(isCanInteract: true)
        }
    }
    
    func screenViewModelScrollToBottom(for indexPath: IndexPath) {
        messageViewController.scrollToBottom(indexPath: indexPath)
    }
    
    func screenViewModelDidTextChange(text: String) {
        composeBar.updateViewDidTextChanged(text)
    }
    
    func screenViewModelKeyboardInputEvents(for events: AmityMessageListScreenViewModel.KeyboardInputEvents) {
        switch events {
        case .default:
            composeBar.rotateMoreButton(canRotate: false)
        case .composeBarMenu:
            composeBar.rotateMoreButton(canRotate: true)
        default:
            break
        }
    }
    
    func screenViewModelLoadingState(for state: AmityLoadingState) {
        switch state {
        case .loading:
            messageViewController.showBottomIndicator()
        case .loaded, .initial:
            messageViewController.hideBottomIndicator()
        }
    }
    
    func screenViewModelEvents(for events: AmityMessageListScreenViewModel.Events) {
        switch events {
        case .updateMessages(let isScrollUp):
            let offset = messageViewController.tableView.contentOffset.y
            let contentHeight = messageViewController.tableView.contentSize.height
            
            messageViewController.tableView.reloadData()
            messageViewController.tableView.layoutIfNeeded()

            let newcontentHeight = self.messageViewController.tableView.contentSize.height
            let newOffset = (newcontentHeight - contentHeight) + offset
            if isScrollUp {
                self.messageViewController.tableView.setContentOffset(CGPoint(x: 0, y: newOffset), animated: false)
            }
            
            if let messageId = messageId, !messageId.isEmpty {
                self.messageId = ""
                screenViewModel.action.jumpToMessageId(messageId)
            }
        case .didSendText:
            screenViewModel.shouldScrollToBottom(force: true)
        case .didEditText:
            break
        case .didDelete(let indexPath):
            messageViewController.tableView.reloadRows(at: [indexPath], with: .none)
        case .didSendImage:
            break
        case .didUploadImage:
            break
        case .didDeleteErrorMessage:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: { // Delay to show HUD from press button from custom edit menu view
                AmityHUD.show(.success(message: AmityLocalizedStringSet.HUD.deleted.localizedString))
            })
        case .didSendAudio:
            break
        case .didSendTextError(let error):
            if error.isAmityErrorCode(.linkNotAllowed) {
                alertErrorLabel.text = "Unable to send link This link isn't allowed in this chat."
                alertViewFadeIn()
            } else {
                alertErrorLabel.text = "Can't send the message"
                alertViewFadeIn()
            }
        }
    }
    
    func alertViewFadeIn() {
        UIView.animate(withDuration: 0.2) {
            self.alertErrorView.alpha = 1
        } completion: { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.alertViewFadeOut()
        }
    }
    
    func alertViewFadeOut() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let strongSelf = self else { return }
            UIView.animate(withDuration: 0.2) {
                strongSelf.alertErrorView.alpha = 0
            }
        }
    }
    
    func screenViewModelCellEvents(for events: AmityMessageListScreenViewModel.CellEvents) {
        
        switch events {
        case .edit(let indexPath):
            guard let message = screenViewModel.dataSource.message(at: indexPath),
                  let text = message.text else { return }
            
            let editTextVC = AmityEditTextViewController.make(text: text, editMode: .editMessage)
            editTextVC.title = AmityLocalizedStringSet.editMessageTitle.localizedString
            editTextVC.dismissHandler = {
                editTextVC.dismiss(animated: true, completion: nil)
            }
            editTextVC.editHandler = { [weak self] newMessage, metadata, mentionees in
                self?.screenViewModel.action.editText(
					with: newMessage,
					messageId: message.messageId,
					metadata: metadata,
					mentionees: mentionees)
            }
            let nav = UINavigationController(rootViewController: editTextVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
        case .delete(let indexPath):
            guard let message = screenViewModel.dataSource.message(at: indexPath) else { return }
            let alertViewController = UIAlertController(title: AmityLocalizedStringSet.MessageList.alertDeleteTitle.localizedString,
                                                        message: AmityLocalizedStringSet.MessageList.alertDeleteDesc.localizedString, preferredStyle: .alert)
            let cancel = UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel, handler: nil)
            let delete = UIAlertAction(title: AmityLocalizedStringSet.General.unsend.localizedString, style: .destructive, handler: { [weak self] _ in
                self?.screenViewModel.action.delete(withMessage: message, at: indexPath)
            })
            alertViewController.addAction(cancel)
            alertViewController.addAction(delete)
            present(alertViewController, animated: true)
        case .deleteErrorMessage(let indexPath):
            guard let message = screenViewModel.dataSource.message(at: indexPath) else { return }
            screenViewModel.action.deleteErrorMessage(with: message.messageId, at: indexPath, isFromResend: false)
        case .report(let indexPath):
            screenViewModel.action.reportMessage(at: indexPath)
        case .imageViewer(let indexPath, let imageView):
            guard let message = screenViewModel.dataSource.message(at: indexPath) else { return }
            AmityUIKitManagerInternal.shared.messageMediaService.downloadImageForMessage(message: message.object, size: .full, progress: nil) { [weak self] (result) in
                switch result {
                case .success(let image):
                    let photoViewerVC = AmityPhotoViewerController(referencedView: imageView, image: image)
                    self?.present(photoViewerVC, animated: true, completion: nil)
                case .failure:
                    break
                }
            }
        case .videoViewer(let indexPath):
            guard let message = screenViewModel.dataSource.message(at: indexPath) else { return }
            if let videoInfo = message.object.getVideoInfo() {
                if let fileUrl = videoInfo.getVideo(resolution: .original), let url = URL(string: fileUrl) {
                    presentVideoPlayer(at: url)
                } else if let url = URL(string: videoInfo.fileURL ) {
                    presentVideoPlayer(at: url)
                }
            } else {
                print("unable to find video url for message: \(message.messageId)")
            }
        case .fileDownloader(let indexPath):
            guard let message = screenViewModel.dataSource.message(at: indexPath) else { return }
            if let fileInfo = message.object.getFileInfo() {
                AmityHUD.show(.loading)
                AmityUIKitManagerInternal.shared.fileService.loadFile(fileURL: fileInfo.fileURL) { result in
                    switch result {
                    case .success(let data):
                        AmityHUD.hide {
                            let tempUrl = data.write(withName: fileInfo.fileName)
                            let documentPicker = UIDocumentPickerViewController(url: tempUrl, in: .exportToService)
                            documentPicker.modalPresentationStyle = .fullScreen
                            self.present(documentPicker, animated: true, completion: nil)
                        }
                    case .failure:
                        AmityHUD.hide()
                    }
                }
            } else {
                print("unable to find file for message: \(message.messageId)")
            }
        case .forward(indexPath: let indexPath):
            messageViewController.updateEditMode(isEdit: true, indexPath: indexPath)
            composeBar.showForwardMenuButton(show: true)
        case .copy(indexPath: let indexPath):
            guard let message = screenViewModel.dataSource.message(at: indexPath) else { return }
            UIPasteboard.general.string = message.text
        case .reply(indexPath: let indexPath):
            guard let message = screenViewModel.dataSource.message(at: indexPath) else { return }
            setReplyContainerView(message)
            showReplyContainerView()
            composeBar.prepareTypingText()
        case .jumpReply(indexPath: let indexPath):
            guard let message = screenViewModel.dataSource.message(at: indexPath) else { return }
            screenViewModel.action.jumpToMessageId(message.parentId ?? "")
        case .avatar(indexPath: let indexPath):
            guard let message = screenViewModel.dataSource.message(at: indexPath) else { return }
            AmityEventHandler.shared.userDidTap(from: self, userId: message.userId)
        case .openEditMenu(indexPath: let indexPath, sourceView: let sourceView, sourceTableViewCell: let sourceTableViewCell, options: let itemsMenu):
            var text: String?
            if let message = screenViewModel.dataSource.message(at: indexPath) {
                text = message.text
            }
            AmityEditMenuView.present(options: itemsMenu, sourceViewController: self, sourceMessageView: sourceView, sourceTableViewCell: sourceTableViewCell, selectedText: text, indexPath: indexPath)
        case .openResendMenu(indexPath: let indexPath): // [Deprecated] Use .openEditMenu instead
            guard let message = screenViewModel.dataSource.message(at: indexPath) else { return }
            let alertViewController = UIAlertController(title: AmityLocalizedStringSet.MessageList.alertErrorMessageTitle.localizedString,
                                                        message: nil, preferredStyle: .actionSheet)
            let cancel = UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel, handler: nil)
            let delete = UIAlertAction(title: AmityLocalizedStringSet.General.delete.localizedString, style: .destructive, handler: { [weak self] _ in
                self?.screenViewModel.action.deleteErrorMessage(with: message.messageId, at: indexPath, isFromResend: false)
            })
            let resend = UIAlertAction(title: AmityLocalizedStringSet.General.resend.localizedString, style: .default, handler: { [weak self] _ in
                self?.screenViewModel.action.resend(with: message, at: indexPath)
            })
            alertViewController.addAction(cancel)
            alertViewController.addAction(resend)
            alertViewController.addAction(delete)
            present(alertViewController, animated: true)
        case .resend(indexPath: let indexPath):
            guard let message = screenViewModel.dataSource.message(at: indexPath) else { return }
            screenViewModel.action.resend(with: message, at: indexPath)
        }
    }
    
    func screenViewModelToggleDefaultKeyboardAndAudioKeyboard(for events: AmityMessageListScreenViewModel.KeyboardInputEvents) {
        switch events {
        case .default:
            composeBar.showRecordButton(show: false)
        case .audio:
            composeBar.showRecordButton(show: true)
        default:
            break
        }
        screenViewModel.action.toggleKeyboardVisible(visible: false)
        view.endEditing(true)
    }
    
    func screenViewModelDidReportMessage(at indexPath: IndexPath, isFlag: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: { [weak self] in // Delay to show HUD from press button from custom edit menu view
            self?.messageViewController.tableView.reloadRows(at: [indexPath], with: .none)
            AmityHUD.show(.success(message: isFlag ? AmityLocalizedStringSet.HUD.reportSent.localizedString : AmityLocalizedStringSet.HUD.unreportSent.localizedString))
        })
    }
    
    func screenViewModelDidFailToReportMessage(at indexPath: IndexPath, with error: Error?) {
        // Intentionally left empty
    }
    
    func screenViewModelIsRefreshing(_ isRefreshing: Bool) {
        setRefreshOverlay(visible: isRefreshing)
    }
	
	func screenViewModelDidTapOnMention(with userId: String) {
		AmityEventHandler.shared.userDidTap(from: self, userId: userId)
	}
    
    func screenViewModelDidUpdateForwardMessageList(amountForwardMessageList: Int) {
        composeBar.updateViewDidSelectForwardMessage(amount: amountForwardMessageList)
    }

    func screenViewModelDidJumpToTarget(with messageId: String) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            if let indexPath = strongSelf.screenViewModel.dataSource.findIndexPath(forMessageId: messageId) {
                let numberOfSections = strongSelf.messageViewController.tableView.numberOfSections
                let numberOfRows = strongSelf.messageViewController.tableView.numberOfRows(inSection: indexPath.section)
                
                if indexPath.section < numberOfSections && indexPath.row < numberOfRows {
                    strongSelf.messageViewController.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                    strongSelf.shakeCell(at: indexPath)
                }
            }
        }
    }

    func screenViewModelDidUpdateJoinChannelSuccess() {
        composeBar.showJoinMenuButton(show: false)
        setupCustomNavigationBar()
        screenViewModel.action.getMessage()
    }
}

// MARK: - UITableViewDataSource
extension AmityMessageListViewController: UITableViewDataSource {
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return mentionManager?.users.count ?? 1
	}
	
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: AmityMentionTableViewCell.identifier) as? AmityMentionTableViewCell, let model = mentionManager?.item(at: indexPath) else { return UITableViewCell() }
		cell.display(with: model)
		return cell
	}
}

// MARK: - UITableViewDelegate
extension AmityMessageListViewController: UITableViewDelegate {
	public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return AmityMentionTableViewCell.height
	}
	
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		mentionManager?.addMention(from: composeBar.textView, in: composeBar.textView.text, at: indexPath)
	}
	
	public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if tableView.isBottomReached {
			mentionManager?.loadMore()
		}
	}
}

// MARK: - AmityMentionManagerDelegate
extension AmityMessageListViewController: AmityMentionManagerDelegate {
	public func didGetHashtag(keywords: [AmityHashtagModel]) {
		// do something
	}
	
	public func didCreateAttributedString(attributedString: NSAttributedString) {
		composeBar.textView.attributedText = attributedString
		composeBar.textView.typingAttributes = [.font: AmityFontSet.body, .foregroundColor: AmityColorSet.base]
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
	
	public func didMentionsReachToMaximumLimit() {
		let alertController = UIAlertController(title: AmityLocalizedStringSet.Mention.unableToMentionTitle.localizedString, message: AmityLocalizedStringSet.Mention.unableToMentionReplyDescription.localizedString, preferredStyle: .alert)
		let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.done.localizedString, style: .cancel, handler: nil)
		alertController.addAction(cancelAction)
		present(alertController, animated: true, completion: nil)
	}
	
	public func didCharactersReachToMaximumLimit() {
		showAlertForMaximumCharacters()
	}
	
	func showAlertForMaximumCharacters() {
		let alertController = UIAlertController(title: AmityLocalizedStringSet.Mention.unableToMentionTitle.localizedString, message: AmityLocalizedStringSet.Mention.unableToMentionReplyDescription.localizedString, preferredStyle: .alert)
		let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.done.localizedString, style: .cancel, handler: nil)
		alertController.addAction(cancelAction)
		present(alertController, animated: true, completion: nil)
	}
}

extension AmityMessageListViewController: AmityMessageListComposeBarDelegate, AmityComposeBarOnlyTextDelegate {
    
	func composeView(_ view: AmityTextComposeBarView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		if view.textView.text.count > AmityMentionManager.maximumCharacterCountForPost {
			showAlertForMaximumCharacters()
			return false
		}
		return mentionManager?.shouldChangeTextIn(view.textView, inRange: range, replacementText: text, currentText: view.textView.text) ?? true
	}
	
	func composeViewDidChangeSelection(_ view: AmityTextComposeBarView) {
		mentionManager?.changeSelection(view.textView)
	}
    
    func composeViewDidCancelForwardMessage() {
        messageViewController.updateEditMode(isEdit: false)
        screenViewModel.action.resetDataInForwardMessageList()
    }
    
    func composeViewDidSelectForwardMessage() {
        AmityChannelEventHandler.shared.channelOpenChannelListForForwardMessage(from: self) { selectedChannels in
            print(selectedChannels)
            self.screenViewModel.action.checkChannelId(withSelectChannel: selectedChannels)
            self.messageViewController.updateEditMode(isEdit: false)
            self.composeBar.showForwardMenuButton(show: false)
        }
    }
    
    func composeViewDidSelectJoinChannel() {
        screenViewModel.action.join()
    }
	
	func sendMessageTap() {
		let metadata = mentionManager?.getMetadata()
        let mentionees = mentionManager?.getMentionees()
        if let message = self.message {
            hideReplyContainerView()
            screenViewModel.action.reply(withText: composeBar.textView.text,
                                         parentId: message.messageId,
                                         metadata: metadata,
                                         mentionees: mentionees,
                                         type: message.messageType)
        } else {
            screenViewModel.action.send(withText: composeBar.textView.text,
                                        metadata: metadata,
                                        mentionees: mentionees)
        }
		mentionManager?.resetState()
	}
}

extension AmityMessageListViewController: AmityFilePickerDelegate {
    func didPickFiles(files: [AmityFile]) {
        screenViewModel.action.send(withFiles: files)
    }
}

extension AmityMessageListViewController {
    private func setReplyContainerView(_ message: AmityMessageModel) {
        self.message = message
        
        let url = message.object.user?.getAvatarInfo()?.fileURL
        replyAvatarView.setImage(withImageURL: url, placeholder: AmityIconSet.defaultAvatar)
        
        var displayName = ""
        if message.isOwner {
            displayName = "Reply to Yourself"
        } else {
            displayName = "Reply to " + (message.object.user?.displayName ?? "Anonymous")
        }
        replyDisplayNameLabel.text = displayName
        
        if message.messageType == .image {
            AmityUIKitManagerInternal.shared.messageMediaService.downloadImageForMessage(message: message.object, size: .medium) { [weak self] in
                self?.replyContentImageView.image = AmityIconSet.defaultMessageImage
            } completion: { [weak self] result in
                switch result {
                case .success(let image):
                    // To check if the image going to assign has the correct index path.
                    self?.replyContentImageView.image = image
                    self?.replyContentImageView.contentMode = .scaleAspectFill
                    self?.replyContentImageView.isHidden = false
                case .failure:
                    self?.replyContentImageView.image = AmityIconSet.defaultMessageImage
                    self?.replyContentImageView.isHidden = true
                    self?.replyContentImageView.contentMode = .center
                }
            }
            replyDescLabel.text = "Image"
        } else if message.messageType == .video {
            if let thumbnailInfo = message.object.getVideoThumbnailInfo() {
                // Set video thumbnail
                replyContentImageView.isHidden = false
                replyContentImageView.loadImage(with: thumbnailInfo.fileURL, size: .medium, placeholder: AmityIconSet.videoThumbnailPlaceholder, optimisticLoad: true)
                replyContentImageView.contentMode = .scaleAspectFill
            }
            replyDescLabel.text = "Video"
        } else if message.messageType == .file {
            if let fileInfo = message.object.getFileInfo() {
                let file = AmityFile(state: .downloadable(fileData: fileInfo))
                replyContentImageView.image = file.fileIcon
                replyContentImageView.isHidden = false
                replyContentImageView.contentMode = .center
            } else {
                replyContentImageView.isHidden = true
            }
            replyDescLabel.text = "File"
        } else if message.messageType == .audio {
            replyContentImageView.tintColor = AmityColorSet.base
            replyContentImageView.isHidden = false
            replyContentImageView.image = AmityIconSet.Chat.iconPlay
            replyContentImageView.contentMode = .center
            replyDescLabel.text = "Voice message"
        } else {
            replyContentImageView.isHidden = true
            replyDescLabel.text = message.text
        }
    }
    
    private func showReplyContainerView() {
        UIView.animate(withDuration: 0.3) {
            self.replyContainerViewHeightConstraint.constant = 55
            self.replyContainerView.isHidden = false
        }
        
        composeBar.updateViewDidReplyProcess(isReplying: true)
    }
    
    private func hideReplyContainerView() {
        UIView.animate(withDuration: 0.3) {
            self.replyContainerViewHeightConstraint.constant = 0
            self.replyContainerView.isHidden = true
            self.message = nil
        }
        
        composeBar.updateViewDidReplyProcess(isReplying: false)
    }
    
    func shakeCell(at indexPath: IndexPath) {
        guard let cell = messageViewController.tableView.cellForRow(at: indexPath) else {
            return
        }
        
        // Define the horizontal translation animation
        let shake = CABasicAnimation(keyPath: "position.x")
        shake.duration = 0.1
        shake.repeatCount = 4 // Number of times to repeat the animation
        shake.autoreverses = true
        shake.fromValue = cell.layer.position.x - 5 // Adjust the value to control the distance of the shake
        shake.toValue = cell.layer.position.x + 5 // Adjust the value to control the distance of the shake
        
        // Apply the animation to the cell's layer
        cell.layer.add(shake, forKey: "cellShakeAnimation")
    }
}

// MARK: - For popover view of AmityEditMenuView
extension AmityMessageListViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // Post notification to Notification.Name.View.didDismiss observer in AmityResponsiveView
        NotificationCenter.default.post(name: Notification.Name.View.didDismiss, object: nil)
    }

}
