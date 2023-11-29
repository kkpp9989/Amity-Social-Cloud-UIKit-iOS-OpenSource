//
//  GroupChatEditViewController.swift
//  AmityUIKit
//
//  Created by min khant on 13/05/2021.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit

class AmityGroupChatEditViewController: AmityViewController {
    
    private enum Constant {
        static let maxCharactor: Int = 100
    }

    @IBOutlet private weak var uploadButton: UIButton!
    @IBOutlet private weak var cameraImageView: UIView!
    @IBOutlet private weak var groupNameTitleLabel: UILabel!
    @IBOutlet private var nameTextField: AmityTextView!
    @IBOutlet private weak var countLabel: UILabel!
    @IBOutlet private weak var avatarView: AmityAvatarView!
    @IBOutlet private weak var groupNameSeparatorView: UIView!
    @IBOutlet private weak var avatarUploadingProgressBar: UIProgressView!
    @IBOutlet private weak var overlayView: UIView!
    
    private var screenViewModel: AmityGroupChatEditorScreenViewModelType?
    private var channelId = String()
    private var saveBarButtonItem: UIBarButtonItem!
    
    // To support reuploading image
    // use this variable to store a new image
    private var uploadingAvatarImage: UIImage?
    
    private var isValueChanged: Bool {
        guard let channel = screenViewModel?.dataSource.channel else {
            return false
        }
        let isValueChanged = (nameTextField.text != channel.displayName) || (uploadingAvatarImage != nil)
        let isValueExisted = !nameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return (isValueChanged && isValueExisted)
    }
    
    private var mockUploadProgressingTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    static func make(channelId: String) -> AmityViewController {
        let vc = AmityGroupChatEditViewController(
            nibName: AmityGroupChatEditViewController.identifier,
            bundle: AmityUIKitManager.bundle)
        vc.channelId = channelId
        return vc
    }
    
    private func updateView() {
        screenViewModel?.dataSource.getChannelEditUserPermission({ [weak self] hasPermission in
            guard let weakSelf = self else { return }
            weakSelf.nameTextField.isEditable = hasPermission
            weakSelf.uploadButton.isEnabled = hasPermission
            
            if hasPermission {
                weakSelf.setupNavigationBar()
            }
        })
    }
    
