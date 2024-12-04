//
//  FloatingBubbleViewController.swift
//  AmityUIKitLiveStream
//
//  Created by GuIDe'MacbookAmityHQ on 15/8/2566 BE.
//

import UIKit
import AmityUIKit

class FloatingBubbleView: UIView {

    private var imageView: UIImageView!
    var reactionType: String = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setImage() -> UIImage {
        switch reactionType {
        case "create":
            return AmityIconSet.iconBadgeDNASangsun ?? UIImage()
        case "honest":
            return AmityIconSet.iconBadgeDNASatsue ?? UIImage()
        case "harmony":
            return AmityIconSet.iconBadgeDNASamakki ?? UIImage()
        case "success":
            return AmityIconSet.iconBadgeDNASumrej ?? UIImage()
        case "society":
            return AmityIconSet.iconBadgeDNASangkom ?? UIImage()
        case "like":
            return AmityIconSet.iconLikeFill ?? UIImage()
        case "love":
            return AmityIconSet.iconBadgeDNALove ?? UIImage()
        default:
            return AmityIconSet.iconBadgeDNASangsun ?? UIImage()
        }
    }

    func runAnimate() {
        imageView = UIImageView(image: setImage())
        imageView.frame = bounds
        addSubview(imageView)
    }
}
