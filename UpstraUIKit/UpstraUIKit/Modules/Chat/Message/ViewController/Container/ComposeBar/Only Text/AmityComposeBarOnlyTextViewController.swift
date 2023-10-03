//
//  AmityComposeBarOnlyTextViewController.swift
//  AmityUIKit
//
//  Created by Nutchaphon Rewik on 9/6/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

import UIKit

protocol AmityComposeBarOnlyTextDelegate: AnyObject {
	func composeView(_ view: AmityTextComposeBarView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
	func composeViewDidChangeSelection(_ view: AmityTextComposeBarView)
	func sendMessageTap()
}

final class AmityComposeBarOnlyTextViewController: UIViewController {

    // MARK: - IBOutlet Properties
    @IBOutlet private var textComposeBarView: AmityTextComposeBarView!
    @IBOutlet private var sendMessageButton: UIButton!
    @IBOutlet private var trailingStackView: UIStackView!
    
    // MARK: - Properties
    private let screenViewModel: AmityMessageListScreenViewModelType
    let composeBarView = AmityKeyboardComposeBarViewController.make()
	weak var delegate: AmityComposeBarOnlyTextDelegate?
    // MARK: - View lifecycle
    private init(viewModel: AmityMessageListScreenViewModelType) {
        screenViewModel = viewModel
        super.init(nibName: "AmityComposeBarOnlyTextViewController", bundle: AmityUIKitManager.bundle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    static func make(viewModel: AmityMessageListScreenViewModelType,
					 delegate: AmityComposeBarOnlyTextDelegate?) -> AmityComposeBarOnlyTextViewController {
		let vc = AmityComposeBarOnlyTextViewController(viewModel: viewModel)
		vc.delegate = delegate
        return vc
    }
    
}

// MARK: - Action
private extension AmityComposeBarOnlyTextViewController {
    
    @IBAction func sendMessageTap() {
		delegate?.sendMessageTap()
        clearText()
    }
    
}

// MARK: - Setup View
private extension AmityComposeBarOnlyTextViewController {
    
    func setupView() {
        setupTextComposeBarView()
        setupSendMessageButton()
    }
    
    func setupTextComposeBarView() {
		textComposeBarView.delegate = self
        textComposeBarView.placeholder = AmityLocalizedStringSet.textMessagePlaceholder.localizedString
        textComposeBarView.textViewDidChanged = { [weak self] text in
            self?.screenViewModel.action.setText(withText: text)
        }
        
        textComposeBarView.textViewShouldBeginEditing = { [weak self] textView in
            self?.screenViewModel.action.toggleKeyboardVisible(visible: true)
            self?.screenViewModel.action.inputSource(for: .default)
        }
    }
    
    func setupSendMessageButton() {
        sendMessageButton.setTitle(nil, for: .normal)
        sendMessageButton.setImage(AmityIconSet.iconSendMessage, for: .normal)
        sendMessageButton.isEnabled = false
        sendMessageButton.isHidden = false
    }
    
}

extension AmityComposeBarOnlyTextViewController: AmityComposeBar {
	var textView: AmityTextView {
		get {
			textComposeBarView.textView
		}
		set {
			textComposeBarView.textView = newValue
		}
	}
    
    func updateViewDidTextChanged(_ text: String) {
        sendMessageButton.isEnabled = !text.isEmpty
    }
    
    func showRecordButton(show: Bool) {
        // Intentionally left empty
        // This class doesn't support showRecordButton.
    }
    
    func clearText() {
        textComposeBarView.clearText()
    }
    
    var deletingTarget: UIView? {
        get {
            nil
        }
        set {
            // Intentionally left empty
            // This class doesn't support deletingTarget
        }
    }
    
    var isTimeout: Bool {
        get {
            return false
        }
        set {
            // Intentionally left empty
            // This class doesn't support deletingTarget
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
        // Intentionally left empty
        // This class doesn't support rotateMoreButton.
    }
    
    func showPopoverMessage() {
        // Intentinally left empty
        // This class doesn't support showPopoverMessage
    }
    
}

extension AmityComposeBarOnlyTextViewController: AmityTextComposeBarViewDelegate {
	func composeView(_ view: AmityTextComposeBarView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		delegate?.composeView(view, shouldChangeTextIn: range, replacementText: text) ?? true
	}
	
	func composeViewDidChangeSelection(_ view: AmityTextComposeBarView) {
		delegate?.composeViewDidChangeSelection(view)
	}
}
