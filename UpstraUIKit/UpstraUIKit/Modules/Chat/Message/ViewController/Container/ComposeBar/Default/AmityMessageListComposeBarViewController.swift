//
//  AmityMessageListComposeBarViewController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 30/10/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit

protocol AmityMessageListComposeBarDelegate: AnyObject {
	func composeView(_ view: AmityTextComposeBarView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
	func composeViewDidChangeSelection(_ view: AmityTextComposeBarView)
    func composeViewDidCancelForwardMessage()
    func composeViewDidSelectForwardMessage()
    func composeViewDidSelectJoinChannel()
	func sendMessageTap()
}

final class AmityMessageListComposeBarViewController: UIViewController {

    // MARK: - IBOutlet Properties
    @IBOutlet var textComposeBarView: AmityTextComposeBarView!
    @IBOutlet var sendMessageButton: UIButton!
    @IBOutlet private var showKeyboardComposeBarButton: UIButton!
    @IBOutlet private var showAudioButton: UIButton!
    @IBOutlet private var showDefaultKeyboardButton: UIButton!
    @IBOutlet var recordButton: AmityRecordingButton!
    @IBOutlet private var trailingStackView: UIStackView!
    @IBOutlet var separatorView: UIView!
    @IBOutlet var inputMenuView: UIStackView!
    
    // Forward menu view
    @IBOutlet var forwardMenuView: UIStackView!
    @IBOutlet private var cancelForwardButton: UIButton!
    @IBOutlet private var forwardButton: UIButton!
    
    // Join menu view
    @IBOutlet var joinMenuView: UIStackView!
    @IBOutlet private var joinButton: UIButton!
    
    // Open editor view
    @IBOutlet var openEditorMenuView: UIStackView!
    @IBOutlet var textTypeActionButton: UIButton!
    @IBOutlet private var otherTypeActionButton: UIButton!
    
    // MARK: - Properties
	weak var delegate: AmityMessageListComposeBarDelegate?
    private var screenViewModel: AmityMessageListScreenViewModelType!
    let composeBarView = AmityKeyboardComposeBarViewController.make()
    var amountForwardMessage: Int = 0
    var isReplying: Bool = false
    var isGetChannelSuccess: Bool = false
    
    // MARK: - Settings
    private var setting = AmityMessageListViewController.Settings()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
	static func make(viewModel: AmityMessageListScreenViewModelType,
					 setting: AmityMessageListViewController.Settings,
					 delegate: AmityMessageListComposeBarDelegate?) -> AmityMessageListComposeBarViewController {
        let vc = AmityMessageListComposeBarViewController(
            nibName: AmityMessageListComposeBarViewController.identifier,
            bundle: AmityUIKitManager.bundle)
        vc.screenViewModel = viewModel
        vc.setting = setting
		vc.delegate = delegate
        return vc
    }
    
    // MARK: - Forward Message Action
    @IBAction func forwardTap(_ sender: UIButton) {
        delegate?.composeViewDidSelectForwardMessage()
    }
    
    @IBAction func cancelForwardTap(_ sender: UIButton) {
        showForwardMenuButton(show: false)
        delegate?.composeViewDidCancelForwardMessage()
    }
    
    @IBAction func joinChannelTap(_ sender: UIButton) {
        delegate?.composeViewDidSelectJoinChannel()
    }
}

// MARK: - Action
private extension AmityMessageListComposeBarViewController {
    
