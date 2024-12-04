//
//  AmityPostTextEditorViewController.swift
//  AmityUIKit
//
//  Created by Nontapat Siengsanor on 1/7/2563 BE.
//  Copyright © 2563 Amity Communication. All rights reserved.
//

import UIKit
import Photos
import AmitySDK
import AVKit
import MobileCoreServices

public class AmityPostEditorSettings {
    
    public init() { }
    
    /// To set what are the attachment types to allow, the default value is `AmityPostAttachmentType.allCases`.
    public var allowPostAttachments: Set<AmityPostAttachmentType> = Set<AmityPostAttachmentType>(AmityPostAttachmentType.allCases)
    
}

protocol AmityPostViewControllerDelegate: AnyObject {
    func postViewController(_ viewController: UIViewController, didCreatePost post: AmityPostModel)
    func postViewController(_ viewController: UIViewController, didUpdatePost post: AmityPostModel)
}

public class AmityPostTextEditorViewController: AmityViewController {
    
    enum Constant {
        static let maximumNumberOfImages: Int = 10
    }
    
    // MARK: - Properties
    
    // Use specifically for edit mode
    private var currentPost: AmityPostModel?
    
    private let settings: AmityPostEditorSettings
    private var screenViewModel: AmityPostTextEditorScreenViewModelType = AmityPostTextEditorScreenViewModel()
    private let postTarget: AmityPostTarget
    private let postMode: AmityPostMode
    
    private let comunityPanelView = AmityComunityPanelView(frame: .zero)
    private let scrollView = UIScrollView(frame: .zero)
    private let textView = AmityTextView(frame: .zero)
    private let locationView = UILabel(frame: .zero)
    private let separaterLine = UIView(frame: .zero)
    private let galleryView = AmityGalleryCollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let fileView = AmityFileTableView(frame: .zero, style: .plain)
    private let postMenuView: AmityPostTextEditorMenuView
    private var postButton: UIBarButtonItem!
    private var galleryViewHeightConstraint: NSLayoutConstraint!
    private var fileViewHeightConstraint: NSLayoutConstraint!
    private var postMenuViewBottomConstraints: NSLayoutConstraint!
    private var filePicker: AmityFilePicker!
    private var mentionTableView: AmityMentionTableView
    private var mentionTableViewHeightConstraint: NSLayoutConstraint!
    private var hashtagTableView: AmityHashtagTableView
    private var hashtagTableViewHeightConstraint: NSLayoutConstraint!
    private var mentionManager: AmityMentionManager?
    private var bottomScrollViewInset: CGFloat = 0
    private var heightConstraintOfMentionHashTagTableView: CGFloat = 0
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    
    private var isValueChanged: Bool {
        return !textView.text.isEmpty || !galleryView.medias.isEmpty || !fileView.files.isEmpty
    }
    
    private var currentAttachmentState: AmityPostAttachmentType? {
        didSet {
            postMenuView.currentAttachmentState = currentAttachmentState
        }
    }
    
    weak var delegate: AmityPostViewControllerDelegate?
    
    private var mediaAsset: [PHAsset] = []
    private var locationMetadata: [String: Any] = [:]
    
