//
//  AmityEditTextViewController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 7/8/2563 BE.
//  Copyright © 2563 Amity Communication. All rights reserved.
//

import UIKit
import AmitySDK
import Photos
import MobileCoreServices

public class AmityEditTextViewController: AmityViewController {
    
    enum EditMode {
        case create(communityId: String?, isReply: Bool)
        // Comment, Reply
        case edit(communityId: String?, metadata: [String: Any]?, isReply: Bool, comment: AmityCommentModel?)
        // Message
        case editMessage
    }
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var headerView: UIView!
    @IBOutlet private var headerLabel: UILabel!
    @IBOutlet private var textView: AmityTextView!
    @IBOutlet private var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var bottomConstraint: NSLayoutConstraint!
    @IBOutlet private var mentionTableView: AmityMentionTableView!
    @IBOutlet private var mentionTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var mentionTableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var hashtagTableView: AmityHashtagTableView!
    @IBOutlet private var hashtagTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var hashtagTableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var galleryView: AmityGalleryCollectionView!
    @IBOutlet private var galleryViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var postMenuView: AmityPostTextEditorMenuView!
    @IBOutlet private var postMenuViewBottomConstraints: NSLayoutConstraint!

    // MARK: - Properties
    private let editMode: EditMode
    private var saveBarButton: UIBarButtonItem!
    private let headerTitle: String?
    private let message: String
    var editHandler: ((String, [String: Any]?, AmityMentioneesBuilder?, [AmityMedia]?) -> Void)?
    var dismissHandler: (() -> Void)?
    private let mentionManager: AmityMentionManager
    private var metadata: [String: Any]? = nil
    private var comment: AmityCommentModel?
    
    private var media: [AmityMedia] = []
    private var mediaAsset: [PHAsset] = []
    
    private var isUploadProgress: Bool = false

    // MARK: - View lifecycle
    
    init(headerTitle: String?, text: String, editMode: EditMode, settings: AmityPostEditorSettings) {
        self.headerTitle = headerTitle
        self.message = text
        self.editMode = editMode
        self.postMenuView = AmityPostTextEditorMenuView(allowPostAttachments: settings.allowPostAttachments)
        switch editMode {
        case .editMessage:
            mentionManager = AmityMentionManager(withType: .message(channelId: nil))
        case .create(let communityId, _):
            mentionManager = AmityMentionManager(withType: .comment(communityId: communityId))
        case .edit(let communityId, let metadata, _, let comment):
            mentionManager = AmityMentionManager(withType: .comment(communityId: communityId))
            self.metadata = metadata
            self.comment = comment
        }
        super.init(nibName: AmityEditTextViewController.identifier, bundle: AmityUIKitManager.bundle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func make(headerTitle: String? = nil, text: String, editMode: EditMode, settings: AmityPostEditorSettings) -> AmityEditTextViewController {
        return AmityEditTextViewController(headerTitle: headerTitle, text: text, editMode: editMode, settings: settings)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupHeaderView()
        setupView()
        setupMentionTableView()
        setuphashtagTableView()
        setupGalleryView()
        
        mentionManager.delegate = self
        mentionManager.setColor(AmityColorSet.base, highlightColor: AmityColorSet.primary)
        mentionManager.setFont(AmityFontSet.body, highlightFont: AmityFontSet.bodyBold)
        if let metadata = metadata {
            mentionManager.setMentions(metadata: metadata, inText: message)
        }
        
        mentionManager.setHashtag(inText: message)
        
        if let _ = comment {
            extractCommentData()
        }
        
        postMenuView.translatesAutoresizingMaskIntoConstraints = false
        postMenuView.currentAttachmentState = .comment
        postMenuView.delegate = self

        // keyboard
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AmityKeyboardService.shared.delegate = self
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AmityKeyboardService.shared.delegate = nil
    }
    
    public override func didTapLeftBarButton() {
        dismissHandler?()
    }
    
    private func setupHeaderView() {
        if let header = headerTitle {
            headerView.isHidden = false
            headerView.backgroundColor = AmityColorSet.secondary.blend(.shade4)
            headerLabel.textColor = AmityColorSet.base.blend(.shade1)
            headerLabel.font = AmityFontSet.body
            headerLabel.text = header
            textView.contentInset.top = 40
        } else {
            headerView.isHidden = true
        }
    }
    
    private func setupView() {
        switch editMode {
        case .create(_, _):
            saveBarButton = UIBarButtonItem(title: AmityLocalizedStringSet.General.post.localizedString, style: .plain, target: self, action: #selector(saveTap))
            saveBarButton.isEnabled = !message.isEmpty
        case .edit, .editMessage:
            saveBarButton = UIBarButtonItem(title: AmityLocalizedStringSet.General.save.localizedString, style: .plain, target: self, action: #selector(saveTap))
            saveBarButton.isEnabled = false
        }

        saveBarButton.tintColor = AmityColorSet.primary
        saveBarButton.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .normal)
        saveBarButton.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .disabled)
        saveBarButton.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .selected)
        
        navigationItem.rightBarButtonItem = saveBarButton
        textView.text = message
        textView.placeholder = AmityLocalizedStringSet.textMessagePlaceholder.localizedString
        textView.showsVerticalScrollIndicator = false
        textView.customTextViewDelegate = self
    }
    
    private func setupMentionTableView() {
        mentionTableView.isHidden = true
        mentionTableView.delegate = self
        mentionTableView.dataSource = self
    }
    
    private func setuphashtagTableView() {
        hashtagTableView.isHidden = true
        hashtagTableView.delegate = self
        hashtagTableView.dataSource = self
    }
    
    private func setupGalleryView() {
        galleryView.translatesAutoresizingMaskIntoConstraints = false
        galleryView.actionDelegate = self
        galleryView.isEditable = true
        galleryView.isScrollEnabled = false
        galleryView.backgroundColor = AmityColorSet.backgroundColor
    }
    
    @objc private func saveTap() {
        let metadata = mentionManager.getMetadata()
        let mentionees = mentionManager.getMentionees()
        let media = galleryView.medias
        dismiss(animated: true) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.editHandler?(strongSelf.textView.text ?? "", metadata, mentionees, media)
        }
    }
    
