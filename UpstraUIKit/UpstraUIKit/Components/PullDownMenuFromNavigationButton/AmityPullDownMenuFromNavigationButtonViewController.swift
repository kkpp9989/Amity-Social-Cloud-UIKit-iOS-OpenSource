//
//  AmityPullDownMenuFromNavigationButtonViewController.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 19/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

struct AmityPullDownMenuItem {
    var name: String
    var image: UIImage?
    var completion: (() -> Void)?
}

class AmityPullDownMenuFromNavigationButtonViewController: UIViewController {
    
    private let items: [AmityPullDownMenuItem] = [
        AmityPullDownMenuItem(name: AmityLocalizedStringSet.General.post.localizedString, image: AmityIconSet.CreatePost.iconPost),
        AmityPullDownMenuItem(name: "Livestream", image: UIImage(named: "icon_create_livestream_post", in: AmityUIKitManager.bundle, compatibleWith: nil)),
        AmityPullDownMenuItem(name: AmityLocalizedStringSet.General.poll.localizedString, image: AmityIconSet.CreatePost.iconPoll)
    ]
    private var tableview: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
    }
    
    private func setUpTableView(){
        /** Initial table view **/
        tableview = UITableView(frame: .zero)
        tableview.register(AmityPullDownMenuFromNavigationButtonViewCell.nib, forCellReuseIdentifier: AmityPullDownMenuFromNavigationButtonViewCell.identifier)
        tableview.isScrollEnabled = false
        tableview.separatorStyle = .none
        tableview.dataSource = self
        tableview.delegate = self
        
        /** Add table view to subview **/
        view.addSubview(tableview)
        
        /** Trigger table view to reload data **/
        tableview.reloadData()
    }
}

extension AmityPullDownMenuFromNavigationButtonViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableview.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
//        print("[Pulldownmenu] item count: \(items.count)")
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell: AmityPullDownMenuFromNavigationButtonViewCell = tableView.dequeueReusableCell(for: indexPath)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AmityPullDownMenuFromNavigationButtonViewCell.identifier) as? AmityPullDownMenuFromNavigationButtonViewCell else { return UITableViewCell() }
//        print("[Pulldownmenu] init item No.: \(items[indexPath.row])")
        cell.display(item: items[indexPath.row])
        cell.selectionStyle = .none

        return cell
    }
}

extension AmityPullDownMenuFromNavigationButtonViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print("[Pulldownmenu] select item name \(items[indexPath.row])")
    }
}
