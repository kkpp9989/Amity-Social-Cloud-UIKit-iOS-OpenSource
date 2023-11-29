//
//  GroupChatCreatorSecondViewController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 8/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import Photos
import AmitySDK

protocol GroupChatCreatorSecondViewControllerDelegate: AnyObject {
	func tapCreateButton(channelId: String, subChannelId: String)
}

class GroupChatCreatorSecondViewController: AmityViewController {
	
	@IBOutlet private weak var userAvatarView: AmityAvatarView!
	@IBOutlet private weak var avatarButton: UIButton!
	@IBOutlet private weak var cameraImageView: UIView!
	@IBOutlet private weak var displayNameLabel: UILabel!
	@IBOutlet private weak var displayNameCounterLabel: UILabel!
	@IBOutlet private weak var displayNameTextField: AmityTextField!
	@IBOutlet private weak var displaynameSeparatorView: UIView!
	private var saveBarButtonItem: UIBarButtonItem!
    @IBOutlet private weak var avatarUploadingProgressBar: UIProgressView!
    @IBOutlet private weak var overlayView: UIView!
    
    private var mockUploadProgressingTimer: Timer?
	
	private var screenViewModel: GroupChatCreatorScreenViewModelType?
	
	// MARK: - Custom Theme Properties [Additional]
	private var theme: ONEKrungthaiCustomTheme?
	
	public var tapCreateButton: ((String, String) -> Void)?

	// To support reuploading image
	// use this variable to store a new image
	private var uploadingAvatarImage: UIImage?
	
	private var selectUsersData: [AmitySelectMemberModel]
	
	open var delegate: GroupChatCreatorViewControllerDelegate?

	private var isValueChanged: Bool {
        let isValueExisted = !displayNameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		return isValueExisted
	}
	
	// [Custom for ONE Krungthai] Seperate max character each data
	private enum Constant {
		static let maxCharacterOfDisplayname: Int = 100
		static let maxCharacterOfAboutInfo: Int = 180
	}
	
	private init(_ selectUsersData: [AmitySelectMemberModel]) {
		self.screenViewModel = GroupChatCreatorScreenViewModel(selectUsersData)
		self.selectUsersData = selectUsersData
		super.init(nibName: GroupChatCreatorSecondViewController.identifier, bundle: AmityUIKitManager.bundle)
		
		title = "Group Profile"
		screenViewModel?.delegate = self
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	public static func make(_ selectUsersData: [AmitySelectMemberModel]) -> GroupChatCreatorSecondViewController {
		return GroupChatCreatorSecondViewController(selectUsersData)
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
		saveBarButtonItem = UIBarButtonItem(title: "Create", style: .done, target: self, action: #selector(saveButtonTap))
		
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
        userAvatarView.bringSubviewToFront(overlayView)
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
		
		let combinedDisplayName = selectUsersData.map { $0.displayName ?? "" }.joined(separator: ", ")
		displayNameTextField.placeholder = "Enter group name"
		
		updateViewState()
	}
	
	@objc private func saveButtonTap() {
		view.endEditing(true)
		
		// Update display name and about
        screenViewModel?.createChannel(users: selectUsersData, displayName: displayNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
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
//			userAvatarView.state = .loading // [Backup]
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
                await screenViewModel?.action.update(avatar: avatar) { [weak self] success in// Stop add mock progressing
                    self?.mockUploadProgressingTimer?.invalidate()
                    self?.mockUploadProgressingTimer = nil
                    self?.avatarUploadingProgressBar.setProgress(1.0, animated: true)
//                    print("[Avatar] Upload progressing number: 1.0 | End")
                    self?.overlayView.isHidden = true // Custom overlay for this view controller only
                    self?.avatarUploadingProgressBar.setProgress(0.0, animated: true) // Reset to 0 for next time
                    
                    if success {
                        AmityHUD.show(.success(message: AmityLocalizedStringSet.HUD.successfullyUpdated.localizedString))
                        self?.userAvatarView.image = avatar
                    } else {
                        AmityHUD.show(.error(message: AmityLocalizedStringSet.HUD.somethingWentWrong.localizedString))
                    }
//                    self?.userAvatarView.state = .idle
                    self?.uploadingAvatarImage = image
                    self?.updateViewState()
                }
            }
		}
	}
	
	private func updateViewState() {
        saveBarButtonItem?.isEnabled = isValueChanged
		displayNameCounterLabel?.text = "\(displayNameTextField.text?.count ?? 0)/\(displayNameTextField.maxLength)"
	}

}

extension GroupChatCreatorSecondViewController: GroupChatCreatorScreenViewModelDelegate {
	func screenViewModelDidCreateCommunity(_ viewModel: GroupChatCreatorScreenViewModelType, builder: AmitySDK.AmityCommunityChannelBuilder) {
		// Do nothing ..
		// This func for Create New Group ONLY!
	}
	
	
	func screenViewModelDidCreateCommunity(_ viewModel: GroupChatCreatorScreenViewModelType, channelId: String, subChannelId: String) {
		dismiss(animated: true) { [weak self] in
			guard let strongSelf = self else { return }
			strongSelf.tapCreateButton?(channelId, subChannelId)
		}
	}
    
    func screenViewModelDidUpdateAvatarUploadingProgress(_ viewModel: GroupChatCreatorScreenViewModelType, progressing: Double) {
        print("[Avatar] Upload progressing number | double: \(progressing) | float: \(Float(progressing))")
        avatarUploadingProgressBar.setProgress(Float(progressing), animated: true)
    }
	
}

extension GroupChatCreatorSecondViewController: UITextFieldDelegate {
	
	public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		return displayNameTextField.verifyFields(shouldChangeCharactersIn: range, replacementString: string)
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
}

extension GroupChatCreatorSecondViewController: AmityTextViewDelegate {
	
	public func textViewDidChange(_ textView: AmityTextView) {
		updateViewState()
	}
	
}

extension GroupChatCreatorSecondViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
	
	public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		picker.dismiss(animated: true) { [weak self] in
			let image = info[.originalImage] as? UIImage
			self?.handleImage(image)
		}
	}
	
}