    private func updateConstraints() {
        galleryViewHeightConstraint.constant = AmityGalleryCollectionView.height(for: galleryView.contentSize.width, numberOfItems: galleryView.medias.count)
        
        // Calculate the height of the expandable label
        let maximumLines = 0
        let actualWidth = galleryView.bounds.width - 32
        let text = textView.text ?? ""
        let messageHeight = AmityTextView.height(for: text, font: AmityFontSet.body, boundingWidth: actualWidth, maximumLines: maximumLines)
        
//        textViewHeightConstraint.constant = messageHeight < 0 ? 300 : messageHeight
    }
    
    private func showAlertForMaximumCharacters() {
        var title = AmityLocalizedStringSet.postUnableToCommentTitle.localizedString
        var message = AmityLocalizedStringSet.postUnableToCommentDescription.localizedString
        switch editMode {
        case .edit(_, _, let isReply, _), .create(_, let isReply):
            title = isReply ? AmityLocalizedStringSet.postUnableToReplyTitle.localizedString : AmityLocalizedStringSet.postUnableToCommentTitle.localizedString
            message = isReply ? AmityLocalizedStringSet.postUnableToReplyDescription.localizedString : AmityLocalizedStringSet.postUnableToCommentDescription.localizedString
        default:
            break
        }
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.done.localizedString, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func updateViewState() {
        // Update separater state
//        separaterLine.isHidden = galleryView.medias.isEmpty && fileView.files.isEmpty
        
        var isPostValid = textView.isValid
        
        // Update post button state
        var isImageValid = false
        if !galleryView.medias.isEmpty {
            isImageValid = !galleryView.medias.allSatisfy({
                switch $0.state {
                case .downloadableImage, .downloadableVideo:
                    return true
                default:
                    return false
                }
            })
            isPostValid = isImageValid
        }
        
        if !isUploadProgress {
            if let comment = comment {
                let isTextChanged = textView.text != comment.text
                //            let isImageChanged = galleryView.medias != comment.comment
                //            let isPostChanged = isTextChanged || isImageChanged
                saveBarButton.isEnabled = isTextChanged || isPostValid
            } else {
                saveBarButton.isEnabled = isPostValid
            }
        }
        
        // Update postMenuView.currentAttachmentState to disable buttons based on the chosen attachment.
        if galleryView.medias.contains(where: { $0.type == .image }) {
            postMenuView.currentAttachmentState = .comment
        } else {
            postMenuView.currentAttachmentState = .none
        }
        
        if textView.text.isEmpty {
            textView.textColor = AmityColorSet.base
        }
    }
    
    private func extractCommentData() {
        // Get images/files for post if any
        if let comment = comment {
            let commentData = comment.comment
            let attachments = commentData.attachments
            for aChild in attachments {
                switch aChild {
                case .image(let fileId, let imageData) :
                    let placeholder = AmityColorSet.base.blend(.shade4).asImage()
                    if let imageData = imageData {
                        let state = AmityMediaState.downloadableImage(
                            imageData: imageData,
                            placeholder: placeholder
                        )
                        let media = AmityMedia(state: state, type: .image)
                        galleryView.configure(medias: [media])
                        self.media.append(media)
                    }
                @unknown default:
                    break
                }
            }
        }
        
        updateConstraints()
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardScreenEndFrame = keyboardValue.size
        if notification.name == UIResponder.keyboardWillHideNotification {
//            bottomScrollViewInset = AmityPostTextEditorMenuView.defaultHeight + comunityPanelHeight + heightConstraintOfMentionHashTagTableView
//            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomScrollViewInset, right: 0)
            postMenuViewBottomConstraints.constant = view.layoutMargins.bottom - 18
        } else {
//            bottomScrollViewInset = keyboardScreenEndFrame.height - view.safeAreaInsets.bottom + AmityPostTextEditorMenuView.defaultHeight + comunityPanelHeight + heightConstraintOfMentionHashTagTableView
//            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomScrollViewInset, right: 0)
            postMenuViewBottomConstraints.constant = view.layoutMargins.bottom - keyboardScreenEndFrame.height
        }
//        scrollView.scrollIndicatorInsets = scrollView.contentInset
        let selectedRange = textView.selectedRange
        textView.scrollRangeToVisible(selectedRange)
    }
    
    // MARK: Helper functions
    
    private func uploadImages() {
        let fileUploadFailedDispatchGroup = DispatchGroup()
        var isUploadFailed = false
        isUploadProgress = true
        saveBarButton.isEnabled = false
        galleryView.isUserInteractionEnabled = false
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
                                self?.galleryView.isUserInteractionEnabled = true
                                isUploadFailed = true
                            }
                            fileUploadFailedDispatchGroup.leave()
                            self?.saveBarButton.isEnabled = false
                            self?.isUploadProgress = false
                            self?.updateViewState()
                        })
                    case .failure:
                        media.state = .error
                        self?.galleryView.updateViewState(for: media.id, state: .error)
                        self?.updateViewState()
                        self?.isUploadProgress = false
                        isUploadFailed = true
                    }
                }
            default:
                Log.add("[UIKit]: Unsupported media state for uploading.")
                self.isUploadProgress = false
                break
            }
        }
        
        fileUploadFailedDispatchGroup.notify(queue: .main) { [weak self] in
            if isUploadFailed && self?.presentedViewController == nil {
                self?.isUploadProgress = false
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
    
    private func presentMaxNumberReachDialogue() {
        let alertController = UIAlertController(
            title: "Maximum number of images exceeded",
            message: "Maximum number of images that can be uploaded is 1. The rest images will be discarded.",
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
        cameraPicker.mediaTypes = [kUTTypeImage as String]
        
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
        switch editMode {
        case .create:
            maxNumberOfSelection = 1
        case .edit:
            maxNumberOfSelection = 1 //- galleryView.medias.count
        case .editMessage:
            maxNumberOfSelection = 1 //- galleryView.medias.count
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
        self.presentNewImagePicker(imagePicker, select: nil, deselect: nil, cancel: nil, finish: finish, completion: nil)
    }
}

extension AmityEditTextViewController: AmityPostTextEditorMenuViewDelegate {
    
    func postMenuView(_ view: AmityPostTextEditorMenuView, didTap action: AmityPostMenuActionType) {
        
        switch action {
        case .camera:
            presentMediaPickerCamera()
        case .album:
            presentMediaPickerAlbum(type: .image)
        default:
            break
        }
    }
    
    private func addMedias(_ medias: [AmityMedia], type: AmityMediaType) {
//        let totalNumberOfMedias = medias.count
//        guard totalNumberOfMedias <= 1 else {
//            presentMaxNumberReachDialogue()
//            return
//        }
        galleryView.replaceMedias(medias)
        // start uploading
        updateViewState()
        switch type {
        case .image:
            uploadImages()
        case .video:
            break
        }
        updateConstraints()
    }
}

extension AmityEditTextViewController: AmityGalleryCollectionViewDelegate {
    
    func galleryView(_ view: AmityGalleryCollectionView, didRemoveImageAt index: Int) {
        var medias = galleryView.medias
        medias.remove(at: index)
//        mediaAsset = medias.compactMap { $0.localAsset }
        galleryView.configure(medias: medias)
        updateViewState()
    }
    
    func galleryView(_ view: AmityGalleryCollectionView, didTapMedia media: AmityMedia, reference: UIImageView) {
    }
}

extension AmityEditTextViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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

extension AmityEditTextViewController: AmityKeyboardServiceDelegate {
    func keyboardWillChange(service: AmityKeyboardService, height: CGFloat, animationDuration: TimeInterval) {
        let offset = height > 0 ? view.safeAreaInsets.bottom : 0
        let constant = -height + offset
        bottomConstraint.constant = constant
        mentionTableViewBottomConstraint.constant = constant
        hashtagTableViewBottomConstraint.constant = constant

        view.setNeedsUpdateConstraints()
        view.layoutIfNeeded()
    }
}

extension AmityEditTextViewController: AmityTextViewDelegate {
    public func textViewDidChange(_ textView: AmityTextView) {
        guard let text = textView.text else { return }
//        saveBarButton.isEnabled = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.attributedText = nil
            textView.textColor = AmityColorSet.base
        }
        
        updateConstraints()
        updateViewState()
    }
    
    public func textViewDidChangeSelection(_ textView: AmityTextView) {
        mentionManager.changeSelection(textView)
    }
    
    public func textView(_ textView: AmityTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView.text.count > AmityMentionManager.maximumCharacterCountForPost {
            showAlertForMaximumCharacters()
            return false
        }
        return mentionManager.shouldChangeTextIn(textView, inRange: range, replacementText: text, currentText: textView.text)
    }
}

// MARK: - UITableViewDataSource
extension AmityEditTextViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mentionManager.users.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag != 1 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: AmityMentionTableViewCell.identifier) as? AmityMentionTableViewCell, let model = mentionManager.item(at: indexPath) else { return UITableViewCell() }
            cell.display(with: model)
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: AmityHashtagTableViewCell.identifier) as? AmityHashtagTableViewCell, let model = mentionManager.itemHashtag(at: indexPath) else { return UITableViewCell() }
            cell.display(with: model)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension AmityEditTextViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView.tag != 1 {
            return AmityMentionTableViewCell.height
        } else {
            return AmityHashtagTableViewCell.height
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.tag != 1 {
            mentionManager.addMention(from: textView, in: textView.text, at: indexPath)
        } else {
            mentionManager.addHashtag(from: textView, in: textView.text, at: indexPath)
        }
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView.tag != 1 {
            if tableView.isBottomReached {
                mentionManager.loadMore()
            }
        } else {
            if tableView.isBottomReached {
                mentionManager.loadMoreHashtag()
            }
        }
    }
}

// MARK: - AmityMentionManagerDelegate
extension AmityEditTextViewController: AmityMentionManagerDelegate {
    public func didRemoveAttributedString() {
        textView.typingAttributes = [.font: AmityFontSet.body, .foregroundColor: AmityColorSet.base]
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
        textView.attributedText = attributedString
        textView.typingAttributes = [.font: AmityFontSet.body, .foregroundColor: AmityColorSet.base]
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
}
