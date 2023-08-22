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
    let reactionViewController: AmityReactionUsersViewController
    let reactionCreateViewController: AmityReactionUsersViewController
    let reactionHonestViewController: AmityReactionUsersViewController
    let reactionHarmonyViewController: AmityReactionUsersViewController
    let reactionSuccessViewController: AmityReactionUsersViewController
    let reactionSocietyViewController: AmityReactionUsersViewController
    let reactionLikeViewController: AmityReactionUsersViewController
    let reactionLoveViewController: AmityReactionUsersViewController
    
    // MARK: - View lifecycle
    private init(info: [AmityReactionInfo], reactionList: [String: Int]) {
        self.info = info
        
        reactionViewController = AmityReactionUsersViewController.make(with: info[0], reactionType: "", reactionCount: info[0].reactionsCount)
        reactionCreateViewController = AmityReactionUsersViewController.make(with: info[0], reactionType: "create", reactionCount: reactionList["create"] ?? 0)
        reactionHonestViewController = AmityReactionUsersViewController.make(with: info[0], reactionType: "honest", reactionCount: reactionList["honest"] ?? 0)
        reactionHarmonyViewController = AmityReactionUsersViewController.make(with: info[0], reactionType: "harmony", reactionCount: reactionList["harmony"] ?? 0)
        reactionSuccessViewController = AmityReactionUsersViewController.make(with: info[0], reactionType: "success", reactionCount: reactionList["success"] ?? 0)
        reactionSocietyViewController = AmityReactionUsersViewController.make(with: info[0], reactionType: "society", reactionCount: reactionList["society"] ?? 0)
        reactionLikeViewController = AmityReactionUsersViewController.make(with: info[0], reactionType: "like", reactionCount: reactionList["like"] ?? 0)
        reactionLoveViewController = AmityReactionUsersViewController.make(with: info[0], reactionType: "love", reactionCount: reactionList["love"] ?? 0)
        
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
        return [reactionViewController, reactionCreateViewController, reactionHonestViewController, reactionHarmonyViewController, reactionSuccessViewController, reactionSocietyViewController, reactionLikeViewController, reactionLoveViewController]
    }
}
