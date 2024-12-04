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
    private let debouncer = Debouncer(delay: 0.5)
    private var hashtagsList: [AmityHashtagModel] = []
    private var paginateToken: String = ""
    private var size: Int = 20
    private var currentKeyword: String = ""
    private var isEndingResult: Bool = false
    private var isLoadingMore: Bool = false
    
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
        /* Check text is nil or is searching for ignore searching */
        guard let newKeyword = text else { return }
        if newKeyword.isEmpty { return }

        if currentKeyword == newKeyword {
            if isEndingResult { return }
        }
        
        /* Check is current keyword with input text for clear data and reset static value or not */
        if currentKeyword != newKeyword {
            hashtagsList = []
            currentKeyword = newKeyword
            paginateToken = ""
            isEndingResult = false
            isLoadingMore = false
        }
        
        delegate?.screenViewModel(self, loadingState: .loading)
        var serviceRequest = RequestHashtag()
        serviceRequest.keyword = currentKeyword
        serviceRequest.size = size
        serviceRequest.paginateToken = paginateToken
//        print(#"[Search] Start search hashtag with keyword "\#(currentKeyword)" from \#(fromIndex) size 20"#)
        /* Set static value to true for block new searching in this time */
        serviceRequest.request { [self] result in
            switch result {
            case .success(let dataResponse):
                let updatedHashtagList = dataResponse.hashtag ?? []
                
                /* Check is data not more than size request is mean is ending result */
                if dataResponse.paging?.next == paginateToken || dataResponse.paging == nil {
                    isEndingResult = true
                    paginateToken = ""
                }
                
                paginateToken = dataResponse.paging?.next ?? ""
                prepareData(updatedHashtagList: updatedHashtagList)
            case .failure(let error):
                print(error)
                
                /* Hide loading indicator */
                DispatchQueue.main.async {
                    self.delegate?.screenViewModel(self, loadingState: .loaded)
                }
            }
        }
    }
    
    private func prepareData(updatedHashtagList: [AmityHashtagModel]) {
        DispatchQueue.main.async { [self] in
            /* Check is loading result more from current keyword or result from new keyword */
            if isLoadingMore {
                self.hashtagsList += updatedHashtagList
            } else {
                self.hashtagsList = updatedHashtagList
            }
            
            if hashtagsList.isEmpty {
                delegate?.screenViewModelDidSearchNotFound(self)
            } else {
                delegate?.screenViewModelDidSearch(self)
            }
            
            /* Hide loading indicator */
            delegate?.screenViewModel(self, loadingState: .loaded)
        }
    }
    
    func loadMore() {
        /* Check is ending result or result not found for ignore load more */
        if isEndingResult || hashtagsList.isEmpty { return }
        
        /* Set static value to true for prepare data in loading more case */
        isLoadingMore = true
        
        /* Get data next section */
        delegate?.screenViewModel(self, loadingState: .loading)
        debouncer.run { [self] in
            search(withText: currentKeyword)
        }
    }
}
