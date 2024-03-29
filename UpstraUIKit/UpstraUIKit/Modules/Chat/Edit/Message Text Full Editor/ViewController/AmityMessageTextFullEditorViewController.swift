//
//  AmityMessageTextFullEditorViewController.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 31/1/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

/// It's use for create broadcast message only. if want to use for other message type, will must to improve for its of some function.

import UIKit
import Photos
import AmitySDK
import AVKit
import MobileCoreServices

public class AmityMessageFullTextEditorSettings {
    
    public init() { }
    
    /// To set what are the attachment types to allow, the default value is `AmityMessageAttachmentType.allCases`.
    public var allowMessageAttachments: Set<AmityMessageAttachmentType> = Set<AmityMessageAttachmentType>(AmityMessageAttachmentType.allCases)
    
}

protocol AmityMessageTextFullEditorViewControllerDelegate: AnyObject {
    func messageTextFullEditorViewController(_ viewController: UIViewController, didCreateMessage message: AmityMessageModel)
}

public class AmityMessageTextFullEditorViewController: AmityViewController {
    
    enum Constant {
        static let maximumNumberOfMedias: Int = 1
        static let maximumNumberOfFiles: Int = 1
    }
    
    // MARK: - Properties
    
    // Use specifically for edit mode
    private var currentMessage: AmityMessageModel?
    
    private let settings: AmityMessageFullTextEditorSettings
    private var screenViewModel: AmityMessageTextFullEditorScreenViewModelType = AmityMessageTextFullEditorScreenViewModel()
    private let messageTarget: AmityMessageTarget
    private let messageMode: AmityMessageMode
    
    private let scrollView = UIScrollView(frame: .zero)
    private let textView = AmityTextView(frame: .zero)
    private let separaterLine = UIView(frame: .zero)
    private let galleryView = AmityGalleryCollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let fileView = AmityFileTableView(frame: .zero, style: .plain)
    private let messageMenuView: AmityMessageTextFullEditorMenuView
    private var createButton: UIBarButtonItem!
    private var textViewHeightZeroConstraint: NSLayoutConstraint!
    private var galleryViewHeightConstraint: NSLayoutConstraint!
    private var fileViewHeightConstraint: NSLayoutConstraint!
    private var messageMenuViewBottomConstraints: NSLayoutConstraint!
    private var filePicker: AmityFilePicker!
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    
    private var isValueChanged: Bool {
        return !textView.text.isEmpty || !galleryView.medias.isEmpty || !fileView.files.isEmpty
    }
    
    private var currentAttachmentState: AmityMessageAttachmentType? {
        didSet {
            messageMenuView.currentAttachmentState = currentAttachmentState
        }
    }
    
    weak var delegate: AmityMessageTextFullEditorViewControllerDelegate?
    
