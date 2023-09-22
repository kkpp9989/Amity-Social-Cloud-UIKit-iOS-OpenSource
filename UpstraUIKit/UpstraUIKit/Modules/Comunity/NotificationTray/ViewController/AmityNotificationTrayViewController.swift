//
//  AmityNotificationTrayViewController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 20/9/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

class AmityNotificationTrayViewController: AmityViewController {
    
    // MARK: - @IBOutlet Properties
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    
    // MARK: - Properties
    private let screenViewModel = AmityNotificationTrayScreenViewModel()
    private var isLoadmore: Bool = true
    
    // MARK: - Initializer
    
    private init() {
        super.init(nibName: AmityNotificationTrayViewController.identifier, bundle: AmityUIKitManager.bundle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public static func make() -> AmityNotificationTrayViewController {
        return AmityNotificationTrayViewController()
    }
    
    // MARK: - View's life cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupScreenViewModel()
        setupTableView()
        setupNavigationBar()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        screenViewModel.fetchData()
    }
    
    // MARK: - Private functions
    
    private func setupTableView() {
        tableView.separatorStyle = .none
        tableView.register(NotificationTrayTableViewCell.nib, forCellReuseIdentifier: NotificationTrayTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    private func setupScreenViewModel() {
        screenViewModel.delegate = self
    }
    
    private func setupNavigationBar() {
        // Initial ONE Krungthai Custom theme
        theme = ONEKrungthaiCustomTheme(viewController: self)
        
        // Set color navigation bar by custom theme
        theme?.setBackgroundNavigationBar()
        title = "Notifications"
    }

}

extension AmityNotificationTrayViewController: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return screenViewModel.numberOfItems()
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: NotificationTrayTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        if tableView.isBottomReached {
//            screenViewModel.loadNext()
        }
        return cell
    }

}

extension AmityNotificationTrayViewController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? NotificationTrayTableViewCell else { return }
//        if let item = screenViewModel.item(at: indexPath) {
//            cell.configure(model: item)
//        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = screenViewModel.item(at: indexPath) else { return }
        screenViewModel.updateReadItem(model: item)
        if item.targetType != "community" {
//            AmityEventHandler.shared.postDidtap(from: self, postId: item.targetId ?? "")
        } else {
//            AmityEventHandler.shared.communityDidTap(from: self, communityId: item.targetId ?? "")
        }
    }

    func tableView(_ tableView: AmityPostTableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView.isBottomReached {
            if isLoadmore {
                isLoadmore = false
                screenViewModel.loadMore()
            }
        }
    }
}

extension AmityNotificationTrayViewController: AmityNotificationTrayScreenViewModelDelegate {
    func screenViewModelDidUpdateData(_ viewModel: AmityNotificationTrayScreenViewModel) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.isLoadmore = true
        }
    }
}
