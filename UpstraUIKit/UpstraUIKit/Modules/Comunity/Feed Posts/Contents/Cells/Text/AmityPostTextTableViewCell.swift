//
//  AmityPostTextTableViewCell.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 2/8/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

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
    private var urlData: URL? // [Custom for ONE Krungthai][URL Preview] Add URL data property for use tap action
    
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
    
    // MARK: - Perform Action
    private func performAction(action: AmityPostAction) {
        delegate?.didPerformAction(self, action: action)
    }
}

// MARK: URL Preview [Custom For ONE Krungthai]
extension AmityPostTextTableViewCell {
    // MARK: - Setup URL Preview
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
        
        // Setup tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openURLTapAction(_:)))
        urlPreviewView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Display URL Preview
    public func displayURLPreview(metadata: AmityURLMetadata) {
        urlPreviewTitle.text = metadata.title
        urlPreviewDomain.text = metadata.domain
        urlPreviewImage.image = metadata.imagePreview
        urlPreviewView.isHidden = false
        urlData = metadata.urlData
    }
    
    // MARK: - Hide URL Preview
    public func hideURLPreview() {
        clearURLPreviewView()
    }
    
    // MARK: - Clear URL Preview
    private func clearURLPreviewView() {
        urlPreviewView.isHidden = true
        urlPreviewTitle.text = " "
        urlPreviewDomain.text = " "
        urlPreviewImage.image = nil
        urlData = nil
    }
    
    // MARK: - Perform Action
    @objc func openURLTapAction(_ sender: UITapGestureRecognizer) {
        if let currentURLData = urlData {
            UIApplication.shared.open(currentURLData, options: [:], completionHandler: nil)
        }
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