    init(messageTarget: AmityMessageTarget, messageMode: AmityMessageMode, settings: AmityMessageFullTextEditorSettings) {
        
        self.messageTarget = messageTarget
        self.messageMode = messageMode
        self.settings = settings
        self.messageMenuView = AmityMessageTextFullEditorMenuView(allowMessageAttachments: settings.allowMessageAttachments, alignment: .leading)

        super.init(nibName: nil, bundle: nil)
        
        screenViewModel.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initial ONE Krungthai Custom theme
        theme = ONEKrungthaiCustomTheme(viewController: self)
        
        title = AmityLocalizedStringSet.General.broadcast.localizedString
        
        filePicker = AmityFilePicker(presentationController: self, delegate: self)
        
        let title: String
        switch messageMode {
        case .create:
            title = AmityLocalizedStringSet.General.send.localizedString
        case .createManyChannel:
            title = AmityLocalizedStringSet.General.next.localizedString
        case .edit(let messageId):
            title = AmityLocalizedStringSet.General.save.localizedString
        }
        
        createButton = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(oncreateButtonTap))
        createButton.tintColor = AmityColorSet.primary
        createButton.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .normal)
        createButton.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .disabled)
        createButton.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .selected)
        
        navigationItem.rightBarButtonItem = createButton
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        #warning("ViewController must be implemented with storyboard")
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .onDrag
        scrollView.backgroundColor = AmityColorSet.backgroundColor
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: AmityMessageTextFullEditorMenuView.defaultHeight, right: 0)
        view.addSubview(scrollView)
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.padding = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        textView.customTextViewDelegate = self
        textView.isScrollEnabled = false
        textView.font = AmityFontSet.body
        textView.minCharacters = 1
        textView.setupWithoutSuggestions()
        textView.isEditable = !settings.allowMessageAttachments.contains(.file)
        
        /// It's use for create broadcast message only. if want to use for other message type, will must to improve for its
        let placeholder: String
        if settings.allowMessageAttachments.contains(.file) {
            placeholder = AmityLocalizedStringSet.Chat.broadcastMessageCreationFileTypeOnlyPlaceholder.localizedString
        } else {
            placeholder = AmityLocalizedStringSet.Chat.broadcastMessageCreationTextPlaceholder.localizedString
        }
        textView.placeholder = placeholder
        
        scrollView.addSubview(textView)
        
        separaterLine.translatesAutoresizingMaskIntoConstraints = false
        separaterLine.backgroundColor = AmityColorSet.secondary.blend(.shade4)
        separaterLine.isHidden = true
        scrollView.addSubview(separaterLine)
        
        galleryView.translatesAutoresizingMaskIntoConstraints = false
        galleryView.actionDelegate = self
        galleryView.isEditable = true
        galleryView.isScrollEnabled = false
        galleryView.backgroundColor = AmityColorSet.backgroundColor
        scrollView.addSubview(galleryView)
        
        fileView.translatesAutoresizingMaskIntoConstraints = false
        fileView.actionDelegate = self
        fileView.isEditingMode = true
        scrollView.addSubview(fileView)
        
        messageMenuView.translatesAutoresizingMaskIntoConstraints = false
        messageMenuView.delegate = self
        view.addSubview(messageMenuView)
        
        textViewHeightZeroConstraint = NSLayoutConstraint(item: textView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        textViewHeightZeroConstraint.isActive = false
        galleryViewHeightConstraint = NSLayoutConstraint(item: galleryView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        fileViewHeightConstraint = NSLayoutConstraint(item: fileView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        messageMenuViewBottomConstraints = NSLayoutConstraint(item: messageMenuView, attribute: .bottom, relatedBy: .equal, toItem: view.layoutMarginsGuide, attribute: .bottom, multiplier: 1, constant: 0)
        
        switch messageMode {
        case .create, .createManyChannel:
            // If there is no menu to show, so we don't show messageMenuView.
            messageMenuView.isHidden = settings.allowMessageAttachments.isEmpty
        case .edit:
            messageMenuView.isHidden = false
        }
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            messageMenuView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageMenuView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageMenuView.heightAnchor.constraint(equalToConstant: messageMode == .create ? AmityMessageTextFullEditorMenuView.defaultHeight : AmityMessageTextFullEditorMenuView.defaultHeight),
            messageMenuViewBottomConstraints,
            textView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            textView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
            textView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            textViewHeightZeroConstraint,
            separaterLine.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            separaterLine.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            separaterLine.centerYAnchor.constraint(equalTo: galleryView.topAnchor),
            separaterLine.heightAnchor.constraint(equalToConstant: 1),
            galleryView.topAnchor.constraint(equalTo: textView.bottomAnchor),
            galleryView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            galleryView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            galleryView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
            galleryViewHeightConstraint,
            fileView.topAnchor.constraint(equalTo: galleryView.bottomAnchor),
            fileView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            fileView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            fileView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            fileViewHeightConstraint
        ])
        updateConstraints()
        // keyboard
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set color navigation bar by custom theme
        theme?.setBackgroundNavigationBar()
        
        // Update view state
        updateViewState()
    }
    
    public override func didTapLeftBarButton() {
        if isValueChanged {
            let alertController = UIAlertController(title: AmityLocalizedStringSet.Chat.messageCreationDiscardMessageTitle.localizedString, message: AmityLocalizedStringSet.Chat.messageCreationDiscardMessageDescription.localizedString, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel, handler: nil)
            let discardAction = UIAlertAction(title: AmityLocalizedStringSet.General.discard.localizedString, style: .destructive) { [weak self] _ in
                self?.generalDismiss()
            }
            alertController.addAction(cancelAction)
            alertController.addAction(discardAction)
            present(alertController, animated: true, completion: nil)
        } else {
            generalDismiss()
        }
    }
    
    private func updateConstraints() {
        fileViewHeightConstraint.constant = AmityFileTableView.height(for: fileView.files.count, isEdtingMode: true, isExpanded: false)
        galleryViewHeightConstraint.constant = AmityGalleryCollectionView.height(for: galleryView.contentSize.width, numberOfItems: galleryView.medias.count)
        textViewHeightZeroConstraint.isActive = fileView.files.count > 0 ? true : false
        scrollView.layoutIfNeeded()
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardScreenEndFrame = keyboardValue.size
        if notification.name == UIResponder.keyboardWillHideNotification {
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: AmityMessageTextFullEditorMenuView.defaultHeight, right: 0)
            messageMenuViewBottomConstraints.constant = view.layoutMargins.bottom
        } else {
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardScreenEndFrame.height - view.safeAreaInsets.bottom + AmityMessageTextFullEditorMenuView.defaultHeight, right: 0)
            messageMenuViewBottomConstraints.constant = view.layoutMargins.bottom - keyboardScreenEndFrame.height
        }
        scrollView.scrollIndicatorInsets = scrollView.contentInset
        let selectedRange = textView.selectedRange
        textView.scrollRangeToVisible(selectedRange)
    }
    
    // MARK: - Action
    @objc private func oncreateButtonTap() {
        // Get data
        let text = textView.text ?? ""
        let medias = galleryView.medias
        let files = fileView.files
        
        // Setup after end editing
        view.endEditing(true)
        createButton.isEnabled = false
        
        // Send message each type
        /// It's use for create broadcast message only. if want to use for other message type, will must to improve for its
        switch messageTarget {
        case .broadcast(let channel):
            // Clarified broadcast type
            var broadcastType: AmityBroadcastMessageCreatorType?
            if !medias.isEmpty {
                broadcastType = !text.isEmpty ? .imageWithCaption : .image
            } else if !files.isEmpty {
                broadcastType = .file
            } else if !text.isEmpty {
                broadcastType = .text
            }
            guard let currentBroadcastType = broadcastType else { break }
            
            // Create message creator model
            let messageCreatorModel = AmityBroadcastMessageCreatorModel(broadcastType: currentBroadcastType, text: text, medias: medias, files: files)
            
            // Send broadcast message
            if let selectedChannel = channel { // Case : Send broadcast one group
                screenViewModel.action.createMessage(message: messageCreatorModel, channelId: selectedChannel.channelId)
            } else { // Case : Send broadcast many group
                let channelPickerViewController = AmityForwatdChannelPickerViewController.make(pageTitle: "Select group", type: .broadcast, broadcastMessage: messageCreatorModel)
                channelPickerViewController.isLastViewController = false
                navigationController?.pushViewController(channelPickerViewController, animated: true)
            }
        default:
            break // Not ready for other type
        }
    }
    
    private func updateViewState() {
        
        // Update separater state
        separaterLine.isHidden = galleryView.medias.isEmpty && fileView.files.isEmpty
        
        var isMessageValid = textView.isValid
        
        // Update create button state
        var isImageValid = true
        if !galleryView.medias.isEmpty {
            isImageValid = galleryView.medias.filter({
                switch $0.state {
                case .uploadedImage, .uploadedVideo , .downloadableImage, .downloadableVideo:
                    return false
                default:
                    return true
                }
            }).isEmpty
            isMessageValid = isImageValid
        }
        var isFileValid = true
        if !fileView.files.isEmpty {
            isFileValid = fileView.files.filter({
                switch $0.state {
                case .uploaded, .downloadable:
                    return false
                default:
                    return true
                }
            }).isEmpty
            isMessageValid = isFileValid
        }
        
        createButton.isEnabled = isMessageValid
        
        // Update messageMenuView.currentAttachmentState to disable buttons based on the chosen attachment.
        if !fileView.files.isEmpty {
            currentAttachmentState = .file
        } else if galleryView.medias.contains(where: { $0.type == .image }) {
            currentAttachmentState = .image
        } else if galleryView.medias.contains(where: { $0.type == .video }) {
            currentAttachmentState = .video
        } else {
            currentAttachmentState = .none
        }
        
        if textView.text.isEmpty {
            textView.textColor = AmityColorSet.base
        }
    }
    
    // MARK: Helper functions
    private func uploadImages() {
        let fileUploadFailedDispatchGroup = DispatchGroup()
        var isUploadFailed = false
        for index in 0..<galleryView.medias.count {
            let media = galleryView.medias[index]
            guard case .idle = galleryView.viewState(for: media.id) else {
                // If file is uploading, skip checking task
                continue
            }
            switch galleryView.mediaState(for: media.id) {
            case .localAsset, .image:
                fileUploadFailedDispatchGroup.enter()
                // Start with 0% immediately.
                galleryView.updateViewState(for: media.id, state: .uploading(progress: 0))
                // get local image for uploading
                media.getImageForUploading { [weak self] result in
                    switch result {
                    case .success(let img):
                        AmityUIKitManagerInternal.shared.fileService.uploadImage(image: img, progressHandler: { progress in
                            self?.galleryView.updateViewState(for: media.id, state: .uploading(progress: progress))
                            Log.add("[UIKit]: Upload Progress \(progress)")
                        }, completion:  { [weak self] result in
                            switch result {
                            case .success(let imageData):
                                Log.add("[UIKit]: Uploaded image data \(imageData.fileId)")
                                media.state = .uploadedImage(data: imageData)
                                self?.galleryView.updateViewState(for: media.id, state: .uploaded)
                            case .failure:
                                Log.add("[UIKit]: Image upload failed")
                                media.state = .error
                                self?.galleryView.updateViewState(for: media.id, state: .error)
                                isUploadFailed = true
                            }
                            fileUploadFailedDispatchGroup.leave()
                            self?.updateViewState()
                        })
                    case .failure:
                        media.state = .error
                        self?.galleryView.updateViewState(for: media.id, state: .error)
                        isUploadFailed = true
                    }
                }
            default:
                Log.add("[UIKit]: Unsupported media state for uploading.")
                break
            }
        }
        
        fileUploadFailedDispatchGroup.notify(queue: .main) { [weak self] in
            if isUploadFailed && self?.presentedViewController == nil {
                self?.showUploadFailureAlert()
            }
        }
        
    }
    
    private func uploadVideos() {
        let dispatchGroup = DispatchGroup()
        var isUploadFailed = false
        for index in 0..<galleryView.medias.count {
            let media = galleryView.medias[index]
            guard case .idle = galleryView.viewState(for: media.id) else {
                // If file is uploading, skip checking task
                continue
            }
            switch galleryView.mediaState(for: media.id) {
            case .localAsset, .localURL:
                // Note:
                // - .localUrl via camera
                // - .localAsset via photo album picker
                dispatchGroup.enter()
                // Start with 0% immediately.
                galleryView.updateViewState(for: media.id, state: .uploading(progress: 0))
                // get local video url for uploading
                media.getLocalURLForUploading { [weak self] url in
                    guard let url = url else {
                        media.state = .error
                        self?.galleryView.updateViewState(for: media.id, state: .error)
                        isUploadFailed = true
                        return
                    }
                    AmityUIKitManagerInternal.shared.fileService.uploadVideo(url: url, progressHandler: { progress in
                        self?.galleryView.updateViewState(for: media.id, state: .uploading(progress: progress))
                        Log.add("[UIKit]: Upload Progress \(progress)")
                    }, completion: { result in
                        switch result {
                        case .success(let videoData):
                            Log.add("[UIKit]: Uploaded video \(videoData.fileId)")
                            media.state = .uploadedVideo(data: videoData)
                            self?.galleryView.updateViewState(for: media.id, state: .uploaded)
                        case .failure:
                            Log.add("[UIKit]: Video upload failed")
                            media.state = .error
                            self?.galleryView.updateViewState(for: media.id, state: .error)
                            isUploadFailed = true
                        }
                        dispatchGroup.leave()
                        self?.updateViewState()
                    })
                }
            default:
                break
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            if isUploadFailed && self?.presentedViewController == nil {
                self?.showUploadFailureAlert()
            }
        }
        
    }
    
    private func uploadFiles() {
        let fileUploadFailedDispatchGroup = DispatchGroup()
        var isUploadFailed = false
        for index in 0..<fileView.files.count {
            let file = fileView.files[index]
            
            switch fileView.viewState(for: file.id) {
            case .idle:
                if case .local = fileView.fileState(for: file.id), let fileUrl = file.fileURL, let fileData = try? Data(contentsOf: fileUrl) {
                    let fileToUpload = AmityUploadableFile(fileData: fileData, fileName: file.fileName)
                    fileUploadFailedDispatchGroup.enter()
                    // Start with 0% immediately.
                    fileView.updateViewState(for: file.id, state: .uploading(progress: 0))
                    AmityUIKitManagerInternal.shared.fileService.uploadFile(file: fileToUpload, progressHandler: { [weak self] progress in
                        self?.fileView.updateViewState(for: file.id, state: .uploading(progress: progress))
                        Log.add("[UIKit]: File upload progress: \(progress)")
                    }) { [weak self] result in
                        switch result {
                        case .success(let fileData):
                            Log.add("[UIKit]: File upload success")
                            file.state = .uploaded(data: fileData)
                            self?.fileView.updateViewState(for: file.id, state: .uploaded)
                        case .failure(let error):
                            Log.add("[UIKit]: File upload failed")
                            file.state = .error(errorMessage: error.localizedDescription)
                            self?.fileView.updateViewState(for: file.id, state: .error)
                            isUploadFailed = true
                        }
                        fileUploadFailedDispatchGroup.leave()
                        self?.updateViewState()
                    }
                } else {
                    fileView.updateViewState(for: file.id, state: .error)
                }
            case .error:
                fileView.updateViewState(for: file.id, state: .error)
            case .downloadable, .uploaded, .uploading(_):
                break
            }
        }
        
        fileUploadFailedDispatchGroup.notify(queue: .main) { [weak self] in
            if isUploadFailed && self?.presentedViewController == nil {
                self?.showUploadFailureAlert()
            }
        }
        
    }

    private func showUploadFailureAlert() {
        let alertController = UIAlertController(title: AmityLocalizedStringSet.Chat.messageCreationUploadIncompleteTitle.localizedString, message: AmityLocalizedStringSet.Chat.messageCreationUploadIncompleteDescription.localizedString, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.ok.localizedString, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func playVideo(for asset: PHAsset) {
        guard asset.mediaType == .video else {
            assertionFailure("Not a valid video media type")
            return
        }
        PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { [weak self] asset, max, info in
            guard let asset = asset as? AVURLAsset else {
                assertionFailure("Unable to convert asset to AVURLAsset")
                return
            }
            DispatchQueue.main.async {
                self?.presentVideoPlayer(at: asset.url)
            }
        }
    }
    
    private func presentMaxNumberReachDialogue() {
        let title: String
        let message: String
        
        switch currentAttachmentState {
        case .image:
            title = "Maximum number of images exceeded"
            message = "Maximum number of images that can be uploaded is \(Constant.maximumNumberOfMedias). The rest images will be discarded."
        case .video:
            title = "Maximum number of videos exceeded"
            message = "Maximum number of videos that can be uploaded is \(Constant.maximumNumberOfMedias). The rest videos will be discarded."
        default:
            title = "Maximum number of files exceeded"
            message = "Maximum number of files that can be uploaded is \(Constant.maximumNumberOfFiles). The rest files will be discarded."
        }
        
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let cancelAction = UIAlertAction(
            title: AmityLocalizedStringSet.General.ok.localizedString,
            style: .cancel,
            handler: nil
        )
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func presentMediaPickerCamera() {
        
        let cameraPicker = UIImagePickerController()
        cameraPicker.sourceType = .camera
        cameraPicker.videoQuality = .typeHigh
        cameraPicker.delegate = self
        
        // We automatically choose media type based on last media pick.
        switch currentAttachmentState {
        case .none:
            // If the user have not chosen any media yet, we allow both type to be picked.
            // After it is selected, we force the same type for the later actions.
            var mediaTypesWhenNothingSelected: [String] = []
            if settings.allowMessageAttachments.contains(.image) {
                mediaTypesWhenNothingSelected.append(kUTTypeImage as String)
            }
            if settings.allowMessageAttachments.contains(.video) {
                mediaTypesWhenNothingSelected.append(kUTTypeMovie as String)
            }
            cameraPicker.mediaTypes = mediaTypesWhenNothingSelected
        case .image:
            // The user already select image, so we force the media type to allow only image.
            cameraPicker.mediaTypes = [kUTTypeImage as String]
        case .video:
            // The user already select video, so we force the media type to allow only video.
            cameraPicker.mediaTypes = [kUTTypeMovie as String]
        case .file:
            Log.add("Type mismatch")
        }
        
        present(cameraPicker, animated: true, completion: nil)
        
    }
    
    private func presentMediaPickerAlbum(type: AmityMediaType) {
        
        let supportedMediaTypes: Set<NewSettings.NewFetch.NewAssets.MediaTypes>
        
        // The closue to execute when picker finish picking the media.
        let finish: ([PHAsset]) -> Void
        
        switch type {
        case .image:
            supportedMediaTypes = [.image]
            finish = { [weak self] assets in
                guard let strongSelf = self else { return }
                let medias: [AmityMedia] = assets.map { asset in
                    AmityMedia(state: .localAsset(asset), type: .image)
                }
                strongSelf.addMedias(medias, type: .image)
            }
        case .video:
            supportedMediaTypes = [.video]
            finish = { [weak self] assets in
                guard let strongSelf = self else { return }
                let medias: [AmityMedia] = assets.map { asset in
                    let media = AmityMedia(state: .localAsset(asset), type: .video)
                    media.localAsset = asset
                    return media
                }
                strongSelf.addMedias(medias, type: .video)
            }
        }
        
        let maxNumberOfSelection: Int
        switch messageMode {
        case .create, .createManyChannel:
            maxNumberOfSelection = Constant.maximumNumberOfMedias
        case .edit:
            maxNumberOfSelection = Constant.maximumNumberOfMedias - galleryView.medias.count
        }
        
        let imagePicker = NewImagePickerController(selectedAssets: [])
        imagePicker.settings.theme.selectionStyle = .checked
        imagePicker.settings.fetch.assets.supportedMediaTypes = supportedMediaTypes
        imagePicker.settings.selection.max = maxNumberOfSelection
        imagePicker.settings.selection.unselectOnReachingMax = true
        
        let options = imagePicker.settings.fetch.album.options
        // Fetching user library and other smart albums
        let userLibraryCollection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: options)
        let favoritesCollection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: options)
        let selfPortraitsCollection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSelfPortraits, options: options)
        let panoramasCollection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumPanoramas, options: options)
        let videosCollection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumVideos, options: options)
        
        // Fetching regular albums
        let regularAlbumsCollection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: options)
        
        imagePicker.settings.fetch.album.fetchResults = [
            userLibraryCollection,
            favoritesCollection,
            regularAlbumsCollection,
            selfPortraitsCollection,
            panoramasCollection,
            videosCollection
        ]
                    
        imagePicker.modalPresentationStyle = .overFullScreen
        presentNewImagePicker(imagePicker, select: nil, deselect: nil, cancel: nil, finish: finish, completion: nil)
    }
    
}

