//
//  AmityPostTabbarViewController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 24/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

public protocol AmityPostTabbarViewControllerDelegate: AnyObject {
    func viewController(_ viewController: AmityPostTabbarViewController)
    func didTapPostButton(_ viewController: AmityPostTabbarViewController)
    func didTapAvatarButton(_ viewController: AmityPostTabbarViewController)
}

final public class AmityPostTabbarViewController: UIViewController {

    // MARK: -  IBOutlet Properties
    @IBOutlet private var statusLabel: UILabel!
    @IBOutlet private var avatarView: AmityAvatarView!
    
    // MARK: - Properties
    public weak var delegate: AmityPostTabbarViewControllerDelegate?
    
    // MARK: - View lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // [Fix defect] Add reload user profile image when this open community home first time after open app and update user profile image
        reloadAvatarImage()
    }

    public static func make() -> AmityPostTabbarViewController {
        let vc = AmityPostTabbarViewController(nibName: AmityPostTabbarViewController.identifier, bundle: AmityUIKitManager.bundle)
        return vc
    }
    
    // MARK: - Setup views
    private func setupView() {
        view.backgroundColor = AmityColorSet.backgroundColor
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(statusTap)))
        
        statusLabel.text = "What's going on..."
        statusLabel.font = AmityFontSet.body
        statusLabel.textColor = AmityColorSet.base.blend(.shade3)
        
        avatarView.placeholder = AmityIconSet.defaultAvatar
        avatarView.setImage(withImageURL: AmityUIKitManager.avatarURL, placeholder: AmityIconSet.defaultAvatar)
        avatarView.isUserInteractionEnabled = true
        avatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTap)))
    }
    
    func reloadView() {
        delegate?.viewController(self)
    }
    
    private func reloadAvatarImage() {
        avatarView.setImage(withImageURL: AmityUIKitManager.avatarURL, placeholder: AmityIconSet.defaultAvatar)
    }
    
    @objc func avatarTap() {
        delegate?.didTapAvatarButton(self)
    }
    
    @objc func statusTap() {
        delegate?.didTapPostButton(self)
    }
}

extension AmityPostTabbarViewController: FeedHeaderPresentable {
    public var headerView: UIView {
        return view
    }
    
    public var height: CGFloat {
        return 76
    }
}