    private func setupNavigationBar() {
        saveBarButtonItem = UIBarButtonItem(title: AmityLocalizedStringSet.General.save.localizedString, style: .done, target: self, action: #selector(saveButtonTap))
        saveBarButtonItem.isEnabled = false
        // [Improvement] Add set font style to label of save button
        saveBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body,
                                                   NSAttributedString.Key.foregroundColor: AmityColorSet.primary], for: .normal)
        saveBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .disabled)
        saveBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .selected)
        
        navigationItem.rightBarButtonItem = saveBarButtonItem
    }
    
    func setupView() {
        title = AmityLocalizedStringSet.editUserProfileTitle.localizedString
        screenViewModel = AmityGroupChatEditScreenViewModel(channelId: channelId)
        screenViewModel?.delegate = self
        avatarView.placeholder = AmityIconSet.defaultGroupChat
        avatarView.bringSubviewToFront(overlayView)
        avatarUploadingProgressBar.tintColor = AmityColorSet.primary
        avatarUploadingProgressBar.setProgress(0.0, animated: true)
        overlayView.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        overlayView.isHidden = true
        cameraImageView.backgroundColor = AmityColorSet.secondary.blend(.shade4)
        cameraImageView.layer.borderColor = AmityColorSet.backgroundColor.cgColor
        cameraImageView.layer.borderWidth = 1.0
        cameraImageView.layer.cornerRadius = 14.0
        cameraImageView.clipsToBounds = true
        
        // display name
//        groupNameTitleLabel.text = AmityLocalizedStringSet.editUserProfileDisplayNameTitle.localizedString + "*" // [Original]
        groupNameTitleLabel.text = AmityLocalizedStringSet.editGroupChatProfileDisplayNameTitle.localizedString + "*" // [Custom for ONE Krungthai] Change label of displayname refer to ONE KTB figma
        groupNameTitleLabel.font = AmityFontSet.title
        groupNameTitleLabel.textColor = AmityColorSet.base
        countLabel.font = AmityFontSet.caption
        countLabel.textColor = AmityColorSet.base.blend(.shade1)
        nameTextField.customTextViewDelegate = self
        nameTextField.layer.borderWidth = 0
        nameTextField.isScrollEnabled = false
        nameTextField.textContainer.lineBreakMode = .byWordWrapping
        nameTextField.padding = .zero
        nameTextField.maxCharacters = Constant.maxCharactor
        nameTextField.maxLength = Constant.maxCharactor
        nameTextField.font = AmityFontSet.body // [Improvement] Set font style of text field
        
        // [Improvement] Set separator background
        // separator
        groupNameSeparatorView.backgroundColor = AmityColorSet.secondary.blend(.shade4)
    }
    
    @objc private func textFieldEditingChanged(_ textView: AmityTextView) {
        updateViewState()
    }
    
    private func handleImage(_ image: UIImage?) {
        uploadingAvatarImage = image
        avatarView.image = image
        updateViewState()
    }
    
    private func updateViewState() {
        saveBarButtonItem?.isEnabled = isValueChanged || uploadingAvatarImage != nil
        countLabel?.text = "\(nameTextField.text?.count ?? 0)/\(nameTextField.maxLength)"
    }
    
    @IBAction private func didTapUpload(_ sender: Any) {
        // Show camera
        var cameraOption = TextItemOption(title: AmityLocalizedStringSet.General.camera.localizedString)
        cameraOption.completion = { [weak self] in
            let cameraPicker = UIImagePickerController()
            cameraPicker.sourceType = .camera
            cameraPicker.delegate = self
            self?.present(cameraPicker, animated: true, completion: nil)
        }
        
        // Show image picker
        var galleryOption = TextItemOption(title: AmityLocalizedStringSet.General.imageGallery.localizedString)
        galleryOption.completion = { [weak self] in
            let imagePicker = AmityImagePickerController(selectedAssets: [])
            imagePicker.settings.theme.selectionStyle = .checked
            imagePicker.settings.fetch.assets.supportedMediaTypes = [.image]
            imagePicker.settings.selection.max = 1
            imagePicker.settings.selection.unselectOnReachingMax = true
            
            self?.presentAmityUIKitImagePicker(imagePicker, select: nil, deselect: nil, cancel: nil, finish: { assets in
                guard let asset = assets.first else { return }
                asset.getImage { result in
                    switch result {
                    case .success(let image):
                        self?.handleImage(image)
                    case .failure:
                        break
                    }
                }
            })
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
    
    @objc private func saveButtonTap() {
        AmityHUD.show(.loading)
        // Update user avatar
        if let avatar = uploadingAvatarImage {
//            avatarView.state = .loading // [Backup]
            // [Workaround] Mock upload avatar progressing
            // Set start progressing
            var currentProgressing: Float = 0.1
            avatarUploadingProgressBar.setProgress(currentProgressing, animated: true)
            overlayView.isHidden = false // Custom overlay for this view controller only
//            print("[Avatar] Upload progressing number: \(currentProgressing) | Start")
            // Mock progressing with random data every 1 second
            mockUploadProgressingTimer = Timer(timeInterval: 1.0, repeats: true) { timer in
                DispatchQueue.main.async {
                    let mockIncreaseProgressing: [Float] = [0.1, 0.2, 0.3]
                    currentProgressing += mockIncreaseProgressing.randomElement() ?? 0.1
                    self.avatarUploadingProgressBar.setProgress(currentProgressing, animated: true)
//                    print("[Avatar] Upload progressing number: \(currentProgressing) | Progressing")
                }
            }
            // Start add mock progressing
            RunLoop.current.add(mockUploadProgressingTimer!, forMode: .common)
            mockUploadProgressingTimer?.fire()
            Task {
                await screenViewModel?.action.update(avatar: avatar, completion: { [weak self] result in
                    guard let weakSelf = self else { return }
                    // Stop add mock progressing
                    weakSelf.mockUploadProgressingTimer?.invalidate()
                    weakSelf.mockUploadProgressingTimer = nil
                    weakSelf.avatarUploadingProgressBar.setProgress(1.0, animated: true)
//                    print("[Avatar] Upload progressing number: 1.0 | End")
                    weakSelf.overlayView.isHidden = true // Custom overlay for this view controller only
                    weakSelf.avatarUploadingProgressBar.setProgress(0.0, animated: true) // Reset to 0 for next time
    //                weakSelf.avatarView.state = .idle // [Backup]
                    
                    if result {
                        weakSelf.uploadingAvatarImage = nil
                        if weakSelf.isValueChanged {
                            weakSelf.screenViewModel?.action.update(displayName: weakSelf.nameTextField.text ?? "")
                        } else {
                            AmityHUD.show(.success(message: AmityLocalizedStringSet.HUD.successfullyUpdated.localizedString))
                            AmityChannelEventHandler.shared.channelGroupChatUpdateDidComplete(from: weakSelf)
                        }
                    } else {
                        AmityHUD.show(.error(message: AmityLocalizedStringSet.HUD.somethingWentWrong.localizedString))
                    }
                })
            }
        } else if isValueChanged {
            screenViewModel?.action.update(displayName: nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        }
    }
}

extension AmityGroupChatEditViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [weak self] in
            let image = info[.originalImage] as? UIImage
            self?.handleImage(image)
        }
    }
    
}

