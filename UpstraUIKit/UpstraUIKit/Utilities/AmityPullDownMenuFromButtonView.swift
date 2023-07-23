//
//  AmityPopupMenuFromButtonView.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 23/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//
// [Custom For ONE Krungthai] New component for ONE Krungthai -> Refer from AmityBottomSheet

import UIKit

struct AmityPullDownMenuFromButtonView {
    static func present<T: ItemOption>(options: [T],
                                       selectedItem: UIBarButtonItem,
                                       isTitleHidden: Bool = true,
                                       from popOverDelegate: UIPopoverPresentationControllerDelegate?,
                                       width: CGFloat? = nil,
                                       height: CGFloat? = nil,
                                       completion: (() -> Void)? = nil) {
        let pullDownMenu = AmityPullDownMenuFromNavigationButtonViewController()
        
        // Set open view controller style to popover
        pullDownMenu.modalPresentationStyle = .popover
        
        // Set popover view controller
        let popoverController = pullDownMenu.popoverPresentationController
        
        guard let fromVC = popOverDelegate as? AmityViewController else { return }
        
        popoverController?.sourceView = fromVC.view
        popoverController?.sourceRect = fromVC.view.bounds
        
        // Set delegate
        popoverController?.delegate = popOverDelegate
        
        // Set sender point
        popoverController?.barButtonItem = selectedItem
        
        // Delete arrow
        popoverController!.permittedArrowDirections = UIPopoverArrowDirection.init(rawValue: 0)
        
        pullDownMenu.configure(items: options)
        
        fromVC.present(pullDownMenu, animated: true, completion: completion)
        
        // Set the size for the popover view controller
        pullDownMenu.preferredContentSize = CGSize(width: width ?? pullDownMenu.currentDynamicTableViewWidth, height: height ?? pullDownMenu.currentDynamicTableViewHeight)
    }
}
