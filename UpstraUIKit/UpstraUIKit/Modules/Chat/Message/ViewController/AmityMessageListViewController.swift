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
    @IBOutlet private var replyContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var replyCloseViewButton: UIButton!
    
    // MARK: - Properties
    private var screenViewModel: AmityMessageListScreenViewModelType!
    private var connectionStatatusObservation: NSKeyValueObservation?
	private var mentionManager: AmityMentionManager?
    private var filePicker: AmityFilePicker?
    
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
        
        // Initial ONE Krungthai Custom theme
        theme = ONEKrungthaiCustomTheme(viewController: self)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
		mentionManager?.delegate = self
		mentionManager?.setColor(AmityColorSet.base, highlightColor: AmityColorSet.primary)
		mentionManager?.setFont(AmityFontSet.body, highlightFont: AmityFontSet.bodyBold)
		
        AmityKeyboardService.shared.delegate = self
        
        bottomConstraint.constant = .zero
        view.endEditing(true)
        
        // Set color navigation bar by custom theme
        theme?.setBackgroundNavigationBar()
        
        /* [Custom for ONE Krungthai] Hide tabber when open chat detail view */
        tabBarController?.tabBar.isHidden = true
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AmityAudioPlayer.shared.stop()
		mentionManager?.delegate = nil
        AmityKeyboardService.shared.delegate = nil
        
        screenViewModel.action.toggleKeyboardVisible(visible: false)
        screenViewModel.action.inputSource(for: .default)
        screenViewModel.action.stopReading()
        
        AmityAudioPlayer.shared.stop()
        bottomConstraint.constant = .zero
        view.endEditing(true)
        
        /* [Custom for ONE Krungthai] Hide tabber when go to another view */
        tabBarController?.tabBar.isHidden = false
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
        messageId: String? = ""
    ) -> AmityMessageListViewController {
        let viewModel = AmityMessageListScreenViewModel(channelId: channelId, subChannelId: subChannelId)
        let vc = AmityMessageListViewController(nibName: AmityMessageListViewController.identifier, bundle: AmityUIKitManager.bundle)
        vc.screenViewModel = viewModel
        vc.settings = settings
		vc.mentionManager = AmityMentionManager(withType: .message(channelId: channelId))
        vc.messageId = messageId
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
        replyCloseViewButton.setImage(AmityIconSet.iconCloseReply, for: .normal)
        
        replyContentImageView.contentMode = .center
        replyContentImageView.layer.cornerRadius = 4
        
        replyAvatarView.placeholder = AmityIconSet.defaultAvatar
        replyDisplayNameLabel.font = AmityFontSet.body
        replyDescLabel.font = AmityFontSet.body
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
            cameraPicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
            cameraPicker.delegate = self
            self.present(cameraPicker, animated: true, completion: nil)
        }
    }
    
    func albumTap() {
        let imagePicker = AmityImagePickerController(selectedAssets: [])
        imagePicker.settings.theme.selectionStyle = .checked
        imagePicker.settings.fetch.assets.supportedMediaTypes = [.image]
        imagePicker.settings.selection.max = 20
        imagePicker.settings.selection.unselectOnReachingMax = false
        imagePicker.settings.theme.selectionStyle = .numbered
        presentAmityUIKitImagePicker(imagePicker, select: nil, deselect: nil, cancel: nil, finish: { [weak self] assets in
            let media = assets.map { asset in
                AmityMedia(state: .image(self?.getAssetThumbnail(asset: asset) ?? UIImage()), type: .image)
            }
            
            let vc = PreviewImagePickerController.make(media: media,
                                                    viewModel: (self?.screenViewModel)!,
                                                    mediaType: .image)
            vc.tabBarController?.tabBar.isHidden = true
            self?.navigationController?.pushViewController(vc, animated: false)
        })
    }
    
    func videoAlbumTap() {
        let imagePicker = AmityImagePickerController(selectedAssets: [])
        imagePicker.settings.theme.selectionStyle = .checked
        imagePicker.settings.fetch.assets.supportedMediaTypes = [.video]
        imagePicker.settings.selection.max = 10
        imagePicker.settings.selection.unselectOnReachingMax = false
        imagePicker.settings.theme.selectionStyle = .numbered
        presentAmityUIKitImagePicker(imagePicker, select: nil, deselect: nil, cancel: nil, finish: { [weak self] assets in
            let medias = assets.map { AmityMedia(state: .localAsset($0), type: .video) }
            let vc = PreviewImagePickerController.make(media: medias,
                                                    viewModel: (self?.screenViewModel)!,
                                                    mediaType: .video)
            vc.tabBarController?.tabBar.isHidden = true
            self?.navigationController?.pushViewController(vc, animated: false)
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
                Log.add("[Recorder] state in handler: Finish")
            case .finishWithMaximumTime:
                self?.circular.hide()
                self?.alertMaxAudio()
                Log.add("[Recorder] state in handler: finishWithMaximumTime")
            case .notFinish:
                Log.add("[Recorder] state in handler: notFinish")
            case .timeTooShort:
                Log.add("[Recorder] state in handler: timeTooShort")
                self?.circular.hide()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self?.composeBar.showPopoverMessage()
                }
            case .deleteAndClose:
                Log.add("[Recorder] state in handler: deleteAndClose")
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
        screenViewModel.startReading()
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
            navigationController?.popViewController(animated: true)
        }
    }
    
    func screenViewModelShouldUpdateScrollPosition(to indexPath: IndexPath) {
        messageViewController.updateScrollPosition(to: indexPath)
    }
    
    func screenViewModelDidGetChannel(channel: AmityChannelModel) {
        navigationHeaderViewController?.updateViews(channel: channel)
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
        case .updateMessages:
            
            let offset = messageViewController.tableView.contentOffset.y
            let contentHeight = messageViewController.tableView.contentSize.height

            messageViewController.tableView.reloadData()
            messageViewController.tableView.layoutIfNeeded()
            
            let newcontentHeight = self.messageViewController.tableView.contentSize.height
            let newOffset = (newcontentHeight - contentHeight) + offset
            self.messageViewController.tableView.setContentOffset(CGPoint(x: 0, y: newOffset), animated: false)
            
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
        case .didDeeleteErrorMessage:
            AmityHUD.show(.success(message: AmityLocalizedStringSet.HUD.delete.localizedString))
        case .didSendAudio:
            NSLog("[Recorder] screenViewModelEvents .didSendAudio -> Go to audioRecordingViewController?.stopRecording()")
            audioRecordingViewController?.stopRecording()
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
            let alertViewController = UIAlertController(title: AmityLocalizedStringSet.MessageList.alertErrorMessageTitle.localizedString,
                                                        message: nil, preferredStyle: .actionSheet)
            let cancel = UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel, handler: nil)
            let delete = UIAlertAction(title: AmityLocalizedStringSet.General.unsend.localizedString, style: .destructive, handler: { [weak self] _ in
                self?.screenViewModel.action.deleteErrorMessage(with: message.messageId, at: indexPath)
            })
            alertViewController.addAction(cancel)
            alertViewController.addAction(delete)
            present(alertViewController, animated: true)
            
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
            messageViewController.updateEditMode(isEdit: true)
            composeBar.showForwardMenuButton(show: true)
        case .copy(indexPath: let indexPath):
            guard let message = screenViewModel.dataSource.message(at: indexPath) else { return }
            UIPasteboard.general.string = message.text
        case .reply(indexPath: let indexPath):
            guard let message = screenViewModel.dataSource.message(at: indexPath) else { return }
            setReplyContainerView(message)
            showReplyContainerView()
        case .jumpReply(indexPath: let indexPath):
            guard let message = screenViewModel.dataSource.message(at: indexPath) else { return }
            screenViewModel.action.jumpToTargetId(message)
        case .avatar(indexPath: let indexPath):
            guard let message = screenViewModel.dataSource.message(at: indexPath) else { return }
            AmityEventHandler.shared.userDidTap(from: self, userId: message.userId)
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
    
    func screenViewModelDidReportMessage(at indexPath: IndexPath) {
        AmityHUD.show(.success(message: AmityLocalizedStringSet.HUD.reportSent.localizedString))
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
        DispatchQueue.main.async { [self] in
            if let indexPath = screenViewModel.dataSource.findIndexPath(forMessageId: messageId) {
                messageViewController.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                shakeCell(at: indexPath)
            }
        }
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
        }
        
        let url = message.object.user?.getAvatarInfo()?.fileURL
        replyAvatarView.setImage(withImageURL: url, placeholder: AmityIconSet.defaultAvatar)
        
        var displayName = ""
        if message.isOwner {
            displayName = "Reply to Yourself"
        } else {
            displayName = message.object.user?.displayName ?? "Anonymous"
        }
        replyDisplayNameLabel.text = displayName
        replyDescLabel.text = message.text
    }
    
    private func showReplyContainerView() {
        UIView.animate(withDuration: 0.3) {
            self.replyContainerViewHeightConstraint.constant = 55
            self.replyContainerView.isHidden = false
        }
    }
    
    private func hideReplyContainerView() {
        UIView.animate(withDuration: 0.3) {
            self.replyContainerViewHeightConstraint.constant = 0
            self.replyContainerView.isHidden = true
            self.message = nil
        }
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
