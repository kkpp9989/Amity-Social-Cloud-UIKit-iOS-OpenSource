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
    private var isLoadMore: Bool = false

    init() {}
    
    func fetchData() {
        if !isLoadMore {
            page = 0
            pageCount = 0
            totalPages = 0
        }
        AmityEventHandler.shared.showKTBLoading()
        let serviceRequest = RequestGetNotification()
        serviceRequest.requestNotificationHistory(page) { [self] result in
            switch result {
            case .success(let dataResponse):
                if isLoadMore {
                    collectionData += dataResponse.data
                } else {
                    collectionData = dataResponse.data
                }
                page = dataResponse.nextPage ?? 0
                totalPages = dataResponse.totalPages
                delegate?.screenViewModelDidUpdateData(self)
            case .failure(let error):
                print(error)
                delegate?.screenViewModelDidUpdateData(self)
            }
            pageCount += 1
            isLoadMore = false
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
            isLoadMore = true
            fetchData()
        }
    }
    
    func updateReadItem(model: NotificationTray) {
        let serviceRequest = RequestGetNotification()
        serviceRequest.requestNotificationRead(model.verb, targetId: model.targetID) { [weak self] result in
            guard let strongSelf = self else {return }
            
            if let index = strongSelf.findIndexByTargetID(targetID: model.targetID, in: strongSelf.collectionData) {
                print("Index found: \(index)")
                strongSelf.collectionData[index].hasRead = true
            }
            
            switch result {
            case .success(_):
                strongSelf.delegate?.screenViewModelDidUpdateData(strongSelf)
            case .failure(let error):
                print(error)
                strongSelf.delegate?.screenViewModelDidUpdateData(strongSelf)
            }
        }
    }
    
    func findIndexByTargetID(targetID: String, in array: [NotificationTray]) -> Int? {
        for (index, notification) in array.enumerated() {
            if notification.targetID == targetID {
                return index
            }
        }
        return nil // Return nil if targetID is not found in the array
    }
}
