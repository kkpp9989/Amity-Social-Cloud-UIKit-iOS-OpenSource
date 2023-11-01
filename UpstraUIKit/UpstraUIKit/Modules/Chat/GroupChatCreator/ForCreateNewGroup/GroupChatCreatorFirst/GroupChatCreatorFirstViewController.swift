//
//  GroupChatCreatorFirstViewController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 8/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import Photos
import AmitySDK

protocol GroupChatCreatorViewControllerDelegate: AnyObject {
    func tapCreateButton(channelId: String, subChannelId: String)
}

class GroupChatCreatorFirstViewController: AmityViewController {
    
    @IBOutlet private weak var userAvatarView: AmityAvatarView!
    @IBOutlet private weak var avatarButton: UIButton!
    @IBOutlet private weak var cameraImageView: UIView!
    @IBOutlet private weak var displayNameLabel: UILabel!
    @IBOutlet private weak var displayNameCounterLabel: UILabel!
    @IBOutlet private weak var displayNameTextField: AmityTextField!
    @IBOutlet private weak var displaynameSeparatorView: UIView!
    private var saveBarButtonItem: UIBarButtonItem!
    
    private var screenViewModel: GroupChatCreatorScreenViewModelType?
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    
    public var tapNextButton: ((String, String) -> Void)?

    // To support reuploading image
    // use this variable to store a new image
    private var uploadingAvatarImage: UIImage?
    
    private var selectUsersData: [AmitySelectMemberModel]
    
    open var delegate: GroupChatCreatorViewControllerDelegate?

    private var isValueChanged: Bool {
        guard let user = screenViewModel?.dataSource.user else {
            return false
        }
        let isValueChanged = (displayNameTextField.text != user.displayName) || (uploadingAvatarImage != nil)
        let isValueExisted = !displayNameTextField.text!.isEmpty
        return isValueChanged && isValueExisted
    }
    
    // [Custom for ONE Krungthai] Seperate max character each data
    private enum Constant {
        static let maxCharacterOfDisplayname: Int = 100
        static let maxCharacterOfAboutInfo: Int = 180
    }
    
    private init(_ selectUsersData: [AmitySelectMemberModel]) {
        self.screenViewModel = GroupChatCreatorScreenViewModel(selectUsersData)
        self.selectUsersData = selectUsersData
        super.init(nibName: GroupChatCreatorFirstViewController.identifier, bundle: AmityUIKitManager.bundle)
        
        title = "Group Profile"
        screenViewModel?.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public static func make(_ selectUsersData: [AmitySelectMemberModel]) -> GroupChatCreatorFirstViewController {
        return GroupChatCreatorFirstViewController(selectUsersData)
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
        saveBarButtonItem = UIBarButtonItem(title: AmityLocalizedStringSet.General.next.localizedString, style: .done, target: self, action: #selector(saveButtonTap))
        
        // [Fix defect] Set font of save button refer to AmityFontSet
        saveBarButtonItem.tintColor = AmityColorSet.primary
        saveBarButtonItem.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .normal)
        saveBarButtonItem.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .disabled)
        saveBarButtonItem.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .selected)
        
        navigationItem.rightBarButtonItem = saveBarButtonItem
    }
    
    private func setupView() {
        // avatar
        userAvatarView.placeholder = AmityIconSet.defaultGroupChat
        cameraImageView.backgroundColor = AmityColorSet.secondary.blend(.shade4)
        cameraImageView.layer.borderColor = AmityColorSet.backgroundColor.cgColor
        cameraImageView.layer.borderWidth = 1.0
        cameraImageView.layer.cornerRadius = 14.0
        cameraImageView.clipsToBounds = true
        
        // display name
        displayNameLabel.font = AmityFontSet.bodyBold
        displayNameLabel.textColor = AmityColorSet.base.blend(.shade1)
        displayNameLabel.text = "Group Name"
        
        displayNameCounterLabel.font = AmityFontSet.caption
        displayNameCounterLabel.textColor = AmityColorSet.base.blend(.shade1)
        
        displayNameTextField.delegate = self
        displayNameTextField.font = AmityFontSet.body
        displayNameTextField.borderStyle = .none
        displayNameTextField.addTarget(self, action: #selector(textFieldEditingChanged), for: .editingChanged)
        displayNameTextField.maxLength = Constant.maxCharacterOfDisplayname
        displayNameTextField.autocorrectionType = .no
        displayNameTextField.spellCheckingType = .no
        displayNameTextField.inputAccessoryView = UIView()
                
        // separator
        displaynameSeparatorView.backgroundColor = AmityColorSet.secondary.blend(.shade4)
        
        displayNameTextField.placeholder = "Enter group name"
        
        updateViewState()
    }
    
    @objc private func saveButtonTap() {
        view.endEditing(true)
		screenViewModel?.action.createChannel(displayName: displayNameTextField.text ?? "")
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
    
    @objc private func textFieldEditingChanged(_ textView: AmityTextView) {
        updateViewState()
    }
    
    private func handleImage(_ image: UIImage?) {
        if let avatar = image {
            userAvatarView.state = .loading
            screenViewModel?.action.update(avatar: avatar) { [weak self] success in
                if success {
                    AmityHUD.show(.success(message: AmityLocalizedStringSet.HUD.successfullyUpdated.localizedString))
                    self?.userAvatarView.image = avatar
                } else {
                    AmityHUD.show(.error(message: AmityLocalizedStringSet.HUD.somethingWentWrong.localizedString))
                }
                self?.userAvatarView.state = .idle
                self?.uploadingAvatarImage = image
                self?.updateViewState()
            }
        }
    }
    
    private func updateViewState() {
//        saveBarButtonItem?.isEnabled = isValueChanged
        displayNameCounterLabel?.text = "\(displayNameTextField.text?.count ?? 0)/\(displayNameTextField.maxLength)"
    }

}

extension GroupChatCreatorFirstViewController: GroupChatCreatorScreenViewModelDelegate {
	
	func screenViewModelDidCreateCommunity(_ viewModel: GroupChatCreatorScreenViewModelType, channelId: String, subChannelId: String) {
		// Do nothing ..
		// This func for Invite people from 1:1 ONLY!
	}
    
	func screenViewModelDidCreateCommunity(_ viewModel: GroupChatCreatorScreenViewModelType, builder: AmityLiveChannelBuilder) {
		let vc = AmityMemberPickerChatSecondViewController.make(liveChannelBuilder: builder, displayName: displayNameTextField.text ?? "")
		vc.tapCreateButton = { [weak self] channelId, subChannelId in
			guard let strongSelf = self else { return }
			strongSelf.tapNextButton?(channelId, subChannelId)
		}
		navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension GroupChatCreatorFirstViewController: UITextFieldDelegate {
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return displayNameTextField.verifyFields(shouldChangeCharactersIn: range, replacementString: string)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension GroupChatCreatorFirstViewController: AmityTextViewDelegate {
    
    public func textViewDidChange(_ textView: AmityTextView) {
        updateViewState()
    }
    
}

extension GroupChatCreatorFirstViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [weak self] in
            let image = info[.originalImage] as? UIImage
            self?.handleImage(image)
        }
    }
    
}