    @IBAction func sendMessageTap() {
        if textComposeBarView.textView.text.count <= 10000 {
            delegate?.sendMessageTap()
            clearText()
        } else {
            let alertController = UIAlertController(title: AmityLocalizedStringSet.Chat.chatUnableToChatTitle.localizedString, message: AmityLocalizedStringSet.Chat.chatUnableToChatDescription.localizedString, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.ok.localizedString, style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func showKeyboardComposeBarTap() {
        screenViewModel.action.toggleInputSource()
        showRecordButton(show: false)
    }
    
    @IBAction func toggleDefaultKeyboardAndAudioKeyboardTap(_ sender: UIButton) {
        AmityAudioRecorder.shared.requestPermission()
        screenViewModel.action.toggleShowDefaultKeyboardAndAudioKeyboard(sender)
    }
    
    @IBAction func textTypeActionButtonTap() {
        let channelType = screenViewModel.dataSource.getChannelType()
        switch channelType {
        case .broadcast:
            screenViewModel.action.toggleOpenCreateBroadcastMessageEditor(type: .content)
        default:
            break
        }
    }
    
    @IBAction func otherTypeActionButtonTap() {
        let channelType = screenViewModel.dataSource.getChannelType()
        switch channelType {
        case .broadcast:
            screenViewModel.action.toggleOpenCreateBroadcastMessageEditor(type: .file)
        default:
            break
        }
    }
    
    // MARK: - Audio Recording
    @IBAction func touchDown(sender: AmityRecordingButton) {
        AmityAudioRecorder.shared.checkPermission { [weak self] isAllowed, error in
            guard let isAllowed = isAllowed else { return }
            if isAllowed {
                self?.screenViewModel.action.performAudioRecordingEvents(for: .show)
            } else {
                self?.screenViewModel.action.performAudioRecordingEvents(for: .permissionDenied)
            }
        }
    }
}

// MARK: - Setup View
private extension AmityMessageListComposeBarViewController {
    
    func setupView() {
        setupTextComposeBarView()
        setupSendMessageButton()
        setupShowKeyboardComposeBarButton()
        setupLeftItems()
        setupRecordButton()
        setupForwardMenuView()
        setupJoinChannelButton()
        setupOpenEditorMenuView()
    }
    
    func setupTextComposeBarView() {
		textComposeBarView.delegate = self
        textComposeBarView.placeholder = AmityLocalizedStringSet.textMessagePlaceholder.localizedString
        textComposeBarView.textViewDidChanged = { [weak self] text in
            if text.count >= 10000 {
                let alertController = UIAlertController(title: AmityLocalizedStringSet.Chat.chatUnableToChatTitle.localizedString, message: AmityLocalizedStringSet.Chat.chatUnableToChatDescription.localizedString, preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.ok.localizedString, style: .cancel, handler: nil)
                alertController.addAction(cancelAction)
                self?.present(alertController, animated: true, completion: nil)
            } else {
                self?.screenViewModel.action.setText(withText: text)
            }
        }
        
        textComposeBarView.textViewShouldBeginEditing = { [weak self] textView in
            self?.screenViewModel.action.toggleKeyboardVisible(visible: true)
            self?.screenViewModel.action.inputSource(for: .default)
        }
        
        /* [Custom for ONE Krungthai] Set separator color refer to ONE KTB figma */
        separatorView.backgroundColor = AmityColorSet.secondary.blend(.shade4)
    }
    
    func setupOpenEditorMenuView() {
        /** Setup view **/
        openEditorMenuView.isHidden = false
        
        /** Setup text type action button **/
        textTypeActionButton.backgroundColor = AmityColorSet.secondary.blend(.shade4)
        textTypeActionButton.layer.borderWidth = 1
        textTypeActionButton.layer.borderColor = AmityColorSet.secondary.blend(.shade4).cgColor
        textTypeActionButton.layer.cornerRadius = textTypeActionButton.frame.height / 2
        textTypeActionButton.contentHorizontalAlignment = .left
        textTypeActionButton.setAttributedTitle(NSAttributedString(string: AmityLocalizedStringSet.textBroadcastMessagePlaceholder.localizedString, attributes: [
            .foregroundColor: AmityColorSet.secondary.blend(.shade3),
            .font: AmityFontSet.body
        ]), for: .normal)
        
        /** Setup other type action button **/
        otherTypeActionButton.setTitle(nil, for: .normal)
        otherTypeActionButton.setImage(AmityIconSet.iconAttach, for: .normal)
        otherTypeActionButton.tintColor = AmityColorSet.base.blend(.shade1)
        otherTypeActionButton.isHidden = false
    }
    
    func setupForwardMenuView() {
        // Set view to hidden at start
        forwardMenuView.isHidden = true
        
        // Set cancel button
        cancelForwardButton.backgroundColor = AmityColorSet.baseInverse
        cancelForwardButton.layer.borderColor = AmityColorSet.secondary.blend(.shade4).cgColor
        cancelForwardButton.layer.borderWidth = 1
        cancelForwardButton.layer.cornerRadius = 18 // Base on font size 15
        cancelForwardButton.setAttributedTitle(NSAttributedString(string: AmityLocalizedStringSet.General.cancel.localizedString, attributes: [
            .foregroundColor: AmityColorSet.base,
            .font: AmityFontSet.bodyBold
        ]), for: .normal)
        cancelForwardButton.setAttributedTitle(NSAttributedString(string: AmityLocalizedStringSet.General.cancel.localizedString, attributes: [
            .foregroundColor: AmityColorSet.base,
            .font: AmityFontSet.bodyBold
        ]), for: .disabled)
        cancelForwardButton.setAttributedTitle(NSAttributedString(string: AmityLocalizedStringSet.General.cancel.localizedString, attributes: [
            .foregroundColor: AmityColorSet.base,
            .font: AmityFontSet.bodyBold
        ]), for: .selected)
        
        // Set forward button
        forwardButton.backgroundColor = UIColor(hex: "B2EAFF")
        forwardButton.layer.cornerRadius = 18 // Base on font size 15
        forwardButton.setAttributedTitle(NSAttributedString(string: AmityLocalizedStringSet.General.share.localizedString, attributes: [
            .foregroundColor: AmityColorSet.baseInverse,
            .font: AmityFontSet.bodyBold
        ]), for: .normal)
        forwardButton.setAttributedTitle(NSAttributedString(string: AmityLocalizedStringSet.General.share.localizedString, attributes: [
            .foregroundColor: AmityColorSet.baseInverse,
            .font: AmityFontSet.bodyBold
        ]), for: .disabled)
        forwardButton.setAttributedTitle(NSAttributedString(string: AmityLocalizedStringSet.General.share.localizedString, attributes: [
            .foregroundColor: AmityColorSet.baseInverse,
            .font: AmityFontSet.bodyBold
        ]), for: .selected)
        forwardButton.isEnabled = false
    }
    
    func setupSendMessageButton() {
        sendMessageButton.setTitle(nil, for: .normal)
        sendMessageButton.setImage(AmityIconSet.iconSendMessage, for: .normal)
        sendMessageButton.isEnabled = false
        sendMessageButton.isHidden = true
    }
    
    func setupJoinChannelButton() {
        joinButton.backgroundColor = AmityColorSet.primary
        joinButton.layer.cornerRadius = 18
        joinButton.setImage(AmityIconSet.iconAddWhite, for: .normal)
        joinButton.setAttributedTitle(NSAttributedString(string: AmityLocalizedStringSet.communityDetailJoinButton.localizedString, attributes: [
            .foregroundColor: UIColor.white,
            .font: AmityFontSet.bodyBold
        ]), for: .normal)
        joinButton.clipsToBounds = true
    }
    
    func setupShowKeyboardComposeBarButton() {
        showKeyboardComposeBarButton.setTitle(nil, for: .normal)
        showKeyboardComposeBarButton.setImage(AmityIconSet.iconAdd, for: .normal)
        showKeyboardComposeBarButton.tintColor = AmityColorSet.base.blend(.shade1)
        showKeyboardComposeBarButton.isHidden = false
    }
    
    func setupLeftItems() {
        showAudioButton.isHidden = setting.shouldHideAudioButton
        showAudioButton.setImage(AmityIconSet.Chat.iconVoiceMessageGrey, for: .normal)
        showAudioButton.tag = 0
        
        showDefaultKeyboardButton.isHidden = true
        showDefaultKeyboardButton.setImage(AmityIconSet.Chat.iconKeyboard, for: .normal)
        showDefaultKeyboardButton.tag = 1
    }
    
    func setupRecordButton() {
        recordButton.layer.cornerRadius = 4
        recordButton.backgroundColor = AmityColorSet.secondary.blend(.shade4)
        recordButton.titleLabel?.font = AmityFontSet.bodyBold
        recordButton.setTitleColor(AmityColorSet.base, for: .normal)
        recordButton.setImage(AmityIconSet.Chat.iconMic, for: .normal)
        /* [Custom for ONE Krungthai] Change wording of record button to "Tap to record" */
//        recordButton.setTitle(AmityLocalizedStringSet.MessageList.holdToRecord.localizedString, for: .normal) // [Original]
        recordButton.setTitle(AmityLocalizedStringSet.MessageList.tapToRecord.localizedString, for: .normal)
        recordButton.tintColor = AmityColorSet.base
        recordButton.isHidden = true
        
        recordButton.deleteHandler = { [weak self] in
            self?.screenViewModel.action.performAudioRecordingEvents(for: .delete)
        }
        
        recordButton.recordHandler = { [weak self] in
            self?.screenViewModel.action.performAudioRecordingEvents(for: .record)
        }
        
        recordButton.deletingHandler = { [weak self] in
            self?.screenViewModel.action.performAudioRecordingEvents(for: .deleting)
        }
        
        recordButton.recordingHandler = { [weak self] in
            self?.screenViewModel.action.performAudioRecordingEvents(for: .cancelingDelete)
        }
    }
}

extension AmityMessageListComposeBarViewController: AmityComposeBar {
    
	var textView: AmityTextView {
		get {
			textComposeBarView.textView
		}
		set {
			textComposeBarView.textView = newValue
		}
	}
    
    func updateViewDidReplyProcess(isReplying: Bool) {
        self.isReplying = isReplying
        
        if isReplying {
            showAudioButton.isHidden = true
            showKeyboardComposeBarButton.isHidden = true
        } else {
            showAudioButton.isHidden = false
            showKeyboardComposeBarButton.isHidden = sendMessageButton.isHidden ? false : true
        }
    }
    
    func updateViewDidTextChanged(_ text: String) {
        sendMessageButton.isEnabled = !text.isEmpty
        showKeyboardComposeBarButton.isHidden = !text.isEmpty || isReplying
        sendMessageButton.isHidden = text.isEmpty
    }
    
    func updateViewDidMuteOrStopChannelStatusChanged(isCanInteract: Bool) {
        if isCanInteract {
            view.isUserInteractionEnabled = true
            textComposeBarView.placeholder = AmityLocalizedStringSet.textMessagePlaceholder.localizedString
        } else {
            view.isUserInteractionEnabled = false
            textComposeBarView.placeholder = AmityLocalizedStringSet.textMessagePlaceholderMuted.localizedString
            textComposeBarView.text = nil
        }
    }
    
    func showForwardMenuButton(show: Bool) {
        if show {
            inputMenuView.isHidden = true
            openEditorMenuView.isHidden = true
            forwardMenuView.isHidden = false
        } else {
            inputMenuView.isHidden = screenViewModel.dataSource.getChannelType() == .broadcast
            openEditorMenuView.isHidden = !(screenViewModel.dataSource.getChannelType() == .broadcast)
            forwardMenuView.isHidden = true
        }
    }
    
    func updateViewDidSelectForwardMessage(amount: Int) {
        if amount > 0 {
            forwardButton.isEnabled = true
            forwardButton.backgroundColor = AmityColorSet.primary
            forwardButton.setAttributedTitle(NSAttributedString(string: AmityLocalizedStringSet.General.share.localizedString + " (\(amount))", attributes: [
                .foregroundColor: AmityColorSet.baseInverse,
                .font: AmityFontSet.bodyBold
            ]), for: .normal)
            forwardButton.setAttributedTitle(NSAttributedString(string: AmityLocalizedStringSet.General.share.localizedString + " (\(amount))", attributes: [
                .foregroundColor: AmityColorSet.baseInverse,
                .font: AmityFontSet.bodyBold
            ]), for: .disabled)
            forwardButton.setAttributedTitle(NSAttributedString(string: AmityLocalizedStringSet.General.share.localizedString + " (\(amount))", attributes: [
                .foregroundColor: AmityColorSet.baseInverse,
                .font: AmityFontSet.bodyBold
            ]), for: .selected)
        } else {
            forwardButton.isEnabled = false
            forwardButton.backgroundColor = UIColor(hex: "B2EAFF")
            forwardButton.setAttributedTitle(NSAttributedString(string: AmityLocalizedStringSet.General.share.localizedString, attributes: [
                .foregroundColor: AmityColorSet.baseInverse,
                .font: AmityFontSet.bodyBold
            ]), for: .normal)
            forwardButton.setAttributedTitle(NSAttributedString(string: AmityLocalizedStringSet.General.share.localizedString, attributes: [
                .foregroundColor: AmityColorSet.baseInverse,
                .font: AmityFontSet.bodyBold
            ]), for: .disabled)
            forwardButton.setAttributedTitle(NSAttributedString(string: AmityLocalizedStringSet.General.share.localizedString, attributes: [
                .foregroundColor: AmityColorSet.baseInverse,
                .font: AmityFontSet.bodyBold
            ]), for: .selected)
        }
    }
    
    func updateViewDidGetChannel(channel: AmityChannelModel) {
        if !isGetChannelSuccess {
            let channelType = screenViewModel.dataSource.getChannelType()
            switch channelType {
            case .broadcast:
                inputMenuView.isHidden = true
                openEditorMenuView.isHidden = false
            case .community:
                    //is member
                    let isPublic = screenViewModel.dataSource.getChannelModel()?.object.isPublic ?? true
                    let isMember = channel.object.currentUserMembership == .member
                    if isPublic {
                        inputMenuView.isHidden = false
                        openEditorMenuView.isHidden = true
                    } else {
                        if isMember {
                            inputMenuView.isHidden = false
                            openEditorMenuView.isHidden = true
                        } else {
                            inputMenuView.isHidden = true
                            openEditorMenuView.isHidden = true
                        }

                    }
            default:
                inputMenuView.isHidden = false
                openEditorMenuView.isHidden = true
            }
            
            isGetChannelSuccess = true
        }
    }
    
    func showRecordButton(show: Bool) {
        if show {
            trailingStackView.isHidden = true
            textComposeBarView.isHidden = true
            recordButton.isHidden = false
            showAudioButton.isHidden = true // [Custom for ONE Krungthai] Change record button to hidden when pressed record button refer to Figma
            showDefaultKeyboardButton.isHidden = false
            textComposeBarView.textView.resignFirstResponder()
        } else {
            trailingStackView.isHidden = false
            textComposeBarView.isHidden = false
            recordButton.isHidden = true
            showAudioButton.isHidden = setting.shouldHideAudioButton
            showDefaultKeyboardButton.isHidden = true
            if textComposeBarView.text != "" {
                sendMessageButton.isHidden = false
                showKeyboardComposeBarButton.isHidden = true
            } else {
                showKeyboardComposeBarButton.isHidden = false
                sendMessageButton.isHidden = true
            }
        }
    }
    
    func showJoinMenuButton(show: Bool) {
        if show {
            inputMenuView.alpha = 0
            inputMenuView.isHidden = true
            forwardMenuView.isHidden = true
            joinMenuView.isHidden = false
        } else {
            inputMenuView.alpha = 1
            inputMenuView.isHidden = false
            forwardMenuView.isHidden = true
            joinMenuView.isHidden = true
        }
    }
    
    func clearText() {
        textComposeBarView.clearText()
    }
    
    var deletingTarget: UIView? {
        get {
            recordButton.deletingTarget
        }
        set {
            recordButton.deletingTarget = newValue
        }
    }
    
    var isTimeout: Bool {
        get {
            recordButton.isTimeout
        }
        set {
            recordButton.isTimeout = newValue
        }
    }
    
    var selectedMenuHandler: ((AmityKeyboardComposeBarModel.MenuType) -> Void)? {
        get {
            composeBarView.selectedMenuHandler
        }
        set {
            composeBarView.selectedMenuHandler = newValue
        }
    }
    
    func rotateMoreButton(canRotate rotate: Bool) {
        if rotate {
            // for show keyboard compose bar menu
            animationForRotation(with: CGFloat.pi * 0.25, animation: { [weak self] in
                self?.textComposeBarView.inputView = self?.composeBarView.view
                self?.textComposeBarView.reloadInputViews()
                self?.textComposeBarView.becomeFirstResponder()
            })
        } else {
            // for show keyboard default
            animationForRotation(with: 0, animation: { [weak self] in
                guard let strongSelf = self else { return }
                if strongSelf.screenViewModel.dataSource.isKeyboardVisible() {
                    if strongSelf.textComposeBarView.inputView != nil {
                        strongSelf.textComposeBarView.inputView = nil
                        strongSelf.textComposeBarView.resignFirstResponder()
                    }
                    
                    if !strongSelf.textComposeBarView.becomeFirstResponder() {
                        strongSelf.textComposeBarView.textView.becomeFirstResponder()
                    }
                } else {
                    strongSelf.textComposeBarView.textView.resignFirstResponder()
                }
            })
        }
    }
    
    func animationForRotation(with angle: CGFloat, animation: @escaping () -> Void) {
        UIView.animate(withDuration: 0.25, animations: { [weak self] in
            self?.showKeyboardComposeBarButton.transform = CGAffineTransform(rotationAngle: angle)
            animation()
        })
    }
    
    func showPopoverMessage() {
        let vc = AmityPopoverMessageViewController.make()
        vc.text = AmityLocalizedStringSet.PopoverText.popoverMessageIsTooShort.localizedString
        vc.modalPresentationStyle = .popover
        
        let popover = vc.popoverPresentationController
        popover?.delegate = self
        popover?.permittedArrowDirections = .down
        popover?.sourceView = recordButton
        popover?.sourceRect = recordButton.bounds
        present(vc, animated: true, completion: nil)
    }
    
    func prepareTypingText() {
        textComposeBarView.becomeFirstResponder()
        textComposeBarView.textView.becomeFirstResponder()
    }
}

extension AmityMessageListComposeBarViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

extension AmityMessageListComposeBarViewController: AmityTextComposeBarViewDelegate {
	func composeView(_ view: AmityTextComposeBarView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		delegate?.composeView(view, shouldChangeTextIn: range, replacementText: text) ?? true
	}
	
	func composeViewDidChangeSelection(_ view: AmityTextComposeBarView) {
		delegate?.composeViewDidChangeSelection(view)
	}
}