    init(postTarget: AmityPostTarget, postMode: AmityPostMode, settings: AmityPostEditorSettings) {
        
        self.postTarget = postTarget
        self.postMode = postMode
        self.settings = settings
        self.postMenuView = AmityPostTextEditorMenuView(allowPostAttachments: settings.allowPostAttachments)
        self.mentionTableView = AmityMentionTableView(frame: .zero)
        self.hashtagTableView = AmityHashtagTableView(frame: .zero)

        if postMode == .create {
            var communityId: String? = nil
            switch postTarget {
            case .community(let community):
                communityId = community.isPublic ? nil : community.communityId
            default: break
            }
            mentionManager = AmityMentionManager(withType: .post(communityId: communityId))
        }
        
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
        
        filePicker = AmityFilePicker(presentationController: self, delegate: self)
        
        let isCreateMode = (postMode == .create)
        postButton = UIBarButtonItem(title: isCreateMode ? AmityLocalizedStringSet.General.post.localizedString : AmityLocalizedStringSet.General.save.localizedString, style: .plain, target: self, action: #selector(onPostButtonTap))
        postButton.tintColor = AmityColorSet.primary
        
        // [Fix defect] Set font of post button refer to AmityFontSet
        postButton.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .normal)
        postButton.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .disabled)
        postButton.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .selected)
        
        navigationItem.rightBarButtonItem = postButton
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        #warning("ViewController must be implemented with storyboard")
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .onDrag
        scrollView.backgroundColor = AmityColorSet.backgroundColor
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: AmityPostTextEditorMenuView.defaultHeight, right: 0)
        view.addSubview(scrollView)
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.padding = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        textView.customTextViewDelegate = self
        textView.isScrollEnabled = false
        textView.font = AmityFontSet.body
        textView.minCharacters = 1
        textView.setupWithoutSuggestions()
        textView.placeholder = AmityLocalizedStringSet.postCreationTextPlaceholder.localizedString
        scrollView.addSubview(textView)
        
        // Add tap gesture recognizer to the locationView
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOnLabel))
        locationView.addGestureRecognizer(tapGesture)
        locationView.isUserInteractionEnabled = true
        
        locationView.translatesAutoresizingMaskIntoConstraints = false
        locationView.font = AmityFontSet.body
        locationView.textColor = AmityColorSet.highlight
        locationView.numberOfLines = 0
        locationView.isHidden = true
        scrollView.addSubview(locationView)
        
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
        
        postMenuView.translatesAutoresizingMaskIntoConstraints = false
        postMenuView.delegate = self
        view.addSubview(postMenuView)
        
        comunityPanelView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(comunityPanelView)
        
        mentionTableView.isHidden = true
        mentionTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mentionTableView)
        mentionTableViewHeightConstraint = mentionTableView.heightAnchor.constraint(equalToConstant: 1.0)
        
