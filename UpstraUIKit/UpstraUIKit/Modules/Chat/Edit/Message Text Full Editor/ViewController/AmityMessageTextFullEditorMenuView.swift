//
//  AmityMessageTextFullEditorMenuView.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 31/1/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import UIKit

protocol AmityMessageTextFullEditorMenuViewDelegate: AnyObject {
    func messageMenuView(_ view: AmityMessageTextFullEditorMenuView, didTap action: AmityMessageMenuActionType)
}

enum AmityMessageMenuActionType {
    case camera
    case album
    case video
    case file
    case expand
}

public enum AmityMessageAttachmentType: CaseIterable {
    case image
    case video
    case file
}

class AmityMessageTextFullEditorMenuView: UIView {
    
    static let defaultHeight: CGFloat = 60
    
    private let allowMessageAttachments: Set<AmityMessageAttachmentType>
    
    private let stackView = UIStackView(frame: .zero)
    private let topLineView = UIView(frame: .zero)
    private let cameraButton = AmityButton(frame: .zero)
    private let albumButton = AmityButton(frame: .zero)
    private let videoButton = AmityButton(frame: .zero)
    private let fileButton = AmityButton(frame: .zero)
    private let expandButton = AmityButton(frame: .zero)
    
    var currentAttachmentState: AmityMessageAttachmentType? {
        didSet {
            updateButtonState()
        }
    }
    
    weak var delegate: AmityMessageTextFullEditorMenuViewDelegate?
    
    private enum Constant {
        static let topLineViewHeight: CGFloat = 1.0
    }
    
    init(allowMessageAttachments: Set<AmityMessageAttachmentType>) {
        self.allowMessageAttachments = allowMessageAttachments
        super.init(frame: .zero)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        
        backgroundColor = AmityColorSet.backgroundColor
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.cornerRadius = 16
        layer.borderColor = AmityColorSet.secondary.blend(.shade4).cgColor
        layer.borderWidth = 1
        clipsToBounds = true
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .equalCentering
        stackView.alignment = .center
        topLineView.translatesAutoresizingMaskIntoConstraints = false
        topLineView.backgroundColor = .clear
        
        cameraButton.setImage(AmityIconSet.iconCameraSmall, for: .normal)
        cameraButton.addTarget(self, action: #selector(tapCamera), for: .touchUpInside)
        albumButton.setImage(AmityIconSet.iconPhoto, for: .normal)
        albumButton.addTarget(self, action: #selector(tapPhoto), for: .touchUpInside)
        videoButton.setImage(AmityIconSet.iconPlayVideo, for: .normal)
        videoButton.addTarget(self, action: #selector(tapVideo), for: .touchUpInside)
        fileButton.setImage(AmityIconSet.iconAttach, for: .normal)
        fileButton.addTarget(self, action: #selector(tapFile), for: .touchUpInside)
        expandButton.setImage(AmityIconSet.iconDownChevron, for: .normal)
        expandButton.addTarget(self, action: #selector(tapExpand), for: .touchUpInside)
        
        // Setup arrangedSubview in stackview
        let buttonsToAdd = [cameraButton, albumButton, videoButton, fileButton]
        for button in buttonsToAdd {
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 32),
                button.heightAnchor.constraint(equalToConstant: 32)
            ])
            button.layer.cornerRadius = 16
            button.clipsToBounds = true
            button.backgroundColor = (button == expandButton) ? .clear : AmityColorSet.base.blend(.shade4)
            button.setTintColor(AmityColorSet.base, for: .normal)
            button.setTintColor(AmityColorSet.base.blend(.shade3), for: .disabled)
            stackView.addArrangedSubview(button)
        }
        
        // Set buttons visibility based on allowMessageAttachments.
        cameraButton.isHidden = true
        albumButton.isHidden = allowMessageAttachments.isDisjoint(with: [.image])
        videoButton.isHidden = allowMessageAttachments.isDisjoint(with: [.video])
        fileButton.isHidden = allowMessageAttachments.isDisjoint(with: [.file])
        
        // At empty view, at beginning, and the end of the stackview.
        // This logic works together with stackView.distribution = .equalCentering
        // To create buttons position arrangment, and also create negative space at left and right side.
        let visibleButtons = stackView.arrangedSubviews.filter { !$0.isHidden }
        if visibleButtons.count < 4 {
            stackView.insertArrangedSubview(UIView(frame: .zero), at: 0)
            stackView.addArrangedSubview(UIView(frame: .zero))
        }
        
        addSubview(topLineView)
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            topLineView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topLineView.trailingAnchor.constraint(equalTo: trailingAnchor),
            topLineView.topAnchor.constraint(equalTo: topAnchor),
            topLineView.heightAnchor.constraint(equalToConstant: Constant.topLineViewHeight),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor,  constant: -16),
            stackView.topAnchor.constraint(equalTo: topLineView.bottomAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
        
    }
    
    private func updateButtonState() {
        switch currentAttachmentState {
        case .image:
            cameraButton.isEnabled = false
            albumButton.isEnabled = true
            videoButton.isEnabled = false
            fileButton.isEnabled = false
        case .video:
            cameraButton.isEnabled = false
            albumButton.isEnabled = false
            videoButton.isEnabled = true
            fileButton.isEnabled = false
        case .file:
            cameraButton.isEnabled = false
            albumButton.isEnabled = false
            videoButton.isEnabled = false
            fileButton.isEnabled = true
        case .none:
            cameraButton.isEnabled = true
            albumButton.isEnabled = true
            videoButton.isEnabled = true
            fileButton.isEnabled = true
        }
    }
    
    // MARK: - Private function
    @objc private func tapCamera() {
        delegate?.messageMenuView(self, didTap: .camera)
    }
    
    @objc private func tapPhoto() {
        delegate?.messageMenuView(self, didTap: .album)
    }
    
    @objc private func tapVideo() {
        delegate?.messageMenuView(self, didTap: .video)
    }
    
    @objc private func tapFile() {
        delegate?.messageMenuView(self, didTap: .file)
    }
    
    @objc private func tapExpand() {
        delegate?.messageMenuView(self, didTap: .expand)
    }

}

