//
//  AmityNotificationTrayScreenViewModel.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 20/9/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

class AmityNotificationTrayScreenViewModel: AmityNotificationTrayScreenViewModelType {
    
    weak var delegate: AmityNotificationTrayScreenViewModelDelegate?
    
    private var collectionData: [NotificationTray] = []
    
    private var page: Int = 0
    private var totalPages: Int = 1
    private var pageCount: Int = 0

    init() {}
    
    func fetchData() {
        if pageCount >= totalPages { return }
        AmityEventHandler.shared.showKTBLoading()
        let serviceRequest = RequestGetNotification()
        serviceRequest.requestNotificationHistory(page) { [self] result in
            switch result {
            case .success(let dataResponse):
                collectionData += dataResponse.data
                page = dataResponse.nextPage ?? 0
                totalPages = dataResponse.totalPages
                delegate?.screenViewModelDidUpdateData(self)
            case .failure(let error):
                print(error)
                delegate?.screenViewModelDidUpdateData(self)
            }
            pageCount += 1
        }
    }

    func updateReadTray() {
        let serviceRequest = RequestGetNotification()
        serviceRequest.requestNotificationLastRead() { result in
            switch result {
            case .success(_):
                break
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // MARK: - Data Source
    
    func numberOfItems() -> Int {
        return collectionData.count
    }
    
    func item(at indexPath: IndexPath) -> NotificationTray? {
        return collectionData[indexPath.row]
    }
    
    func loadMore() {
        if pageCount < totalPages {
            fetchData()
        }
    }
    
    func updateReadItem(model: NotificationTray) {
        let serviceRequest = RequestGetNotification()
        serviceRequest.requestNotificationRead(model.verb, targetId: model.targetID) { [self] result in
            switch result {
            case .success(_):
                delegate?.screenViewModelDidUpdateData(self)
            case .failure(let error):
                print(error)
                delegate?.screenViewModelDidUpdateData(self)
            }
        }
    }
    
}