extension AmityMessageTextFullEditorViewController: AmityGalleryCollectionViewDelegate {
    
    func galleryView(_ view: AmityGalleryCollectionView, didRemoveImageAt index: Int) {
        var medias = galleryView.medias
        medias.remove(at: index)
        galleryView.configure(medias: medias)
        updateViewState()
    }
    
    func galleryView(_ view: AmityGalleryCollectionView, didTapMedia media: AmityMedia, reference: UIImageView) {
        
        switch media.type {
        case .video:
            if let asset = media.localAsset {
                // The video is picked from album.
                playVideo(for: asset)
            } else if let videoUrl = media.localUrl {
                // The video is taken from camera.
                presentVideoPlayer(at: videoUrl)
            } else {
                assertionFailure("Unsupported media when tapping at the video.")
            }
        case .image:
            // Do nothing when tap at the image.
            break
        }
        
    }
    
}

extension AmityMessageTextFullEditorViewController: AmityTextViewDelegate {
    
    public func textViewDidChange(_ textView: AmityTextView) {
        updateViewState()
    }
    
    public func textView(_ textView: AmityTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView.text.count > AmityMentionManager.maximumCharacterCountForPost {
            showAlertForMaximumCharacters()
            return false
        }
        return true
    }
    
    public func textViewDidChangeSelection(_ textView: AmityTextView) {
        // Not use
    }
}

