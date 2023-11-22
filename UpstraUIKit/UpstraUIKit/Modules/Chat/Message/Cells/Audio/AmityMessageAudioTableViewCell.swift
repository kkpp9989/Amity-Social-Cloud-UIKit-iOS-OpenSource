//
//  AmityMessageAudioTableViewCell.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 2/12/2563 BE.
//  Copyright © 2563 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityMessageAudioTableViewCellDelegate: NSObject {
    func reloadDataAudioCell(indexPath: IndexPath)
}

final class AmityMessageAudioTableViewCell: AmityMessageTableViewCell {
    
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var actionImageView: UIImageView!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    
    var celliIndexPath: IndexPath!
    
    weak var delegateCell: AmityMessageAudioTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        durationLabel.text = "00:00"
        actionImageView.image = AmityIconSet.Chat.iconPlay
    }
    
    func setupView() {
        durationLabel.text = "00:00"
        durationLabel.font = AmityFontSet.body
        durationLabel.textAlignment = .right
        actionImageView.image = AmityIconSet.Chat.iconPlay
        
        activityIndicatorView.hidesWhenStopped = true
        
    }
    
    override func display(message: AmityMessageModel) {
        if !message.isDeleted {
            if message.isOwner {
                if AmityColorSet.messageBubble == (UIColor(hex: "B2EAFF", alpha: 1.0)) {
                    // [Custom for ONE Krungthai] Change color style for color "B2EAFF" of message bubble
                    durationLabel.textColor = AmityColorSet.base
                    actionImageView.tintColor = AmityColorSet.base
                } else {
                    // [Original]
                    durationLabel.textColor = AmityColorSet.baseInverse
                    actionImageView.tintColor = AmityColorSet.baseInverse
                }
                
                activityIndicatorView.style = .medium
                switch message.syncState {
                case .syncing:
                    durationLabel.alpha = 0
                    activityIndicatorView.startAnimating()
                case .synced, .default, .error:
                    durationLabel.alpha = 1
                    activityIndicatorView.stopAnimating()
                @unknown default:
                    break
                }
            } else {
                durationLabel.textColor = AmityColorSet.base
                actionImageView.tintColor = AmityColorSet.base
                activityIndicatorView.style = .medium
            }
            
            if AmityAudioPlayer.shared.isPlaying(), AmityAudioPlayer.shared.fileName == message.messageId {
                actionImageView.image = AmityIconSet.Chat.iconPause
            } else {
                actionImageView.image = AmityIconSet.Chat.iconPlay
            }
            
            if message.metadata != nil {
                var time: Double = 0
                if let _ = message.metadata?["duration"] {
                    time = message.metadata?["duration"] as! Double
                }
                durationLabel.text = previewDuration(time)
            } else {
                durationLabel.text = "00:00"
            }
          
        }
        super.display(message: message)
    }
    
    override class func height(for message: AmityMessageModel, boundingWidth: CGFloat) -> CGFloat {
        let displaynameHeight: CGFloat = message.isOwner ? 0 : 46
        if message.isDeleted {
            return AmityMessageTableViewCell.deletedMessageCellHeight + displaynameHeight
        }
        return 90 + displaynameHeight
    }
    
}

// Calculate Time Duration
extension AmityMessageAudioTableViewCell {
    
    func previewDuration(_ itemDuration: Double?) -> String {
        let time = Int((itemDuration ?? 0) / 1000)
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        let display = String(format:"%02i:%02i", minutes, seconds)
        return display
    }
    
}

extension AmityMessageAudioTableViewCell {
    @IBAction func playTap(_ sender: UIButton) {
        if !message.isDeleted && message.syncState == .synced {
            sender.isEnabled = false
            if message.messageId == AmityAudioPlayer.shared.fileName {
                sender.isEnabled = true
                AmityAudioPlayer.shared.startAudio()
            } else {
                delegateCell?.reloadDataAudioCell(indexPath: celliIndexPath)
                AmityUIKitManagerInternal.shared.messageMediaService.download(for: message.object) { [weak self] in
                    self?.durationLabel.alpha = 0
                    self?.activityIndicatorView.startAnimating()
                } completion: { [weak self] (result) in
                    guard let strongSelf = self else { return }
                    switch result {
                    case .success(let url):
                        AmityAudioPlayer.shared.delegate = self
                        AmityAudioPlayer.shared.fileName = strongSelf.message.messageId
                        AmityAudioPlayer.shared.path = url
                        AmityAudioPlayer.shared.getPlayAudio()
                        AmityAudioPlayer.shared.setObserver()
                        AmityAudioPlayer.shared.startObservingTime()
                        AmityAudioPlayer.shared.startAudio()
                        sender.isEnabled = true
                        strongSelf.activityIndicatorView.stopAnimating()
                        strongSelf.durationLabel.alpha = 1
                    case .failure(let error):
                        Log.add(error.localizedDescription)
                    }
                }
            }
        }
    }
}

extension AmityMessageAudioTableViewCell: AmityAudioPlayerDelegate {
    func playing() {
        actionImageView.image = AmityIconSet.Chat.iconPause
    }
    
    func stopPlaying() {
        actionImageView.image = AmityIconSet.Chat.iconPlay
    }
    
    func finishPlaying() {
        actionImageView.image = AmityIconSet.Chat.iconPlay
        if message.metadata != nil {
            var time: Double = 0
            if let _ = message.metadata?["duration"] {
                time = message.metadata?["duration"] as! Double
            }
            durationLabel.text = previewDuration(time)
        } else {
            durationLabel.text = "00:00"
        }
    }
    
    func displayDuration(_ duration: String) {
        durationLabel.text = duration
        self.layoutIfNeeded()
    }
}