//        hashtagTableView.isHidden = true
        hashtagTableView.translatesAutoresizingMaskIntoConstraints = false
        hashtagTableView.tag = 1
        view.addSubview(hashtagTableView)
        hashtagTableViewHeightConstraint = hashtagTableView.heightAnchor.constraint(equalToConstant: 1.0)
        
        galleryViewHeightConstraint = NSLayoutConstraint(item: galleryView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        fileViewHeightConstraint = NSLayoutConstraint(item: fileView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        postMenuViewBottomConstraints = NSLayoutConstraint(item: postMenuView, attribute: .bottom, relatedBy: .equal, toItem: view.layoutMarginsGuide, attribute: .bottom, multiplier: 1, constant: 0)
        
        switch postMode {
        case .create:
            // If there is no menu to show, so we don't show postMenuView.
            postMenuView.isHidden = settings.allowPostAttachments.isEmpty
        case .edit:
            postMenuView.isHidden = false
        }
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            
            postMenuView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            postMenuView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            postMenuView.heightAnchor.constraint(equalToConstant: postMode == .create ? AmityPostTextEditorMenuView.defaultHeight : AmityPostTextEditorMenuView.defaultHeight),
            postMenuViewBottomConstraints,
            
            comunityPanelView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            comunityPanelView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            comunityPanelView.bottomAnchor.constraint(equalTo: postMenuView.topAnchor),
            comunityPanelView.heightAnchor.constraint(equalToConstant: AmityComunityPanelView.defaultHeight),
            
            textView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            textView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
            textView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            
            separaterLine.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            separaterLine.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            separaterLine.centerYAnchor.constraint(equalTo: galleryView.topAnchor),
            separaterLine.heightAnchor.constraint(equalToConstant: 1),
            
            locationView.topAnchor.constraint(equalTo: textView.bottomAnchor),
            locationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            locationView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            galleryView.topAnchor.constraint(equalTo: locationView.bottomAnchor),
            galleryView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            galleryView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            galleryViewHeightConstraint,
            
            fileView.topAnchor.constraint(equalTo: galleryView.bottomAnchor),
            fileView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            fileView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            fileView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            fileViewHeightConstraint,
            
            mentionTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mentionTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mentionTableView.bottomAnchor.constraint(equalTo: postMenuView.topAnchor),
            mentionTableViewHeightConstraint,
            
            hashtagTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hashtagTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hashtagTableView.bottomAnchor.constraint(equalTo: postMenuView.topAnchor),
            hashtagTableViewHeightConstraint
        ])

        updateConstraints()
        // keyboard
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        switch postMode {
        case .edit(let postId):
            screenViewModel.dataSource.loadPost(for: postId)
            title = AmityLocalizedStringSet.postCreationEditPostTitle.localizedString
            comunityPanelView.isHidden = true
        case .create:
            switch postTarget {
            case .community(let comunity):
                title = comunity.displayName
                comunityPanelView.isHidden = true
            case .myFeed:
                title = AmityLocalizedStringSet.postCreationMyTimelineTitle.localizedString
                comunityPanelView.isHidden = true
            }
        }
        
        mentionTableView.delegate = self
        mentionTableView.dataSource = self
        mentionManager?.delegate = self
        
        hashtagTableView.delegate = self
        hashtagTableView.dataSource = self
        hashtagTableView.tag = 1
        
        updateAttributesText()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set color navigation bar by custom theme
        theme?.setBackgroundNavigationBar()
    }
    
    public override func didTapLeftBarButton() {
        if isValueChanged {
            let alertController = UIAlertController(title: AmityLocalizedStringSet.postCreationDiscardPostTitle.localizedString, message: AmityLocalizedStringSet.postCreationDiscardPostMessage.localizedString, preferredStyle: .alert)
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
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardScreenEndFrame = keyboardValue.size
        let comunityPanelHeight = comunityPanelView.isHidden ? 0.0 : AmityComunityPanelView.defaultHeight
        if notification.name == UIResponder.keyboardWillHideNotification {
            bottomScrollViewInset = AmityPostTextEditorMenuView.defaultHeight + comunityPanelHeight + heightConstraintOfMentionHashTagTableView
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomScrollViewInset, right: 0)
            postMenuViewBottomConstraints.constant = view.layoutMargins.bottom
        } else {
            bottomScrollViewInset = keyboardScreenEndFrame.height - view.safeAreaInsets.bottom + AmityPostTextEditorMenuView.defaultHeight + comunityPanelHeight + heightConstraintOfMentionHashTagTableView
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomScrollViewInset, right: 0)
            postMenuViewBottomConstraints.constant = view.layoutMargins.bottom - keyboardScreenEndFrame.height
        }
        scrollView.scrollIndicatorInsets = scrollView.contentInset
        let selectedRange = textView.selectedRange
        textView.scrollRangeToVisible(selectedRange)
    }
    
    private func updateAttributesText() {
        let text = textView.text ?? ""
        mentionManager?.createAttributedText(text: text)
    }
    
    // MARK: - Action
    
    @objc private func onPostButtonTap() {
        guard let text = textView.text else { return }
        let medias = galleryView.medias
        let files = fileView.files
        
        view.endEditing(true)
        postButton.isEnabled = false
        let metadata = mentionManager?.getMetadata()
        let location = locationMetadata
        let mentionees = mentionManager?.getMentionees()
        if let post = currentPost {
            // update post
            screenViewModel.updatePost(oldPost: post, text: text, medias: medias, files: files, metadata: metadata, mentionees: mentionees, location: location)
        } else {
            // create post
            var communityId: String?
            if case .community(let community) = postTarget {
                communityId = community.communityId
            }
            screenViewModel.createPost(text: text, medias: medias, files: files, communityId: communityId, metadata: metadata, mentionees: mentionees, location: location)
        }
    }
    
    @objc func handleTapOnLabel(gesture: UITapGestureRecognizer) {
        // Get the location of the tap relative to the label
        let location = gesture.location(in: locationView)
        
        // Determine if the tap occurred within the bounds of the image attachment
        if let attributedString = locationView.attributedText {
            let textContainer = NSTextContainer(size: CGSize(width: locationView.bounds.width, height: CGFloat.greatestFiniteMagnitude))
            let layoutManager = NSLayoutManager()
            let textStorage = NSTextStorage(attributedString: attributedString)
            textStorage.addLayoutManager(layoutManager)
            layoutManager.addTextContainer(textContainer)
            
            let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            
            if let attachment = attributedString.attribute(.attachment, at: characterIndex, effectiveRange: nil) as? NSTextAttachment {
                // Handle the tap on the image attachment here
                self.locationView.text = nil
                self.locationView.isHidden = true
                self.locationMetadata = [:]
                self.postButton.isEnabled = true
            }
        }
    }
    
    private func updateViewState() {
        
        // Update separater state
        separaterLine.isHidden = galleryView.medias.isEmpty && fileView.files.isEmpty
        
        var isPostValid = textView.isValid
        
        // Update post button state
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
            isPostValid = isImageValid
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
            isPostValid = isFileValid
        }
        
        if let post = currentPost {
            let isTextChanged = textView.text != post.text
            let isImageChanged = galleryView.medias != post.medias
            let isDocumentChanged = fileView.files.map({ $0.id }) != post.files.map({ $0.id })
            let isLocationChanged = checkLatChangeBetween(old: post.metadata ?? [:], new: locationMetadata)
            let isPostChanged = isTextChanged || isImageChanged || isDocumentChanged || isLocationChanged
            postButton.isEnabled = isPostChanged && isPostValid
        } else {
            postButton.isEnabled = isPostValid
        }
        
        // Update postMenuView.currentAttachmentState to disable buttons based on the chosen attachment.
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
    
    func checkLatChangeBetween(old: [String: Any], new: [String: Any]) -> Bool {
        // Check if the new dictionary contains location key and it is a dictionary
        guard let newLocation = new["location"] as? [String: Any] else { return false }
        
        // Check if the old dictionary contains location key and it is a dictionary
        guard let oldLocation = old["location"] as? [String: Any],
              let oldLat = oldLocation["lat"] as? Double,
              let newLat = newLocation["lat"] as? Double else {
            return true
        }
        
        // Compare old latitude with new latitude
        return oldLat != newLat
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
        let alertController = UIAlertController(title: AmityLocalizedStringSet.postCreationUploadIncompletTitle.localizedString, message: AmityLocalizedStringSet.postCreationUploadIncompletDescription.localizedString, preferredStyle: .alert)
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
        let alertController = UIAlertController(
            title: "Maximum number of images exceeded",
            message: "Maximum number of images that can be uploaded is \(Constant.maximumNumberOfImages). The rest images will be discarded.",
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
        case .none, .comment:
            // If the user have not chosen any media yet, we allow both type to be picked.
            // After it is selected, we force the same type for the later actions.
            var mediaTypesWhenNothingSelected: [String] = []
            if settings.allowPostAttachments.contains(.image) {
                mediaTypesWhenNothingSelected.append(kUTTypeImage as String)
            }
            if settings.allowPostAttachments.contains(.video) {
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
                
                strongSelf.mediaAsset = assets
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
                strongSelf.mediaAsset = assets
                strongSelf.addMedias(medias, type: .video)
            }
        }
        
        let maxNumberOfSelection: Int
        switch postMode {
        case .create:
            maxNumberOfSelection = Constant.maximumNumberOfImages - galleryView.medias.count
        case .edit:
            maxNumberOfSelection = Constant.maximumNumberOfImages - galleryView.medias.count
        }
        
        let imagePicker = NewImagePickerController(selectedAssets: [])
        imagePicker.settings.theme.selectionStyle = .numbered
        imagePicker.settings.fetch.assets.supportedMediaTypes = supportedMediaTypes
        imagePicker.settings.selection.max = maxNumberOfSelection
        imagePicker.settings.selection.unselectOnReachingMax = false
        
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
        self.presentNewImagePicker(imagePicker, select: nil, deselect: nil, cancel: nil, finish: finish, completion: nil)
        
    }
    
    private func authorizeNew(_ authorized: @escaping () -> Void) {
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .authorized:
                DispatchQueue.main.async(execute: authorized)
            default:
                break
            }
        }
    }
}