extension AmityMessageTextFullEditorViewController: AmityFilePickerDelegate {
    
    func didPickFiles(files: [AmityFile]) {
        let totalNumberOfFiles = fileView.files.count + files.count
        guard totalNumberOfFiles <= Constant.maximumNumberOfFiles else {
            presentMaxNumberReachDialogue()
            return
        }
        fileView.configure(files: files)
        
        // text, file and images are not supported posting together
        galleryView.configure(medias: [])
        updateViewState()
        uploadFiles()
        updateConstraints()
    }
    
}

extension AmityMessageTextFullEditorViewController: AmityFileTableViewDelegate {
    
    func fileTableView(_ view: AmityFileTableView, didTapAt index: Int) {
        // Not use
    }
    
    func fileTableViewDidDeleteData(_ view: AmityFileTableView, at index: Int) {
        updateViewState()
        updateConstraints()
    }
    
    func fileTableViewDidUpdateData(_ view: AmityFileTableView) {
        updateViewState()
        updateConstraints()
    }
    
    func fileTableViewDidTapViewAll(_ view: AmityFileTableView) {
        // Not use
    }
    
}

extension AmityMessageTextFullEditorViewController: AmityMessageTextFullEditorViewControllerDelegate {
    func messageTextFullEditorViewController(_ viewController: UIViewController, didCreateMessage message: AmityMessageModel) {
        // Not use
    }
    
