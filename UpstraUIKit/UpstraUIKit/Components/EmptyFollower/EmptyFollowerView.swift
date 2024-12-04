//
//  EmptyFollowerView.swift
//  AmityUIKit
//
//  Created by Sitthiphong Kanhasura on 25/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation
import UIKit

class EmptyFollowerView: AmityView {
	// MARK: - IBOutlet Properties
	@IBOutlet var view: UIView!
	@IBOutlet var icon: UIImageView!
	@IBOutlet var title: UILabel!
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		loadNibContent()
		setupView()

	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		loadNibContent()
		setupView()
	}
	override func awakeFromNib() {
		super.awakeFromNib()
		setupView()
	}
}

extension EmptyFollowerView {
	func setupView() {
		icon.image = AmityIconSet.Follow.iconFollowEmpty
		title.textColor = AmityColorSet.base.blend(.shade3)
		title.font = AmityFontSet.title
		title.numberOfLines = 2
	}
}