extension AmityPostTextEditorViewController: AmityGalleryCollectionViewDelegate {
    
    func galleryView(_ view: AmityGalleryCollectionView, didRemoveImageAt index: Int) {
        var medias = galleryView.medias
        medias.remove(at: index)
        mediaAsset = medias.compactMap { $0.localAsset }
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

extension AmityPostTextEditorViewController: AmityTextViewDelegate {
    
    public func textViewDidChange(_ textView: AmityTextView) {
        updateViewState()
    }
    
    public func textView(_ textView: AmityTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView.text.count > AmityMentionManager.maximumCharacterCountForPost {
            showAlertForMaximumCharacters()
            return false
        }
        return mentionManager?.shouldChangeTextIn(textView, inRange: range, replacementText: text, currentText: textView.text) ?? true
    }
    
    public func textViewDidChangeSelection(_ textView: AmityTextView) {
        mentionManager?.changeSelection(textView)
    }
}

extension AmityPostTextEditorViewController: AmityFilePickerDelegate {
    
    func didPickFiles(files: [AmityFile]) {
        fileView.configure(files: files)
        
        // file and images are not supported posting together
        galleryView.configure(medias: [])
        updateViewState()
        uploadFiles()
        updateConstraints()
    }
    
}

extension AmityPostTextEditorViewController: AmityFileTableViewDelegate {
    
    func fileTableView(_ view: AmityFileTableView, didTapAt index: Int) {
        //
    }
    
    func fileTableViewDidDeleteData(_ view: AmityFileTableView, at index: Int) {
        updateViewState()
    }
    
    func fileTableViewDidUpdateData(_ view: AmityFileTableView) {
        updateViewState()
    }
    
    func fileTableViewDidTapViewAll(_ view: AmityFileTableView) {
        //
    }
    
}

extension AmityPostTextEditorViewController: AmityPostTextEditorScreenViewModelDelegate {
    
    func screenViewModelDidLoadPost(_ viewModel: AmityPostTextEditorScreenViewModel, post: AmityPost) {
        // This will get call once when open with edit mode
        currentPost = AmityPostModel(post: post)
        
        guard let postModel = currentPost else { return }
        
        fileView.configure(files: postModel.files)
        galleryView.configure(medias: postModel.medias)
        textView.text = postModel.text
        
        if let location = postModel.metadata?["location"] {
            locationMetadata = location as! [String : Any]
        }
        
        setupMentionManager(withPost: postModel)
        updateConstraints()
        updateViewState()
        updateLocationView(with: postModel.metadata ?? [:])
    }
    
    func screenViewModelDidCreatePost(_ viewModel: AmityPostTextEditorScreenViewModel, post: AmityPost?, error: Error?) {
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first , let error = error {
            ToastView.shared.showToast(message: error.localizedDescription, in: window)
            postButton.isEnabled = true
            return
        }
        
        if let post = post {
            
            // ktb kk save coin when post
            AmityEventHandler.shared.saveKTBCoin(v: self , type: .post, id: post.postId , reactType: nil)
            
            switch post.getFeedType() {
            case .reviewing:
                AmityAlertController.present(title: AmityLocalizedStringSet.postCreationSubmitTitle.localizedString,
                                             message: AmityLocalizedStringSet.postCreationSubmitDesc.localizedString, actions: [.ok(style: .default, handler: { [weak self] in
                                                self?.postButton.isEnabled = true
                                                self?.closeViewController()
                                             })], from: self)
            case .published, .declined:
                postButton.isEnabled = true
                closeViewController()
            @unknown default:
                break
            }
        } else {
            postButton.isEnabled = true
            closeViewController()
        }
    }
    
    func screenViewModelDidUpdatePost(_ viewModel: AmityPostTextEditorScreenViewModel, error: Error?) {
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first , let error = error {
            ToastView.shared.showToast(message: error.localizedDescription, in: window)
            postButton.isEnabled = true
        } else {
            postButton.isEnabled = true
            dismiss(animated: true, completion: nil)
        }
    }
    
    private func closeViewController() {
        if let firstVCInNavigationVC = navigationController?.viewControllers.first {
            if firstVCInNavigationVC is AmityCommunityHomePageViewController {
                navigationController?.popViewController(animated: true)
            } else {
                dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension AmityPostTextEditorViewController: AmityPostTextEditorMenuViewDelegate {
    
    func postMenuView(_ view: AmityPostTextEditorMenuView, didTap action: AmityPostMenuActionType) {
        
        switch action {
        case .camera:
            presentMediaPickerCamera()
        case .album:
            authorizeNew {
                self.presentMediaPickerAlbum(type: .image)
            }
        case .video:
            authorizeNew {
                self.presentMediaPickerAlbum(type: .video)
            }
        case .file:
            filePicker.present(from: view, files: fileView.files)
        case .expand:
            presentBottomSheetMenus()
        case .maps:
            presentMapsView()
        }
        
    }
    
    private func presentMapsView() {
        let vc = AmityGoogleMapsViewController.make()
        vc.tapDoneButton = { metadata in
            self.locationMetadata = metadata
            self.updateViewState()
            self.updateLocationView(with: metadata)
        }
        
        let navVc = UINavigationController(rootViewController: vc)
        navVc.modalPresentationStyle = .fullScreen
        present(navVc, animated: true, completion: nil)
    }
    
    func updateLocationView(with metadata: [String: Any]) {
        if let location = metadata["location"] as? [String: Any] {
            let name = location["name"] as? String ?? ""
            let address = location["address"] as? String ?? ""
            let lat = location["lat"] as? Double ?? 0.0
            let long = location["lng"] as? Double ?? 0.0
            
            self.locationView.isHidden = false
            var text = "\(name) \(address) "
            if name.isEmpty || address.isEmpty {
                text = "at \(lat), \(long) "
            }
            
            // Create an attributed string with the text
            let attributedString = NSMutableAttributedString(string: text)
                        
            let imageRightAttachment = NSTextAttachment()
            imageRightAttachment.image = AmityIconSet.iconDeleteLocation
            imageRightAttachment.bounds = CGRect(x: 0, y: 0, width: 20, height: 20) // Adjusting y position
            let attachmentRightString = NSAttributedString(attachment: imageRightAttachment)
            attributedString.append(attachmentRightString)
            
            self.locationView.attributedText = attributedString
        } else {
            // Handle the case where meta["location"] is not the expected type
            self.locationView.isHidden = true
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
            strongSelf.filePicker.present(from: strongSelf.postMenuView, files: strongSelf.fileView.files)
        }
        
        var mapOption = ImageItemOption(title: AmityLocalizedStringSet.General.location.localizedString,
                                        image: AmityIconSet.CreatePost.iconLocation,
                                          imageBackgroundColor: imageBackgroundColor) { [weak self] in
            self?.presentMapsView()
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
        
        // Each option will be added, based on allowPostAttachments.
        var items: [ImageItemOption] = []
        if settings.allowPostAttachments.contains(.image) || settings.allowPostAttachments.contains(.video) {
            items.append(cameraOption)
            items.append(galleryOption)
        }
        if settings.allowPostAttachments.contains(.file) {
            items.append(fileOption)
        }
        if settings.allowPostAttachments.contains(.video) {
            items.append(videoOption)
        }
        
        // Adding map button
        let isEnableMenu = AmityUIKitManagerInternal.shared.isEnableSocialLocation
        if isEnableMenu {
            items.append(mapOption)
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
        let totalNumberOfMedias = medias.count
        guard totalNumberOfMedias <= Constant.maximumNumberOfImages else {
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
        let alertController = UIAlertController(title: AmityLocalizedStringSet.postUnableToPostTitle.localizedString, message: AmityLocalizedStringSet.postUnableToPostDescription.localizedString, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.done.localizedString, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension AmityPostTextEditorViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

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
extension AmityPostTextEditorViewController {
    
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard isValueChanged, !(mentionManager?.isSearchingStarted ?? false) else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }

        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGestureRecognizer.translation(in: panGestureRecognizer.view)
            if translation.x > 0 && abs(translation.x) > abs(translation.y) {
                let alertController = UIAlertController(title: AmityLocalizedStringSet.postCreationDiscardPostTitle.localizedString, message: AmityLocalizedStringSet.postCreationDiscardPostMessage.localizedString, preferredStyle: .alert)
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

// MARK: - UITableViewDelegate
extension AmityPostTextEditorViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView.tag != 1 {
            return AmityMentionTableViewCell.height
        } else {
            return AmityHashtagTableViewCell.height
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.tag != 1 {
            mentionManager?.addMention(from: textView, in: textView.text, at: indexPath)
        } else {
            mentionManager?.addHashtag(from: textView, in: textView.text, at: indexPath)
        }
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView.tag != 1 {
            if indexPath.row == (mentionManager?.users.count ?? 0) - 4 {
                mentionManager?.loadMore()
            }
        } else {
            if indexPath.row == (mentionManager?.keywords.count ?? 0) - 4 {
                mentionManager?.loadMoreHashtag()
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension AmityPostTextEditorViewController: UITableViewDataSource {
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

// MARK: - AmityMentionManagerDelegate
extension AmityPostTextEditorViewController: AmityMentionManagerDelegate {
    public func didRemoveAttributedString() {
        textView.typingAttributes = [.font: AmityFontSet.body, .foregroundColor: AmityColorSet.base]
    }
    
    public func didGetHashtag(keywords: [AmityHashtagModel]) {
        if keywords.isEmpty {
            hashtagTableViewHeightConstraint.constant = 0
            heightConstraintOfMentionHashTagTableView = 0
            hashtagTableView.isHidden = true
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomScrollViewInset, right: 0)
        } else {
            heightConstraintOfMentionHashTagTableView = 240.0
            if keywords.count < 5 {
                heightConstraintOfMentionHashTagTableView = CGFloat(keywords.count) * 65
            }
            hashtagTableViewHeightConstraint.constant = heightConstraintOfMentionHashTagTableView
            hashtagTableView.isHidden = false
            hashtagTableView.reloadData()
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomScrollViewInset + heightConstraintOfMentionHashTagTableView, right: 0)
        }
        
        scrollView.scrollIndicatorInsets = scrollView.contentInset
        
        // Calculate the position of the cursor in the textView
        let cursorRect = textView.caretRect(for: textView.selectedTextRange!.start)

        // Scroll to current cursor of text view
        let rect = textView.convert(cursorRect, to: scrollView)
        scrollView.scrollRectToVisible(rect, animated: false)
    }
    
    public func didCreateAttributedString(attributedString: NSAttributedString) {
        textView.attributedText = attributedString
        textView.typingAttributes = [.font: AmityFontSet.body, .foregroundColor: AmityColorSet.base]
    }
    
    public func didGetUsers(users: [AmityMentionUserModel]) {
        if users.isEmpty {
            mentionTableViewHeightConstraint.constant = 0
            heightConstraintOfMentionHashTagTableView = 0
            mentionTableView.isHidden = true
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomScrollViewInset, right: 0)
        } else {
            heightConstraintOfMentionHashTagTableView = 240.0
            if users.count < 5 {
                heightConstraintOfMentionHashTagTableView = CGFloat(users.count) * 52.0
            }
            mentionTableViewHeightConstraint.constant = heightConstraintOfMentionHashTagTableView
            mentionTableView.isHidden = false
            mentionTableView.reloadData()
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomScrollViewInset + heightConstraintOfMentionHashTagTableView, right: 0)
        }
        
        scrollView.scrollIndicatorInsets = scrollView.contentInset
        
        // Calculate the position of the cursor in the textView
        let cursorRect = textView.caretRect(for: textView.selectedTextRange!.start)

        // Scroll to current cursor of text view
        let rect = textView.convert(cursorRect, to: scrollView)
        scrollView.scrollRectToVisible(rect, animated: false)
    }
    
    public func didMentionsReachToMaximumLimit() {
        let alertController = UIAlertController(title: AmityLocalizedStringSet.Mention.unableToMentionTitle.localizedString, message: AmityLocalizedStringSet.Mention.unableToMentionPostDescription.localizedString, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.done.localizedString, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    public func didCharactersReachToMaximumLimit() {
        showAlertForMaximumCharacters()
    }
}

// MARK: - Private methods
private extension AmityPostTextEditorViewController {
    func setupMentionManager(withPost post: AmityPostModel) {
        guard mentionManager == nil else { return }
        let communityId: String? = (currentPost?.targetCommunity?.isPublic ?? true) ? nil : currentPost?.targetCommunity?.communityId
        mentionManager = AmityMentionManager(withType: .post(communityId: communityId))
        mentionManager?.delegate = self
        mentionManager?.setColor(AmityColorSet.base, highlightColor: AmityColorSet.primary)
        mentionManager?.setFont(AmityFontSet.body, highlightFont: AmityFontSet.bodyBold)
        
        if let metadata = post.metadata {
            mentionManager?.setMentions(metadata: metadata, inText: post.text)
        }
    }
}
