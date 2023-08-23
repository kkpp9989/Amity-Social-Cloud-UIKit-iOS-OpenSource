//
//  AmityReactionPageViewController.swift
//  AmityUIKit
//
//  Created by Amity on 2/5/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

/// ViewPager which contains screen showing list of reaction users.
public class AmityReactionPageViewController: AmityPageViewController {

    let info: [AmityReactionInfo]
	var reactionViewControllerList: [AmityReactionUsersViewController] = []
    
    // MARK: - View lifecycle
    private init(info: [AmityReactionInfo], reactionList: [String: Int]) {
        self.info = info
		
		/// Tab all
		reactionViewControllerList.append(AmityReactionUsersViewController.make(
			with: info[0],
			reactionType: "",
			reactionCount: info[0].reactionsCount)
		)
		
		/// Tab other reactions
		for (key, value) in reactionList where value > 0 {
			switch key {
			case "create", "honest", "harmony", "success", "society", "like", "love":
				let reactionViewController = AmityReactionUsersViewController.make(
					with: info[0],
					reactionType: key,
					reactionCount: value)
				reactionViewControllerList.append(reactionViewController)
			default:
				break
			}
		}
        
        super.init(nibName: AmityReactionPageViewController.identifier, bundle: AmityUIKitManager.bundle)
        title = AmityLocalizedStringSet.Reaction.reactionTitle.localizedString
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
    /// Initializes instance of AmityReactionPageViewController.
    public static func make(info: [AmityReactionInfo], reactionList: [String: Int]) -> AmityReactionPageViewController {
        return AmityReactionPageViewController(info: info, reactionList: reactionList)
    }
    
    override func viewControllers(for pagerTabStripController: AmityPagerTabViewController) -> [UIViewController] {
        return reactionViewControllerList
    }
}
