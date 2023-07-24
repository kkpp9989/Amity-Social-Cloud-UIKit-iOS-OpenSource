//
//  LiveStreamCommentTableViewCell.swift
//  AmityUIKitLiveStream
//
//  Created by GuIDe'MacbookAmityHQ on 23/7/2566 BE.
//

import UIKit
import AmityUIKit
import AmitySDK

protocol LiveStreamCommentTableViewCellProtocol {
    func didReactionTap(reaction: String, isLike: Bool) -> ()
}

class LiveStreamCommentTableViewCell: UITableViewCell, Nibbable {
    
    @IBOutlet var avatarView: AmityAvatarView!
    @IBOutlet var commentView: UIView!
    @IBOutlet var displayNameLabel: UILabel!
    @IBOutlet var commentLabel: UILabel!
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var unlikeButton: UIButton!

    static let height: CGFloat = 60
        
    var delegate: LiveStreamCommentTableViewCellProtocol?
    var commentId: String = ""
    var isLike: Bool = false

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupCell()
    }
    
    func setupCell() {
        self.backgroundColor = .clear
        
        commentView.backgroundColor = .black.withAlphaComponent(0.3)
        commentView.layer.cornerRadius = 10
        
        avatarView.backgroundColor = .clear
        
        displayNameLabel.font = AmityFontSet.headerLine.withSize(16)
        displayNameLabel.textColor = .white
        displayNameLabel.backgroundColor = .clear
        
        commentLabel.font = AmityFontSet.caption.withSize(14)
        commentLabel.backgroundColor = .clear
        commentLabel.numberOfLines = 0
        commentLabel.lineBreakMode = .byTruncatingTail
        commentLabel.sizeToFit()
        commentLabel.textColor = .white
        
        likeButton.setTitle("", for: .normal)
        unlikeButton.setTitle("", for: .normal)
    }

    func display(comment: AmityCommentModel) {
        avatarView.setImage(withImageURL: comment.fileURL)
        displayNameLabel.text = comment.displayName
        commentId = comment.id
        commentLabel.text = comment.text
        isLike = comment.isLiked
        
        if comment.isLiked {
            likeButton.isHidden = true
            unlikeButton.isHidden = false
        } else {
            likeButton.isHidden = false
            unlikeButton.isHidden = true
        }
    }
    
    class func height(for comment: AmityCommentModel, boundingWidth: CGFloat) -> CGFloat {
        var height: CGFloat = 30
        var actualWidth: CGFloat = 0

        // for cell layout and calculation, please go check this pull request https://github.com/EkoCommunications/EkoMessagingSDKUIKitIOS/pull/713
        let horizontalPadding: CGFloat = 0
        actualWidth = boundingWidth - horizontalPadding

        let messageHeight = AmityExpandableLabel.height(for: comment.text, font: AmityFontSet.body, boundingWidth: actualWidth, maximumLines: 0)
        height += messageHeight
        return height
    }
    
    // MARK: - Tap avatar to show profile
    @IBAction func didReactionInCellIsTapped() {
        delegate?.didReactionTap(reaction: commentId, isLike: isLike)
    }
}
