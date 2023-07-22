//
//  AmityHashtagSearchScreenViewModel.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 19/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

final class AmityHashtagSearchScreenViewModel: AmityHashtagSearchScreenViewModelType {
    weak var delegate: AmityHashtagSearchScreenViewModelDelegate?
    
    // MARK: - Properties
    private let debouncer = Debouncer(delay: 0.3)
    private var hashtagsList: [AmityHashtagModel] = []
    
    init() {
    }
}

// MARK: - DataSource
extension AmityHashtagSearchScreenViewModel {
    
    func numberOfKeyword() -> Int {
        return hashtagsList.count
    }
    
    func item(at indexPath: IndexPath) -> AmityHashtagModel? {
        guard !hashtagsList.isEmpty else { return nil }
        return hashtagsList[indexPath.row]
    }
    
}

// MARK: - Action
extension AmityHashtagSearchScreenViewModel {
    
    func search(withText text: String?) {
        var serviceRequest = RequestHashtag()
        serviceRequest.keyword = text ?? ""
        serviceRequest.size = 20
        serviceRequest.request { result in
            switch result {
            case .success(let dataResponse):
                self.prepareData(hashtagList: dataResponse.hashtag ?? [])
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func prepareData(hashtagList: [AmityHashtagModel]) {
        DispatchQueue.main.async { [self] in
            self.hashtagsList = hashtagList
            if hashtagList.isEmpty {
                delegate?.screenViewModelDidSearchNotFound(self)
            } else {
                delegate?.screenViewModelDidSearch(self)
            }
            delegate?.screenViewModel(self, loadingState: .loaded)
        }
    }
    
    func loadMore() {
        
    }
    
}
