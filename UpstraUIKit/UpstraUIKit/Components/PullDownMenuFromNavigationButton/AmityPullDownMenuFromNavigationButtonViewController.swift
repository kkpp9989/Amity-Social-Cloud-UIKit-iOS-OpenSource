//
//  AmityPullDownMenuFromNavigationButtonViewController.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 19/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//
// [Custom For ONE Krungthai][New component] Pull down menu from navigation button for ONE Krungthai -> Refer from BottomSheetOptionView

import UIKit

class AmityPullDownMenuFromNavigationButtonViewController: UIViewController {
    
    public var items: [any ItemOption] = []
    public let tableview: UITableView = UITableView(frame: .zero)
    public var currentDynamicTableViewWidth: CGFloat { return self.maxRowContentWidth }
    public var currentDynamicTableViewHeight: CGFloat { return self.tableview.contentSize.height }
    private var maxRowContentWidth: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
    }
    
    private func setUpTableView(){
        /** Initial table view **/
        tableview.register(ItemOptionTableViewCell.nib, forCellReuseIdentifier: ItemOptionTableViewCell.identifier)
        tableview.isScrollEnabled = false
        tableview.separatorStyle = .none
        tableview.dataSource = self
        tableview.delegate = self
        tableview.rowHeight = UITableView.automaticDimension
        
        /** Add table view to subview **/
        view.addSubview(tableview)
        
        /** Set up constraints for the table view **/
        tableview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableview.topAnchor.constraint(equalTo: view.topAnchor),
            tableview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableview.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        /** Trigger table view to reload data when init table view **/
        tableview.reloadData()
        tableview.layoutIfNeeded()
    }
    
    func configure(items: [any ItemOption]) {
        /** Set items of pull down menu **/
        self.items = items
        
        /** Trigger table view to reload data when assign new items **/
        tableview.reloadData()
        tableview.layoutIfNeeded()
    }
}

extension AmityPullDownMenuFromNavigationButtonViewController: UITableViewDataSource, UITableViewDelegate {
    // Table View Datasource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: ItemOptionTableViewCell.identifier, for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? ItemOptionTableViewCell else { return }
        let item = items[indexPath.row]
        cell.accessibilityIdentifier = item.title.lowercased().replacingOccurrences(of: " ", with: "_")
        cell.selectionStyle = .none
        cell.backgroundColor = AmityColorSet.backgroundColor
        cell.titleLabel.text = item.title
        cell.titleLabel.tintColor = item.tintColor
        cell.titleLabel.textColor = item.textColor
        cell.titleLabel.font = AmityFontSet.bodyBold
        
        if let imageItem = item as? ImageRepresentableOption {
            cell.iconImageView.image = imageItem.image
            cell.imageBackgroundView.isHidden = imageItem.image == nil
            cell.imageBackgroundView.backgroundColor = imageItem.imageBackgroundColor
        }
        
        maxRowContentWidth = max(maxRowContentWidth, cell.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width)
    }
    
    // Table View Delegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return items[indexPath.row].height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /** Dismiss pull down menu for allow present other view controller **/
        dismiss(animated: true)
        
        /** Run handler action of button **/
        let item = items[indexPath.row]
        item.completion?()
    }
}
 