    func messageTextFullEditorViewController(_ viewController: UIViewController, didUpdateMessage message: AmityMessageModel) {
        // Not use
    }
}

extension AmityMessageTextFullEditorViewController: AmityMessageTextFullEditorScreenViewModelDelegate {
    func screenViewModelDidCreateMessage(_ viewModel: AmityMessageTextFullEditorScreenViewModelType, message: AmityMessage?, error: Error?) {
        if let message = message {
            AmityHUD.show(.success(message: AmityLocalizedStringSet.HUD.hudBroadcastMessageSuccess.localizedString))
            navigationController?.popViewController(animated: true)
        } else {
            AmityHUD.show(.success(message: AmityLocalizedStringSet.HUD.hudBroadcastMessageFail.localizedString))
        }
    }
}

extension AmityMessageTextFullEditorViewController: AmityMessageTextFullEditorMenuViewDelegate {
    
    func messageMenuView(_ view: AmityMessageTextFullEditorMenuView, didTap action: AmityMessageMenuActionType) {
        
        switch action {
        case .camera:
            presentMediaPickerCamera()
        case .album:
            presentMediaPickerAlbum(type: .image)
        case .video:
            presentMediaPickerAlbum(type: .video)
        case .file:
            filePicker.present(from: view, files: fileView.files)
        case .expand:
            presentBottomSheetMenus()
        }
    }
    
