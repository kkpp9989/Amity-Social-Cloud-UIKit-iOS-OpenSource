//
//  AmityPostTextTableViewCell.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 2/8/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK
import LinkPresentation

public final class AmityPostTextTableViewCell: UITableViewCell, Nibbable, AmityPostProtocol {
    
    public weak var delegate: AmityPostDelegate?
    
    private enum Constant {
        static let ContentMaximumLine = 8
    }
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var contentLabel: AmityExpandableLabel!
    
    // MARK: - URLPreview IBOutlet Properties
    /* [Custom for ONE Krungthai][URL Preview] Component for URL Preview */
    @IBOutlet var urlPreviewImage: UIImageView!
    @IBOutlet var urlPreviewDomain: AmityLabel!
    @IBOutlet var urlPreviewTitle: AmityLabel!
    @IBOutlet var urlPreviewView: AmityView!
    
    // MARK: - Properties
    public private(set) var post: AmityPostModel?
    public private(set) var indexPath: IndexPath?

    // MARK: - URLPreview Properties
    /* [Custom for ONE Krungthai][URL Preview] Property for store data of URL Preview for decrease loading every time */
    private var urlPreviewData: (urlString: String, title: String?, domain: String?, image: UIImage?)?
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
        setupContentLabel()
        setupURLPreviewView() // [Custom for ONE Krungthai][URL Preview] Add setup URL preview view
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        contentLabel.isExpanded = false
        contentLabel.text = nil
        post = nil
        clearURLPreviewView() // [Custom for ONE Krungthai][URL Preview] Add clear URL preview view outputing
    }
    
    public func display(post: AmityPostModel, indexPath: IndexPath) {

        self.post = post
        self.indexPath = indexPath

        if let liveStream = post.liveStream {
            // We picky back to render title/description for live stream post here.
            // By getting post.liveStream
            if let metadata = post.metadata, let mentionees = post.mentionees {
                let attributes = AmityMentionManager.getAttributes(fromText: post.text, withMetadata: metadata, mentionees: mentionees)

                contentLabel.setText(post.text, withAttributes: attributes)
            } else {
                contentLabel.text = post.text
            }
        } else {

            // The default render behaviour just to grab text from post.text
            if let metadata = post.metadata, let mentionees = post.mentionees {
                let attributes = AmityMentionManager.getAttributes(fromText: post.text, withMetadata: metadata, mentionees: mentionees)
                contentLabel.setText(post.text, withAttributes: attributes)
            } else {
                contentLabel.text = post.text
            }
        }

        contentLabel.isExpanded = post.appearance.shouldContentExpand

        /* [Custom for ONE Krungthai][URL Preview] Add check URL in text for show URL preview or not */
        if let urlString = getURLInText(text: post.text) {
            // Display URL Preview
            urlPreviewView.isHidden = false
            displayURLPreview(urlString: urlString)
        } else {
            // Hide URL Preview because don't have URL in text
            urlPreviewView.isHidden = true
            urlPreviewData = nil
        }
    }

    /* [Custom for ONE Krungthai][URL Preview] Get URL data, store URL data to cell and display URL Preview function */
    private func displayURLPreview(urlString: String) {
        if let previewData = urlPreviewData, previewData.urlString == urlString {
            // Use existing preview data
            urlPreviewTitle.text = previewData.title
            urlPreviewDomain.text = previewData.domain
            urlPreviewImage.image = previewData.image
            urlPreviewView.isHidden = false
            urlPreviewView.alpha = 1.0
        } else {
            // Fetch and display URL preview
            guard let urlData = URL(string: urlString) else { return }

            let metadataProvider = LPMetadataProvider()
            metadataProvider.startFetchingMetadata(for: urlData) { [weak self] (data, error) in
                // Get metadata
                guard let metadata = data, error == nil else {
                    DispatchQueue.main.async { [self] in
                        self?.urlPreviewView.isHidden = true
                    }
                    return
                }

                // Set title & domain & preview image if available
                DispatchQueue.main.async { [weak self] in
                    if let title = metadata.title, let domain = urlData.host, let imageProvider = metadata.imageProvider {
                        // Set title
                        self?.urlPreviewTitle.text = title
                        // Set domain
                        self?.urlPreviewDomain.text = domain

                        // Set preview image
                        imageProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                            if let previewImage = image as? UIImage {
                                DispatchQueue.main.async { [weak self] in
                                    // Store the preview data
                                    self?.urlPreviewData = (urlString, title, domain, previewImage)
                                    self?.urlPreviewImage.image = previewImage
                                    self?.urlPreviewView.isHidden = false
                                    self?.urlPreviewView.alpha = 1.0
                                }
                            } else {
                                DispatchQueue.main.async { [weak self] in
                                    // Hide view because of can't get preview image
                                    self?.urlPreviewData = (urlString, title, domain, nil)
                                    self?.urlPreviewView.isHidden = true
                                }
                            }
                        }
                    } else {
                        self?.urlPreviewView.isHidden = true
                    }
                }
            }
        }
    }
    
    /* [Custom for ONE Krungthai][URL Preview] Get URL in text (first) */
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
        
        // Check and get URL founded in text
        if hyperLinkTextRange.count > 0 {
            guard let firstHyperLink = hyperLinkTextRange.first?.type else { return nil } // Get first URL founded
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
    
    // MARK: - Setup views
    private func setupView() {
        selectionStyle = .none
        backgroundColor = AmityColorSet.backgroundColor
        contentView.backgroundColor = AmityColorSet.backgroundColor
    }
    
    private func setupContentLabel() {
        contentLabel.font = AmityFontSet.body
        contentLabel.textColor = AmityColorSet.base
        contentLabel.shouldCollapse = false
        contentLabel.textReplacementType = .character
        contentLabel.numberOfLines = Constant.ContentMaximumLine
        contentLabel.isExpanded = false
        contentLabel.delegate = self
    }
    
    /* [Custom for ONE Krungthai][URL Preview] Setup url preview view function */
    private func setupURLPreviewView() {
        // Setup image
        urlPreviewImage.image = nil
        urlPreviewImage.backgroundColor = .gray
        urlPreviewImage.contentMode = .scaleAspectFill
        
        // Setup domain
        urlPreviewDomain.text = " "
        urlPreviewDomain.font = AmityFontSet.caption
        urlPreviewDomain.textColor = AmityColorSet.disableTextField
        
        // Setup title
        urlPreviewTitle.text = " "
        urlPreviewTitle.font = AmityFontSet.bodyBold
        urlPreviewTitle.textColor = AmityColorSet.base
        
        // Setup ishidden status of view
        urlPreviewView.isHidden = true
        urlPreviewView.alpha = 0.0
    }
    
    // MARK: - Clear URL Preview
    /* [Custom for ONE Krungthai][URL Preview] Clear data in url preview view function for reuse cell */
    private func clearURLPreviewView() {
        urlPreviewView.isHidden = true
        urlPreviewView.alpha = 0.0
        urlPreviewTitle.text = " "
        urlPreviewDomain.text = " "
        urlPreviewImage.image = nil
    }
    
    // MARK: - Perform Action
    private func performAction(action: AmityPostAction) {
        delegate?.didPerformAction(self, action: action)
    }
}

// MARK: AmityExpandableLabelDelegate
extension AmityPostTextTableViewCell: AmityExpandableLabelDelegate {
    
    public func willExpandLabel(_ label: AmityExpandableLabel) {
        performAction(action: .willExpandExpandableLabel(label: label))
    }
    
    public func didExpandLabel(_ label: AmityExpandableLabel) {
        performAction(action: .didExpandExpandableLabel(label: label))
    }
    
    public func willCollapseLabel(_ label: AmityExpandableLabel) {
        performAction(action: .willCollapseExpandableLabel(label: label))
    }
    
    public func didCollapseLabel(_ label: AmityExpandableLabel) {
        performAction(action: .didCollapseExpandableLabel(label: label))
    }
    
    public func expandableLabeldidTap(_ label: AmityExpandableLabel) {
        performAction(action: .tapExpandableLabel(label: label))
    }

    public func didTapOnMention(_ label: AmityExpandableLabel, withUserId userId: String) {
        performAction(action: .tapOnMentionWithUserId(userId: userId))
    }
    
    public func didTapOnHashtag(_ label: AmityExpandableLabel, withKeyword keyword: String, count: Int) {
        performAction(action: .tapOnHashtagWithKeyword(keyword: keyword, count: count))
    }
}
