//
//  AmityPostURLPreviewTableViewCell.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 7/9/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK
import LinkPresentation

class AmityPostURLPreviewTableViewCell: UITableViewCell, Nibbable, AmityPostProtocol {
    
    // MARK: - IBOutlet Properties
    @IBOutlet var mainView: UIView!
    @IBOutlet var urlPreviewImage: UIImageView!
    @IBOutlet var urlPreviewDomain: AmityLabel!
    @IBOutlet var urlPreviewTitle: UILabel!
    @IBOutlet var mainViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var topURLPreviewDetailConstraint: NSLayoutConstraint!
    @IBOutlet var bottomURLPreviewDetailConstraint: NSLayoutConstraint!
    @IBOutlet var heightImageViewConstraint: NSLayoutConstraint!
    
    
    // MARK: Properties
    var delegate: AmityPostDelegate?
    var post: AmityPostModel?
    var indexPath: IndexPath?
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        clearView()
    }
    
    private func setupView() {
        // Setup image
        urlPreviewImage.image = nil
        urlPreviewImage.backgroundColor = .gray
        urlPreviewImage.contentMode = .scaleAspectFill
        
        // Setup domain
        urlPreviewDomain.text = "-"
        urlPreviewDomain.font = AmityFontSet.caption
        urlPreviewDomain.textColor = AmityColorSet.disableTextField
        
        // Setup title
        urlPreviewTitle.text = "-"
        urlPreviewTitle.font = AmityFontSet.bodyBold
        urlPreviewTitle.textColor = AmityColorSet.base
        
        // Set view to hidden
        mainViewHeightConstraint.isActive = true
        mainView.isHidden = true
        
        // Set selection style to none
        selectionStyle = .none
    }
    
    private func clearView() {
        urlPreviewImage.image = nil
        urlPreviewDomain.text = "-"
        urlPreviewTitle.text = "-"
        mainViewHeightConstraint.isActive = true
        mainView.isHidden = true
        post = nil
    }
    
    func display(post: AmityPostModel, indexPath: IndexPath) {
        self.post = post
        self.indexPath = indexPath
        
        if let urlString = getURLInText(text: post.text) {
            // Display view
            displayURLPreview(urlString: urlString)
            mainViewHeightConstraint.isActive = false
            mainView.isHidden = true
            topURLPreviewDetailConstraint.constant = 8
            bottomURLPreviewDetailConstraint.constant = 8
            heightImageViewConstraint.constant = 172
        } else {
            // Hide view because don't have url in text
            mainViewHeightConstraint.isActive = true
            topURLPreviewDetailConstraint.constant = 0
            bottomURLPreviewDetailConstraint.constant = 0
            heightImageViewConstraint.constant = 0
        }
    }
    
    private func displayURLPreview(urlString: String) {
        let metadataProvider = LPMetadataProvider()
        metadataProvider.startFetchingMetadata(for: URL(string: urlString)!) { (data, error) in
            // Get metadata
            guard let metadata = data, error == nil else {
                return
            }
            
            // Set title & domain & preview image if have
            DispatchQueue.main.async { [self] in
                if let title = metadata.title, let domain = metadata.originalURL?.absoluteString, let imageProvider = metadata.imageProvider {
                    // Set title
                    urlPreviewTitle.text = title
                    // Set domain
                    urlPreviewDomain.text = domain
                    
                    // Set preview image
                    imageProvider.loadObject(ofClass: UIImage.self) { [self] image, error in
                        if let previewImage = image as? UIImage {
                            DispatchQueue.main.async { [self] in
                                urlPreviewImage.image = previewImage
                                mainViewHeightConstraint.isActive = false
                                mainView.isHidden = false
                            }
                        } else {
                            DispatchQueue.main.async { [self] in
                                // Hide view because of can't get preview image
                                mainViewHeightConstraint.isActive = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func getURLInText(text: String) -> String? {
        // Detect URLs
        let urlDetector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let urlMatches = urlDetector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        var hyperLinkTextRange: [Hyperlink] = []
        
        for match in urlMatches {
            guard let textRange = Range(match.range, in: text) else { continue }
            let urlString = String(text[textRange])
            let validUrlString = urlString.hasPrefixIgnoringCase("http") ? urlString : "http://\(urlString)"
            guard let formattedString = validUrlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: formattedString) else { continue }
            hyperLinkTextRange.append(Hyperlink(range: match.range, type: .url(url: url)))
        }
        
        if hyperLinkTextRange.count > 0 {
            guard let firstHyperLink = hyperLinkTextRange.first?.type else { return nil }
            switch firstHyperLink {
            case .url(let url):
                return url.absoluteString
            default:
                return nil
            }
        } else {
            return nil
        }
    }
    
}