    private func presentBottomSheetMenus() {
        
        let bottomSheet = BottomSheetViewController()
        let contentView = ItemOptionView<ImageItemOption>()
        let imageBackgroundColor = AmityColorSet.base.blend(.shade4)
        let disabledColor = AmityColorSet.base.blend(.shade3)
        
        var cameraOption = ImageItemOption(title: AmityLocalizedStringSet.General.camera.localizedString,
                                           image: AmityIconSet.iconCameraSmall,
                                           imageBackgroundColor: imageBackgroundColor) { [weak self] in
            self?.presentMediaPickerCamera()
        }
        
        var galleryOption = ImageItemOption(title: AmityLocalizedStringSet.General.generalPhoto.localizedString,
                                            image: AmityIconSet.iconPhoto,
                                            imageBackgroundColor: imageBackgroundColor) { [weak self] in
            self?.presentMediaPickerAlbum(type: .image)
        }
        
        var videoOption = ImageItemOption(title: AmityLocalizedStringSet.General.generalVideo.localizedString,
                                          image: AmityIconSet.iconPlayVideo,
                                          imageBackgroundColor: imageBackgroundColor) { [weak self] in
            self?.presentMediaPickerAlbum(type: .video)
        }
        
        var fileOption = ImageItemOption(title: AmityLocalizedStringSet.General.generalAttachment.localizedString,
                                         image: AmityIconSet.iconAttach,
                                         imageBackgroundColor: imageBackgroundColor)
        fileOption.completion = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.filePicker.present(from: strongSelf.messageMenuView, files: strongSelf.fileView.files)
        }
        
