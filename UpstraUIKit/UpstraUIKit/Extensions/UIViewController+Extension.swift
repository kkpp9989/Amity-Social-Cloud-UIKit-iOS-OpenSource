//
//  UIViewController+Extension.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 1/6/2563 BE.
//  Copyright © 2563 Amity Communication. All rights reserved.
//

import UIKit
import AVKit
import Photos

extension UIViewController {
    
    static var identifier: String {
        return String(describing: self)
    }
    
    private struct AssociatedKeys {
        static var urlString = "urlString"
    }
    
    private var urlString: String {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.urlString) as? String ?? ""
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.urlString, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
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
        urlString = url.absoluteString
        
        // Override sound settings
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        // Add a custom button to the top right
        let downloadButton = UIButton(type: .custom)
        downloadButton.setImage(AmityIconSet.iconDownload, for: .normal)
        downloadButton.tintColor = AmityColorSet.baseInverse
        downloadButton.layer.cornerRadius = 5
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.addTarget(self, action: #selector(downloadButtonTapped), for: .touchUpInside)
        
        playerViewController.contentOverlayView?.addSubview(downloadButton)
        
        NSLayoutConstraint.activate([
            downloadButton.topAnchor.constraint(equalTo: playerViewController.contentOverlayView!.safeAreaLayoutGuide.topAnchor, constant: 20),
            downloadButton.trailingAnchor.constraint(equalTo: playerViewController.contentOverlayView!.trailingAnchor, constant: 0),
            downloadButton.widthAnchor.constraint(equalToConstant: 100),
            downloadButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        present(playerViewController, animated: true) { [weak player] in
            player?.play()
        }
    }
    
    @objc func downloadButtonTapped() {
        print("Custom button tapped")
        // Handle custom button action here
        let url = urlString
        AmityEventHandler.shared.showKTBLoading()
        downloadAndSaveVideoToGallery(from: url)
    }
    
    func showToastWithCompletion(message: String, duration: TimeInterval = 4.0, delay: TimeInterval = 0.1, completion: (() -> Void)? = nil) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 120, y: self.view.frame.size.height-100, width: 250, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = UIColor.white
        toastLabel.font = UIFont.systemFont(ofSize: 14) // Replace Font.kfLight14 with a default font
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.numberOfLines = 0
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
        
    func downloadAndSaveVideoToGallery(from urlString: String) {
        // Create a URL object from the string
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            AmityEventHandler.shared.hideKTBLoading()
            return
        }
        
        // Create a data task to download the video
        URLSession.shared.dataTask(with: url) { data, response, error in
            // Check for errors
            if let error = error {
                DispatchQueue.main.async {
                    print("Error downloading video: \(error.localizedDescription)")
                    AmityHUD.show(.error(message: AmityLocalizedStringSet.MessageList.cannotDownloadVideoInChat.localizedString))
                    AmityEventHandler.shared.hideKTBLoading()
                }
                return
            }
            
            // Ensure there is data
            guard let videoData = data else {
                DispatchQueue.main.async {
                    print("No data received")
                    AmityHUD.show(.error(message: AmityLocalizedStringSet.MessageList.cannotDownloadVideoInChat.localizedString))
                    AmityEventHandler.shared.hideKTBLoading()
                }
                return
            }
            
            // Get a temporary file URL to write the video data to
            let tempFilePath = NSTemporaryDirectory() + UUID().uuidString + ".mp4"
            let tempFileURL = URL(fileURLWithPath: tempFilePath)
            
            do {
                try videoData.write(to: tempFileURL, options: .atomic)
            } catch {
                DispatchQueue.main.async {
                    print("Error writing video data to temporary file: \(error.localizedDescription)")
                    AmityHUD.show(.error(message: AmityLocalizedStringSet.MessageList.cannotDownloadVideoInChat.localizedString))
                    AmityEventHandler.shared.hideKTBLoading()
                }
                return
            }
            
            // Save the video to the photo library
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempFileURL)
            }) { success, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error saving video to gallery: \(error.localizedDescription)")
                        AmityHUD.show(.error(message: AmityLocalizedStringSet.MessageList.cannotDownloadVideoInChat.localizedString))
                    } else if success {
                        print("Video saved to gallery successfully!")
                        AmityHUD.show(.success(message: AmityLocalizedStringSet.General.done.localizedString))
                    } else {
                        print("Failed to save video to gallery")
                        AmityHUD.show(.error(message: AmityLocalizedStringSet.MessageList.cannotDownloadVideoInChat.localizedString))
                    }
                    
                    AmityEventHandler.shared.hideKTBLoading()
                }
            }
        }.resume()
    }
}
