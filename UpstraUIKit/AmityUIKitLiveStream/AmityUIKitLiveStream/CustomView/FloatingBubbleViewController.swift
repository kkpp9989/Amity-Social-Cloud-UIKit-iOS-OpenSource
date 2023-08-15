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

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupImageView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupImageView()
    }

    private func setupImageView() {
        imageView = UIImageView(image: AmityIconSet.iconBadgeDNASatsue)
        imageView.frame = bounds
        addSubview(imageView)
    }
}
