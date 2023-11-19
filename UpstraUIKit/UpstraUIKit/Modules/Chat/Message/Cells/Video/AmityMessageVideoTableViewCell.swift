//
//  AmityMessageVideoTableViewCell.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 10/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

class AmityMessageVideoTableViewCell: AmityMessageTableViewCell {
    
    @IBOutlet weak var playVideoView: UIStackView!
    @IBOutlet var durationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        messageImageView.image = AmityIconSet.defaultMessageImage
        messageImageView.contentMode = .center
        playVideoView.isHidden = true
        durationLabel.isHidden = true
    }

    private func setupView() {
        // Setup video thumbnail
        messageImageView.contentMode = .center
        messageImageView.layer.cornerRadius = 4
        let tapGestureOfVideoThumbnail = UITapGestureRecognizer(target: self, action: #selector(imageViewTap))
        tapGestureOfVideoThumbnail.numberOfTouchesRequired = 1
        messageImageView.isUserInteractionEnabled = true
        messageImageView.addGestureRecognizer(tapGestureOfVideoThumbnail)
        
        // Setup duration video
        let tapGestureOfPlayButton = UITapGestureRecognizer(target: self, action: #selector(imageViewTap))
        tapGestureOfPlayButton.numberOfTouchesRequired = 1
        playVideoView.addGestureRecognizer(tapGestureOfPlayButton)
        playVideoView.isHidden = true
        durationLabel.isHidden = true
        durationLabel.textColor = .white
        durationLabel.font = AmityFontSet.caption
    }
    
    override func display(message: AmityMessageModel) {
        if !message.isDeleted {
            let indexPath = self.indexPath
            print("[AmityUIKit Log] indexPath: \(String(describing: indexPath?.row)) thumbnailInfo: \(String(describing: message.object.getVideoThumbnailInfo())), videoInfo: \(String(describing: message.object.getVideoInfo()))")
            if let thumbnailInfo = message.object.getVideoThumbnailInfo(), let videoInfo = message.object.getVideoInfo() {
                if indexPath == self.indexPath {
                    // Set video thumbnail
                    messageImageView.loadImage(with: thumbnailInfo.fileURL, size: .full, placeholder: AmityIconSet.videoThumbnailPlaceholder, optimisticLoad: true)
                    messageImageView.contentMode = .scaleAspectFill
                    
                    // Set duration from metadata
                    let duration: TimeInterval
                    let attributes = videoInfo.attributes
                    if let meta = attributes["metadata"] as? [String: Any],
                       let videoMeta = meta["video"] as? [String: Any],
                       let _duration = videoMeta["duration"] as? TimeInterval {
                        duration = _duration
                    } else {
                        duration = .zero
                    }
                    playVideoView.isHidden = false
                    if let durationText = getDurationFormatter(showHour: duration >= 3600).string(from: duration) {
                        durationLabel.isHidden = false
                        durationLabel.text = durationText
                    } else {
                        durationLabel.isHidden = true
                    }
                }
            } else {
                messageImageView.image = AmityIconSet.videoThumbnailPlaceholder
                messageImageView.contentMode = .center
                playVideoView.isHidden = true
                durationLabel.isHidden = true
            }
        }
        super.display(message: message)
    }
    
    private func getDurationFormatter(showHour: Bool) -> DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = showHour ? [.hour, .minute, .second] : [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }
}

private extension AmityMessageVideoTableViewCell {
    @objc
    func imageViewTap() {
        screenViewModel.action.performCellEvent(for: .videoViewer(indexPath: indexPath))
    }
}
