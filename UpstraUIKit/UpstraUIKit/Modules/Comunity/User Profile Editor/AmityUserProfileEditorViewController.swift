//
//  AmityEditUserProfileViewController.swift
//  AmityUIKit
//
//  Created by Nontapat Siengsanor on 15/10/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import Photos
import UIKit

final public class AmityUserProfileEditorViewController: AmityViewController {
    
    @IBOutlet private weak var userAvatarView: AmityAvatarView!
    @IBOutlet private weak var avatarButton: UIButton!
    @IBOutlet private weak var cameraImageView: UIView!
    @IBOutlet private weak var displayNameLabel: UILabel!
    @IBOutlet private weak var displayNameCounterLabel: UILabel!
    @IBOutlet private weak var displayNameTextField: AmityTextField!
    @IBOutlet private weak var aboutLabel: UILabel!
    @IBOutlet private weak var aboutCounterLabel: UILabel!
    @IBOutlet private weak var aboutTextView: AmityTextView!
    @IBOutlet private weak var aboutSeparatorView: UIView!
    @IBOutlet private weak var displaynameSeparatorView: UIView!
    private var saveBarButtonItem: UIBarButtonItem!
    @IBOutlet private weak var avatarUploadingProgressBar: UIProgressView!
    @IBOutlet private weak var overlayView: UIView!
    
    private var screenViewModel: AmityUserProfileEditorScreenViewModelType?
    private var cacheAboutText: String = ""
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    
    // To support reuploading image
    // use this variable to store a new image
    private var uploadingAvatarImage: UIImage?
    
    private var isValueChanged: Bool {
        guard let user = screenViewModel?.dataSource.user else {
            return false
        }
        let isValueChanged = (displayNameTextField.text != user.displayName) || (aboutTextView.text != user.about) || (uploadingAvatarImage != nil)
        let isValueExisted = !displayNameTextField.text!.isEmpty
        return isValueChanged && isValueExisted
    }
    
    // [Custom for ONE Krungthai] Seperate max character each data
    private enum Constant {
        static let maxCharacterOfDisplayname: Int = 100
        static let maxCharacterOfAboutInfo: Int = 180
    }
    
    private init() {
        self.screenViewModel = AmityUserProfileEditorScreenViewModel()
        super.init(nibName: AmityUserProfileEditorViewController.identifier, bundle: AmityUIKitManager.bundle)
        
        title = AmityLocalizedStringSet.editUserProfileTitle.localizedString
        screenViewModel?.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public static func make() -> AmityUserProfileEditorViewController {
        return AmityUserProfileEditorViewController()
    }
    
    // MARK: - view's life cycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initial ONE Krungthai Custom theme
        theme = ONEKrungthaiCustomTheme(viewController: self)
        
        setupNavigationBar()
        setupView()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set color navigation bar by custom theme
        theme?.setBackgroundNavigationBar()
    }
    