        // NOTE: Once the currentAttachmentState has changed from `none` to something else.
        // We still show the buttons, but we disable them based on the currentAttachmentState.
        if currentAttachmentState != .none {
            // Disable gallery option if currentAttachmentState is not .image or .video
            if currentAttachmentState != .image {
                galleryOption.image = AmityIconSet.iconPhoto?.setTintColor(disabledColor)
                galleryOption.textColor = disabledColor
                galleryOption.completion = nil
            }
            
            // Disable camera option if currentAttachmentState is not .image or .video
            if currentAttachmentState != .image && currentAttachmentState != .video {
                cameraOption.image = AmityIconSet.iconCameraSmall?.setTintColor(disabledColor)
                cameraOption.textColor = disabledColor
                cameraOption.completion = nil
            }
            
            // Disable video option if currentAttachmentState is not .video
            if currentAttachmentState != .video {
                videoOption.image = AmityIconSet.iconPlayVideo?.setTintColor(disabledColor)
                videoOption.textColor = disabledColor
                videoOption.completion = nil
            }
            
            // Disable file option if currentAttachmentState is not .file
            if currentAttachmentState != .file {
                fileOption.image = AmityIconSet.iconAttach?.setTintColor(disabledColor)
                fileOption.textColor = disabledColor
                fileOption.completion = nil
            }
        }
        
