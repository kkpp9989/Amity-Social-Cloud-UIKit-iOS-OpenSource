//
//  UIViewController+Extension.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 1/6/2563 BE.
//  Copyright © 2563 Amity Communication. All rights reserved.
//

import UIKit
import AVKit

extension UIViewController {
    
    static var identifier: String {
        return String(describing: self)
    }
    
    public var isModalPresentation: Bool {
        let presentingIsModal = presentingViewController != nil
        let presentingIsNavigation = navigationController?.presentingViewController?.presentedViewController == navigationController
        let presentingIsTabBar = tabBarController?.presentingViewController is UITabBarController
        return presentingIsModal || presentingIsNavigation || presentingIsTabBar
    }
    
    func addChild(viewController: UIViewController, at frame: CGRect? = nil) {
        addChild(viewController)
        viewController.view.frame = frame ?? view.frame
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
    }
    
    func addContainerView(_ viewController: UIViewController, to containerView: UIView) {
        addChild(viewController)
        
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(viewController.view)
        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            viewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        viewController.didMove(toParent: self)
    }
    
    func presentVideoPlayer(at url: URL) {
        let player = AVPlayer(url: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        // Override sound settings
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        present(playerViewController, animated: true) { [weak player] in
            player?.play()
        }
    }
    
    func showToastWithCompletion(message: String, duration: TimeInterval = 4.0, delay: TimeInterval = 0.1, completion: (() -> Void)? = nil) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = UIColor.white
        toastLabel.font = UIFont.systemFont(ofSize: 14) // Replace Font.kfLight14 with a default font
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        self.view.addSubview(toastLabel)
        
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: { [weak self] (isCompleted) in
            toastLabel.removeFromSuperview()
            completion?()
        })
    }
}
