//
//  AmityPreviewLinkCell.swift
//  AmityUIKit
//
//  Created by Zay Yar Htun on 10/17/23.
//  Copyright © 2023 Amity. All rights reserved.
//

import UIKit
import LinkPresentation
import UniformTypeIdentifiers

class AmityPreviewLinkCell: UITableViewCell, Nibbable {
    
    @IBOutlet weak var previewLinkViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var previewLinkView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var urlToOpen: URL?
    
    @IBOutlet weak var previewLinkImage: UIImageView!
    @IBOutlet weak var previewLinkTitle: UILabel!
    @IBOutlet weak var previewLinkURL: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    private func setupView() {
        // Setup view
        selectionStyle = .none
        backgroundColor = AmityColorSet.backgroundColor
        contentView.backgroundColor = AmityColorSet.backgroundColor
        previewLinkViewHeightConstraint.constant = UIScreen.main.bounds.height * 0.32
        previewLinkView.clipsToBounds = true
        previewLinkView.isHidden = false
        
        // Setup open URL gesture
        let gesture = UITapGestureRecognizer(target: self, action: #selector(previewLinkTapped))
        previewLinkView.addGestureRecognizer(gesture)
        
        // Setup domain text
        previewLinkURL.text = " "
        previewLinkURL.font = AmityFontSet.caption
        previewLinkURL.textColor = AmityColorSet.disableTextField
        previewLinkURL.numberOfLines = 1

        // Setup title text
        previewLinkTitle.text = " "
        previewLinkTitle.font = AmityFontSet.bodyBold
        previewLinkTitle.textColor = AmityColorSet.base
        previewLinkTitle.numberOfLines = 2
        
        // Setup image preview
        previewLinkImage.image = nil
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        clearURLPreviewView()
    }
    
    func display(post: AmityPostModel) {
        if let title = post.metadata?["url_preview_cache_title"] as? String,
           let fullURL = post.metadata?["url_preview_cache_url"] as? String,
           let urlData = URL(string: fullURL),
           let domainURL = urlData.host?.replacingOccurrences(of: "www.", with: ""),
           let urlDetected = AmityPreviewLinkWizard.shared.detectURLStringWithURLEncoding(text: post.text), urlDetected == fullURL
        {
            // Set URL data to open
            urlToOpen = urlData
            
            // Set domain and title text
            previewLinkTitle.text = title
            previewLinkURL.text = domainURL
            
            // Show URL preview view
            previewLinkView.isHidden = false
            
            // Show loading indicator
            activityIndicator.startAnimating()
            
            // Get URL Metadata for loading image preview
            Task { @MainActor in
                if let metadata = await AmityPreviewLinkWizard.shared.getMetadata(url: urlData), let imageProvider = metadata.imageProvider {
                    // Loading image preview
                    imageProvider.loadObject(ofClass: UIImage.self, completionHandler: { [weak self] image, error in
                        guard let self else { return }
                        // Set image preview if have or default image URL preview
                        DispatchQueue.main.async {
                            if let image = image as? UIImage {
                                self.previewLinkImage.image = image
                            } else {
                                self.previewLinkImage.image = AmityIconSet.defaultImageURLPreview
                            }
                            // Stop loading indicator
                            self.activityIndicator.stopAnimating()
                        }
                    })
                } else {
                    self.previewLinkImage.image = AmityIconSet.defaultImageURLPreview
                    self.activityIndicator.stopAnimating()
                }
            }
        }
    }
    
    private func clearURLPreviewView() {
        previewLinkView.isHidden = false
        previewLinkTitle.text = " "
        previewLinkURL.text = " "
        previewLinkImage.image = nil
        urlToOpen = nil
    }
    
    @objc private func previewLinkTapped() {
        guard let urlToOpen else {
            return
        }
        UIApplication.shared.open(urlToOpen)
    }
    
}