        // Each option will be added, based on allowMessageAttachments.
        var items: [ImageItemOption] = []
        if settings.allowMessageAttachments.contains(.image) || settings.allowMessageAttachments.contains(.video) {
            items.append(cameraOption)
            items.append(galleryOption)
        }
        if settings.allowMessageAttachments.contains(.file) {
            items.append(fileOption)
        }
        if settings.allowMessageAttachments.contains(.video) {
            items.append(videoOption)
        }
        
        contentView.configure(items: items, selectedItem: nil)
        contentView.didSelectItem = { _ in
            bottomSheet.dismissBottomSheet()
        }
        
        bottomSheet.sheetContentView = contentView
        bottomSheet.isTitleHidden = true
        bottomSheet.modalPresentationStyle = .overFullScreen
        
        present(bottomSheet, animated: false, completion: nil)
        
    }
    
    private func addMedias(_ medias: [AmityMedia], type: AmityMediaType) {
        let totalNumberOfMedias = galleryView.medias.count + medias.count
        guard totalNumberOfMedias <= Constant.maximumNumberOfMedias else {
            presentMaxNumberReachDialogue()
            return
        }
        galleryView.addMedias(medias)
        fileView.configure(files: [])
        // start uploading
        updateViewState()
        switch type {
        case .image:
            uploadImages()
        case .video:
            uploadVideos()
        }
        updateConstraints()
    }
    
    private func showAlertForMaximumCharacters() {
        let alertController = UIAlertController(title: AmityLocalizedStringSet.Chat.messageUnableToCreateMessageTitle.localizedString, message: AmityLocalizedStringSet.Chat.messageUnableToCreateMessageDescription.localizedString, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.done.localizedString, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension AmityMessageTextFullEditorViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

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
            if let fileUrl = info[.mediaURL] as? URL {
                let media = AmityMedia(state: .localURL(url: fileUrl), type: .video)
                media.localUrl = fileUrl
                // Generate thumbnail
                let asset = AVAsset(url: fileUrl)
                let assetImageGenerator = AVAssetImageGenerator(asset: asset)
                assetImageGenerator.appliesPreferredTrackTransform = true
                let time = CMTime(seconds: 1.0, preferredTimescale: 1)
                var actualTime: CMTime = CMTime.zero
                do {
                    let imageRef = try assetImageGenerator.copyCGImage(at: time, actualTime: &actualTime)
                    media.generatedThumbnailImage = UIImage(cgImage: imageRef)
                } catch {
                    print("Unable to generate thumbnail image for kUTTypeMovie.")
                }
                selectedMedia = media
            }
        default:
            assertionFailure("Unsupported media type")
            break
        }
        
        // We want to process selected media only after the default ui for selecting media
        // dismisses completely. Otherwise we see `Attempt to present ....` error
        picker.dismiss(animated: true) { [weak self] in
            guard let media = selectedMedia else { return }
            self?.addMedias([media], type: media.type)
        }
    }
    
}

// MARK: - UIGestureRecognizerDelegate
extension AmityMessageTextFullEditorViewController {

    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard isValueChanged else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }

        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGestureRecognizer.translation(in: panGestureRecognizer.view)
            if translation.x > 0 && abs(translation.x) > abs(translation.y) {
                let alertController = UIAlertController(title: AmityLocalizedStringSet.Chat.messageCreationDiscardMessageTitle.localizedString, message: AmityLocalizedStringSet.Chat.messageCreationDiscardMessageDescription.localizedString, preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel, handler: nil)
                let discardAction = UIAlertAction(title: AmityLocalizedStringSet.General.discard.localizedString, style: .destructive) { [weak self] _ in
                    self?.generalDismiss()
                }
                alertController.addAction(cancelAction)
                alertController.addAction(discardAction)
                present(alertController, animated: true, completion: nil)

                // prevents swiping back and present confirmation message
                return false
            }
        }

        // falls back to normal behaviour, swipe back to previous page
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}