    private func setupNavigationBar() {
        saveBarButtonItem = UIBarButtonItem(title: AmityLocalizedStringSet.General.save.localizedString, style: .done, target: self, action: #selector(saveButtonTap))
        
        // [Fix defect] Set font of save button refer to AmityFontSet
        saveBarButtonItem.tintColor = AmityColorSet.primary
        saveBarButtonItem.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .normal)
        saveBarButtonItem.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .disabled)
        saveBarButtonItem.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .selected)
        
        saveBarButtonItem.isEnabled = false
        navigationItem.rightBarButtonItem = saveBarButtonItem
    }
    
    private func setupView() {
        // avatar
        cameraImageView.backgroundColor = AmityColorSet.secondary.blend(.shade4)
        cameraImageView.layer.borderColor = AmityColorSet.backgroundColor.cgColor
        cameraImageView.layer.borderWidth = 1.0
        cameraImageView.layer.cornerRadius = 14.0
        cameraImageView.clipsToBounds = true
        userAvatarView.placeholder = AmityIconSet.defaultAvatar
        userAvatarView.bringSubviewToFront(overlayView)
        avatarUploadingProgressBar.tintColor = AmityColorSet.primary
        avatarUploadingProgressBar.setProgress(0.0, animated: true)
        overlayView.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        overlayView.isHidden = true
        
        // display name
        /* [Original] */
//        displayNameLabel.text = AmityLocalizedStringSet.editUserProfileDisplayNameTitle.localizedString + "*"
        /* [Custom For ONE Krungthai][Fix defect] Delete * from "Display Name" topic label | refer design from Figma */
        displayNameLabel.text = AmityLocalizedStringSet.editUserProfileDisplayNameTitle.localizedString
        displayNameLabel.font = AmityFontSet.title
        displayNameLabel.textColor = AmityColorSet.base
        
        displayNameCounterLabel.font = AmityFontSet.caption
        displayNameCounterLabel.textColor = AmityColorSet.base.blend(.shade1)
        /* [Custom For ONE Krungthai][Fix defect] Hide displayname counter lable | refer design from Figma */
        displayNameCounterLabel.isHidden = true
        
        displayNameTextField.delegate = self
        displayNameTextField.borderStyle = .none
        displayNameTextField.addTarget(self, action: #selector(textFieldEditingChanged), for: .editingChanged)
        displayNameTextField.maxLength = Constant.maxCharacterOfDisplayname
        
        // [Fix defect] Set font of displayname text field refer to AmityFontSet and set disable text field color | refer design from Figma
        displayNameTextField.font = AmityFontSet.body
        displayNameTextField.textColor = AmityColorSet.disableTextField
        
        // [Custom for ONE Krungthai] Disable display name editing for ONE Krungthai
        displayNameTextField.isUserInteractionEnabled = false
        
        // about
        aboutLabel.text = AmityLocalizedStringSet.createCommunityAboutTitle.localizedString
        aboutLabel.font = AmityFontSet.title
        aboutLabel.textColor = AmityColorSet.base
        aboutCounterLabel.font = AmityFontSet.caption
        aboutCounterLabel.textColor = AmityColorSet.base.blend(.shade1)
        aboutTextView.customTextViewDelegate = self
        aboutTextView.layer.borderWidth = 0
        aboutTextView.isScrollEnabled = false
        aboutTextView.textContainer.lineBreakMode = .byWordWrapping
        aboutTextView.padding = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        aboutTextView.maxCharacters = Constant.maxCharacterOfAboutInfo
        aboutTextView.maxLength = Constant.maxCharacterOfAboutInfo
        aboutTextView.font = AmityFontSet.body
        aboutTextView.textColor = AmityColorSet.base
        
        // separator
        aboutSeparatorView.backgroundColor = AmityColorSet.secondary.blend(.shade4)
        displaynameSeparatorView.backgroundColor = AmityColorSet.secondary.blend(.shade4)
        
        updateViewState()
    }
    
    @objc private func saveButtonTap() {
        view.endEditing(true)
        AmityHUD.show(.loading)
        
        Task { @MainActor in
            // Update display name and about data
            let newDisplayName = displayNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let newAbout = aboutTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let isUpdateTextSuccess = await screenViewModel?.action.update(displayName: newDisplayName, about: newAbout)
            
            // Check is display name and about data update fail for show error
            if let isUpdateTextSuccess, !isUpdateTextSuccess {
                AmityHUD.show(.error(message: AmityLocalizedStringSet.HUD.somethingWentWrong.localizedString))
                return
            }
            
            // Update user avatar if need
            if let avatar = uploadingAvatarImage {
                // Show overlay view and progress bar
                avatarUploadingProgressBar.setProgress(0.0, animated: true)
                overlayView.isHidden = false // Custom overlay for this view controller only
                
                // Start update user avatar
                let isUpdateAvatarSuccess = await screenViewModel?.action.update(avatar: avatar)
                
                // Hide overlay view and progress bar
                overlayView.isHidden = true // Custom overlay for this view controller only
                avatarUploadingProgressBar.setProgress(0.0, animated: true) // Reset to 0 for next time
                
                // Reset cache image and update view state
                uploadingAvatarImage = nil
                updateViewState()
                
                // Check is avatar update success for show error or success
                if let isUpdateAvatarSuccess, isUpdateAvatarSuccess {
                    AmityHUD.show(.success(message: AmityLocalizedStringSet.HUD.successfullyUpdated.localizedString))
                    AmityEventHandler.shared.didEditUserComplete(from: self)
                } else {
                    AmityHUD.show(.error(message: AmityLocalizedStringSet.HUD.somethingWentWrong.localizedString))
                }
            } else {
                // when there is no image update
                // directly show success message after updated
                AmityHUD.show(.success(message: AmityLocalizedStringSet.HUD.successfullyUpdated.localizedString))
                AmityEventHandler.shared.didEditUserComplete(from: self)
            }
        }
    }
    
    @IBAction private func avatarButtonTap(_ sender: Any) {
        view.endEditing(true)
        // Show camera
        var cameraOption = TextItemOption(title: AmityLocalizedStringSet.General.camera.localizedString)
        cameraOption.completion = { [weak self] in
            #warning("Redundancy: camera picker should be replaced with a singleton class")
            let cameraPicker = UIImagePickerController()
            cameraPicker.sourceType = .camera
            cameraPicker.delegate = self
            self?.present(cameraPicker, animated: true, completion: nil)
        }
        
        // Show image picker
        var galleryOption = TextItemOption(title: AmityLocalizedStringSet.General.imageGallery.localizedString)
        galleryOption.completion = { [weak self] in
            let imagePicker = NewImagePickerController(selectedAssets: [])
            imagePicker.settings.theme.selectionStyle = .checked
            imagePicker.settings.fetch.assets.supportedMediaTypes = [.image]
            imagePicker.settings.selection.max = 1
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
            self?.presentNewImagePicker(imagePicker, select: nil, deselect: nil, cancel: nil) { assets in
                guard let asset = assets.first else { return }
                asset.getImage { result in
                    switch result {
                    case .success(let image):
                        self?.handleImage(image)
                    case .failure:
                        break
                    }
                }
            }
        }
        
        let bottomSheet = BottomSheetViewController()
        let contentView = ItemOptionView<TextItemOption>()
        contentView.configure(items: [cameraOption, galleryOption], selectedItem: nil)
        contentView.didSelectItem = { _ in
            bottomSheet.dismissBottomSheet()
        }
        
        bottomSheet.sheetContentView = contentView
        bottomSheet.isTitleHidden = true
        bottomSheet.modalPresentationStyle = .overFullScreen
        present(bottomSheet, animated: false, completion: nil)
    }
    
    @objc private func textFieldEditingChanged(_ textView: AmityTextView) {
        updateViewState()
    }
    
    private func handleImage(_ image: UIImage?) {
        uploadingAvatarImage = image
        userAvatarView.image = image
        updateViewState()
    }
    
    private func updateViewState() {
        saveBarButtonItem?.isEnabled = isValueChanged
        displayNameCounterLabel?.text = "\(displayNameTextField.text?.count ?? 0)/\(displayNameTextField.maxLength)"
        aboutCounterLabel?.text = "\(aboutTextView.text.utf16.count)/\(aboutTextView.maxCharacters)"
    }

}

