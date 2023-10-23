//
//  AssetPreviewViewController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 22/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import Photos

class AssetPreviewViewController: UIViewController {
    public var assets: [PHAsset] = []  // An array of selected assets to be previewed
    var scrollView: UIScrollView!
    var imageViews: [UIImageView] = []
    var finishButton: UIButton!

    // Add a closure property to handle the "Finish" action
    var didFinishPickingAsset: ((_ asset: [PHAsset]) -> Void)?
    var didBackPickingAsset: ((_ asset: [PHAsset]) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the background color to black
        view.backgroundColor = UIColor.black
        
        // Get the safe area insets
        let safeArea = view.safeAreaInsets
        
        // Create a "Finish" button
        finishButton = UIButton(type: .custom)
        finishButton.setTitle("Send", for: .normal)
        finishButton.titleLabel?.font = AmityFontSet.body
        finishButton.setTitleColor(.white, for: .normal)
        finishButton.addTarget(self, action: #selector(finishButtonTapped), for: .touchUpInside)
        finishButton.layer.cornerRadius = 8
        view.addSubview(finishButton)
        
        // Create a "Back" button
        let backButton = UIButton(type: .custom)
        backButton.setImage(AmityIconSet.iconBack, for: .normal)
        backButton.imageView?.contentMode = .scaleAspectFit
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)
        
        // Get the safe area layout guide
        let layoutGuide = view.safeAreaLayoutGuide
        
        // Set constraints for the "Finish" button
        finishButton.translatesAutoresizingMaskIntoConstraints = false
        finishButton.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor, constant: -20).isActive = true
        finishButton.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: -20).isActive = true
        
        // Set constraints for the "Back" button
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.topAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: 20).isActive = true
        backButton.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: 20).isActive = true
        
        // Create a scroll view to display the assets
        scrollView = UIScrollView(frame: CGRect(x: safeArea.left, y: safeArea.top, width: view.bounds.width - safeArea.left - safeArea.right, height: view.bounds.height - safeArea.top - safeArea.bottom - finishButton.bounds.height - backButton.bounds.height - 40))
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scrollView)
        
        for (index, asset) in assets.enumerated() {
            // Create an image view for the asset
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(imageView)
            imageViews.append(imageView)
            
            // Create a constraint for the imageView's position in the scrollView
            let leadingConstraint = NSLayoutConstraint(item: imageView, attribute: .leading, relatedBy: .equal, toItem: scrollView, attribute: .leading, multiplier: 1, constant: CGFloat(index) * scrollView.frame.width)
            let topConstraint = NSLayoutConstraint(item: imageView, attribute: .top, relatedBy: .equal, toItem: scrollView, attribute: .top, multiplier: 1, constant: 0)
            let widthConstraint = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: scrollView, attribute: .width, multiplier: 1, constant: 0)
            let heightConstraint = NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: scrollView, attribute: .height, multiplier: 1, constant: 0)
            
            NSLayoutConstraint.activate([leadingConstraint, topConstraint, widthConstraint, heightConstraint])
            
            // Load and display the asset
            loadAsset(asset, into: imageView)
        }
        
        // Set the content size of the scroll view based on the number of assets
        scrollView.contentSize = CGSize(width: CGFloat(assets.count) * scrollView.frame.width, height: scrollView.frame.height)
    }
    
    @objc func backButtonTapped() {
        // Dismiss the preview view controller
        dismiss(animated: true) { [weak self] in
            guard let strongSelf = self else { return}
            strongSelf.didBackPickingAsset?(strongSelf.assets)
        }
    }
    
    @objc func finishButtonTapped() {
        // Dismiss the preview view controller
        dismiss(animated: true) { [weak self] in
            guard let strongSelf = self else { return}
            strongSelf.didFinishPickingAsset?(strongSelf.assets)
        }
    }
    
    func loadAsset(_ asset: PHAsset, into imageView: UIImageView) {
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isSynchronous = true
        
        // Request the image representation of the asset
        PHImageManager.default().requestImage(for: asset, targetSize: view.bounds.size, contentMode: .aspectFit, options: requestOptions) { (image, info) in
            if let image = image {
                imageView.image = image
            } else {
                // Handle the case where the asset couldn't be loaded
                imageView.image = UIImage(named: "placeholderImage")
            }
        }
    }
}