extension AmityGroupChatEditViewController: AmityTextViewDelegate {
    
    func textView(_ textView: AmityTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return nameTextField.verifyFields(shouldChangeCharactersIn: range, replacementString: text)
    }
    
    func textViewDidChange(_ textView: AmityTextView) {
        updateViewState()
    }
}

extension AmityGroupChatEditViewController: AmityGroupChatEditorScreenViewModelDelegate {
    
    func screenViewModelDidUpdateFailed(_ viewModel: AmityGroupChatEditorScreenViewModelType, withError error: String) {
        AmityHUD.show(.error(message: AmityLocalizedStringSet.HUD.somethingWentWrong.localizedString))
        updateViewState()
    }
    
    func screenViewModelDidUpdateSuccess(_ viewModel: AmityGroupChatEditorScreenViewModelType) {
        AmityHUD.show(.success(message: AmityLocalizedStringSet.HUD.successfullyUpdated.localizedString))
        AmityChannelEventHandler.shared.channelGroupChatUpdateDidComplete(from: self)
    }
    
    func screenViewModelDidUpdate(_ viewModel: AmityGroupChatEditorScreenViewModelType) {
        guard let channel = viewModel.dataSource.channel else { return }
        setupNavigationBar()
        nameTextField.text = channel.displayName
        if let image = uploadingAvatarImage {
            // While uploading avatar, view model will get call once with an old image.
            // To prevent image view showing an old image, checking if it nil here.
            avatarView.image = image
        } else {
            // MKL : FIX
            avatarView.setImage(withImageURL: channel.getAvatarInfo()?.fileURL ?? "",
                                placeholder: AmityIconSet.defaultGroupChat)
        }
        updateViewState()
    }
    
    func screenViewModelDidUpdateAvatarUploadingProgress(_ viewModel: AmityGroupChatEditorScreenViewModelType, progressing: Double) {
        print("[Avatar] Upload progressing number | double: \(progressing) | float: \(Float(progressing))")
        avatarUploadingProgressBar.setProgress(Float(progressing), animated: true)
    }
}
