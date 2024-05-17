//
//  AmityCommunitySearchScreenViewModel.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 26/4/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

import UIKit

final class AmityCommunitySearchScreenViewModel: AmityCommunitySearchScreenViewModelType {
    weak var delegate: AmityCommunitySearchScreenViewModelDelegate?
    
    // MARK: - Manager
    private let communityListRepositoryManager: AmityCommunityListRepositoryManagerProtocol
    
    // MARK: - Properties
    private let debouncer = Debouncer(delay: 0.5)
    private var communityList: [AmityCommunityModel] = []
    private var isEndingResult: Bool = false
    private let size: Int = 20
    
    init(communityListRepositoryManager: AmityCommunityListRepositoryManagerProtocol) {
        self.communityListRepositoryManager = communityListRepositoryManager
    }
}

// MARK: - DataSource
extension AmityCommunitySearchScreenViewModel {
    
    func numberOfCommunity() -> Int {
        return communityList.count
    }
    
    func item(at indexPath: IndexPath) -> AmityCommunityModel? {
        guard !communityList.isEmpty else { return nil }
        return communityList[indexPath.row]
    }
    
}

// MARK: - Action
extension AmityCommunitySearchScreenViewModel {
    
    func search(withText text: String?) {
        communityList = []
        isEndingResult = false
        guard let text = text, !text.isEmpty else {
            delegate?.screenViewModelDidClearText(self)
            delegate?.screenViewModel(self, loadingState: .loaded)
            return
        }

        delegate?.screenViewModel(self, loadingState: .loading)
        communityListRepositoryManager.search(withText: text, filter: .userIsMember) { [weak self] (updatedCommunityList) in
            /* Set is ending result static value to true if result is not more than 20 */
            guard let strongSelf = self else { return }
            if updatedCommunityList.count < strongSelf.size {
                strongSelf.isEndingResult = true
            }
            
            self?.debouncer.run {
                self?.prepareData(communityList: updatedCommunityList)
            }
        }
    }
    
    private func prepareData(communityList: [AmityCommunityModel]) {
        self.communityList = communityList
//        print("[Search][community] communityList: \(communityList)")
        if communityList.isEmpty {
            delegate?.screenViewModelDidSearchNotFound(self)
        } else {
            delegate?.screenViewModelDidSearch(self)
        }
        delegate?.screenViewModel(self, loadingState: .loaded)
    }
    
    func loadMore() {
        /* Check is ending result or result not found for ignore load more */
        if isEndingResult || communityList.isEmpty { return }
        
        /* Get data next section */
        delegate?.screenViewModel(self, loadingState: .loading)
        debouncer.run { [self] in
            let isEndingPage = communityListRepositoryManager.loadMore()
            if isEndingPage {
                isEndingResult = true
                delegate?.screenViewModel(self, loadingState: .loaded)
            }
        }
    }
    
}
