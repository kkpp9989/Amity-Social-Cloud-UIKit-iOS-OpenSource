//
//  EkoAvatarView.swift
//  UpstraUIKit
//
//  Created by Sarawoot Khunsri on 29/5/2563 BE.
//  Copyright © 2563 Eko Communication. All rights reserved.
//

import EkoChat
import UIKit

public enum EkoAvatarShape {
    
    /// A shape for circle
    case circle
    
    /// A shape for square
    case square
    
    /// A custom for customize shape of view
    case custom(radius: CGFloat, borderWith: CGFloat, borderColor: UIColor)
}

public enum EkoAvatarState {
    case idle
    case loading
}

/// Eko avatar view
/// An object that displays a single image or load image from url remote resource
public final class EkoAvatarView: EkoView {
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var placeHolderImageView: UIImageView!
    @IBOutlet private weak var overlayView: UIView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    // To prevent calling setup image multiple times.
    // We can use `DispatchWorkItem` for make request cancellable.
    private var pendingRequestWorkItem: DispatchWorkItem?
    
    public var actionHandler: (() -> Void)?
    public var state: EkoAvatarState = .idle {
        didSet {
            updateState()
        }
    }
    
    /// A shape of imageView
    public var avatarShape: EkoAvatarShape = .circle {
        didSet {
            updateAvatarShape()
        }
    }
    
    /// The image displayed in the image view
    public var image: UIImage? {
        get {
            return imageView.image
        } set {
            imageView.image = newValue
            placeHolderImageView.isHidden = image != nil
        }
    }
    
    public var placeholder: UIImage? = EkoIconSet.defaultAvatar {
        didSet {
            placeHolderImageView.image = placeholder
        }
    }
    
    // MARK: - View lifecycle
    public override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        loadNibContent()
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadNibContent()
    }
    
    private func setupView() {
        setupTapGesture()
        setupImageView()
        setupOverlayView()
        updateViews()
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarViewTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(tapGesture)
    }
    
    private func setupImageView() {
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = false
        avatarShape = .circle
    }
    
    private func setupOverlayView() {
        overlayView.backgroundColor = UIColor.white.withAlphaComponent(0.4)
        overlayView.isHidden = true
        activityIndicator.style = .white
    }
    
    private func updateViews() {
        backgroundColor = EkoColorSet.primary.blend(.shade3)

        updateAvatarShape()
    }
    
    private func updateAvatarShape() {
        switch avatarShape {
        case .circle:
            layer.cornerRadius = frame.height / 2
            imageView.layer.cornerRadius = frame.height / 2
            imageView.layer.masksToBounds = true
        case .square:
            imageView.layer.cornerRadius = 0
            imageView.layer.masksToBounds = false
        case let .custom(radius, borderWidth, borderColor):
            imageView.layer.cornerRadius = radius
            imageView.layer.borderWidth = borderWidth
            imageView.layer.borderColor = borderColor.cgColor
            imageView.layer.masksToBounds = true
        }
    }
    
    private func updateState() {
        if state == .loading {
            overlayView.isHidden = false
            activityIndicator.startAnimating()
        } else {
            overlayView.isHidden = true
            activityIndicator.stopAnimating()
        }
    }
    
    // MARK: - Action
    @objc private func avatarViewTap(_ sender: UIGestureRecognizer) {
        actionHandler?()
    }
    
    func setImage(withImageId imageId: String, size: EkoMediaSize = .small, placeholder: UIImage?, completion: (() -> Void)? = nil) {
        
        placeHolderImageView.image = placeholder
        pendingRequestWorkItem?.cancel()
        
        // Wrap our request in a work item
        let requestWorkItem = DispatchWorkItem {
            EkoFileService.shared.loadImage(with: imageId, size: size) { [weak self] result in
                switch result {
                case .success(let image):
                    self?.imageView.image = image
                    completion?()
                case .failure:
                    self?.imageView.image = nil
                    break
                }
            }
        }
        
        pendingRequestWorkItem = requestWorkItem
        DispatchQueue.main.async(execute: requestWorkItem)
    }
    
}