extension AmityUserProfileEditorViewController: AmityUserProfileEditorScreenViewModelDelegate {
    
    func screenViewModelDidUpdate(_ viewModel: AmityUserProfileEditorScreenViewModelType) {
        guard let user = screenViewModel?.dataSource.user else { return }
        displayNameTextField?.text = user.displayName
        aboutTextView?.text = user.about
        
        if let image = uploadingAvatarImage {
            // While uploading avatar, view model will get call once with an old image.
            // To prevent image view showing an old image, checking if it nil here.
            userAvatarView.image = image
        } else {
            userAvatarView?.setImage(withImageURL: user.avatarURL, placeholder: AmityIconSet.defaultAvatar)
        }
        
        updateViewState()
    }
    
    func screenViewModelDidUpdateAvatarUploadingProgress(_ viewModel: AmityUserProfileEditorScreenViewModelType, progressing: Double) {
//        print("[Avatar][Chat] Upload progressing number | double: \(progressing) | float: \(Float(progressing))")
        avatarUploadingProgressBar.setProgress(Float(progressing), animated: true)
    }
    
}

extension AmityUserProfileEditorViewController: UITextFieldDelegate {
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return displayNameTextField.verifyFields(shouldChangeCharactersIn: range, replacementString: string)
    }
    
}

extension AmityUserProfileEditorViewController: AmityTextViewDelegate {
    
    public func textViewDidChange(_ textView: AmityTextView) {
        updateViewState()
    }
    
}

extension AmityUserProfileEditorViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [weak self] in
            let image = info[.originalImage] as? UIImage
            self?.handleImage(image)
        }
    }
    
}
