//
//  AmityPostLiveStreamTableViewCell.swift
//  AmityUIKit
//
//  Created by Nutchaphon Rewik on 7/9/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

class AmityPostLiveStreamTableViewCell: UITableViewCell, Nibbable, AmityPostProtocol {
    
    public weak var delegate: AmityPostDelegate?
    public private(set) var post: AmityPostModel?
    public private(set) var indexPath: IndexPath?
    
    private var loadImagetoken = UUID()
    
    // MARK: - IBOutlets
    @IBOutlet private weak var thumbnailImageView: UIImageView!
    @IBOutlet private weak var streamStateContainer: UIView!
    @IBOutlet private weak var streamStateLabel: UILabel!
    @IBOutlet private weak var viewerCountContainer: UIView!
    @IBOutlet private weak var viewerCountLabel: UILabel!

    
    @IBOutlet private weak var streamEndView: UIView!
    @IBOutlet private weak var streamEndTitleLabel: UILabel!
    @IBOutlet private weak var streamEndDescriptionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        streamStateContainer.clipsToBounds = true
        streamStateContainer.layer.cornerRadius = 4
        viewerCountContainer.clipsToBounds = true
        viewerCountContainer.layer.cornerRadius = 4
    }
    
    override func prepareForReuse() {
        loadImagetoken = UUID()
        super.prepareForReuse()
    }
    
    func display(post: AmityPostModel, indexPath: IndexPath) {
        
        self.post = post
        self.indexPath = indexPath
        
        let streamStatus: AmityStreamStatus?
        let thumbnailImageUrl: String?
        
        if let stream = post.liveStream {
            // NOTE: If stream is deleted, we show the idle state UI.
            if stream.isDeleted {
                streamStatus = .idle
            } else {
                streamStatus = stream.status
            }
            thumbnailImageUrl = stream.thumbnail?.fileURL
        } else {
            streamStatus = nil
            thumbnailImageUrl = nil
        }
        
        streamEndTitleLabel.font = AmityFontSet.title
        streamEndDescriptionLabel.font = AmityFontSet.body
        
        streamStateLabel.font = AmityFontSet.captionBold
        streamStateLabel.textColor = .white
        
        viewerCountLabel.font = AmityFontSet.captionBold
        viewerCountLabel.textColor = .white
        
        // Whether to show stream end view, which will obsecure all the view behinds.
        switch streamStatus {
        case .ended:
            streamEndTitleLabel.text = "This livestream has ended."
            streamEndDescriptionLabel.text = "Playback will be available for you to watch shortly."
            streamEndDescriptionLabel.isHidden = false
            streamEndView.isHidden = false
        case .idle:
            streamEndTitleLabel.text = "The stream is currently unavailable."
            streamEndDescriptionLabel.text = nil
            streamEndDescriptionLabel.isHidden = true
            streamEndView.isHidden = false
        default:
            streamEndView.isHidden = true
        }
        
        // Configuring streamStateContainer and streamStateLabel
        switch streamStatus {
        case .live:
            streamStateContainer.isHidden = false
            streamStateContainer.backgroundColor = UIColor(hex: "FF305A")
            streamStateLabel.text = "LIVE"
            viewerCountContainer.isHidden = false
            
            getViewerCount(withpostId: post.postId) { [self] viewerCount in
                setViewerCount(viewerCount: viewerCount)
            }
        case .recorded:
            streamStateContainer.isHidden = false
            streamStateContainer.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            streamStateLabel.text = "RECORDED"
            viewerCountContainer.isHidden = true
        default:
            streamStateContainer.isHidden = true
            viewerCountContainer.isHidden = true
        }
        
        // Set the placeholder
        // - while waiting for image loading
        // - or if there's no image to load
        let placeholder = UIImage(named: "default_livestream", in: AmityUIKitManager.bundle, compatibleWith: nil)
        thumbnailImageView.image = placeholder
        
        // Load thumbnail image
        if let thumbnailImageUrl = thumbnailImageUrl {
            loadImageAsync(fromFileUrl: thumbnailImageUrl)
        }
        
        viewerCountLabel.text = String(post.viewerCount.formatUsingAbbrevation())
    }
    
    private func loadImageAsync(fromFileUrl fileUrl: String) {
        
        let capturedToken = loadImagetoken
        
        AmityUIKitManagerInternal.shared.fileService.loadImage(imageURL: fileUrl, size: .medium, optimisticLoad: true) { [weak self] result in
            
            guard let strongSelf = self else {
                return
            }
            guard strongSelf.loadImagetoken == capturedToken else {
                // Cell has been dequeued while we are loading the image.
                // We don't do anything, since this cell suppose to render in different index path.
                return
            }
            switch result {
            case .success(let image):
                strongSelf.thumbnailImageView.image = image
            case .failure:
                break
            }
        }
        
        
    }
    
    func getViewerCount(withpostId postId: String, completion: @escaping (Int) -> Void) {
        // Simulate your API request using a service object or Alamofire, etc.
        let serviceRequest = RequestGetViewerCount()
        serviceRequest.request(postId: postId, viewerUserId: AmityUIKitManager.currentUserToken, viewerDisplayName: AmityUIKitManager.displayName, isTrack: false, streamId: ""){ result in
            switch result {
            case .success(let dataResponse):
                let viwerCount = dataResponse.viewerCount ?? 0
                completion(viwerCount)
            case .failure(_):
                completion(0)
            }
        }
    }
    
    func setViewerCount(viewerCount: Int) {
        DispatchQueue.main.async { [self] in
            viewerCountLabel.text = String(viewerCount.formatUsingAbbrevation())
        }
    }
    
    @IBAction private func playLiveStreamButtonDidTouch() {
        guard let liveStream = post?.liveStream else {
            assertionFailure("live stream must exist at this point.")
            return
        }
        delegate?.didPerformAction(self, action: .tapLiveStream(stream: liveStream))
    }
    
}
