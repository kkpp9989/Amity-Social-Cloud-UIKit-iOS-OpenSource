//
//  AmityHashtagSearchScreenViewModel.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 19/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

final class AmityHashtagSearchScreenViewModel: AmityHashtagSearchScreenViewModelType {
    enum LoadingState {
        case idle
        case loading
        case loadingMore
    }
    
    weak var delegate: AmityHashtagSearchScreenViewModelDelegate?
    
    // MARK: - Properties
    private let debouncer = Debouncer(delay: 0.3)
    private var hashtagsList: [AmityHashtagModel] = []
    private var previousResponseHashtagsList: [AmityHashtagModel] = []
    private var fromIndex: Int = 0
    private var previousFromIndex: Int = 0
    private var currentKeyword: String = ""
    private var hashtagLoadingState: LoadingState = .idle
    
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
        /* Check is not same keyword for clear data */
        if currentKeyword != text {
            print("[hashtaglist] clear data because have new keyword | current keyword : \(currentKeyword) | new keyword : \(text)")
            currentKeyword = text ?? ""
            fromIndex = 0 // Reset the index when starting a new search
            hashtagLoadingState = .loading
            refreshData()
        }
        
        delegate?.screenViewModel(self, loadingState: .loading)
        var serviceRequest = RequestHashtag()
        serviceRequest.keyword = currentKeyword
        serviceRequest.size = 20
        serviceRequest.from = fromIndex
        print(#"[hashtaglist] Get hashtag from index \#(fromIndex) with size 20 and keyword "\#(currentKeyword)""#)
        serviceRequest.request { [self] result in
            switch result {
            case .success(let dataResponse):
                let updatedHashtagList = dataResponse.hashtag ?? []
                /* Check latest response is duplicate previous response for ignore update data */
                if !checkDuplicateResponseOfHashtagList(updatedHashtagList: updatedHashtagList) {
                    previousResponseHashtagsList = updatedHashtagList // Set new previous for check next time
                    previousFromIndex = fromIndex
                    prepareData(updatedHashtagList: updatedHashtagList)
                } else {
                    fromIndex = previousFromIndex
                    hashtagLoadingState = .idle // Reset loading state after preparing data
                }
                
                /* Hide loading indicator */
                DispatchQueue.main.async {
                    self.delegate?.screenViewModel(self, loadingState: .loaded)
                }
            case .failure(let error):
                print(error)
                hashtagLoadingState = .idle // Reset loading state in case of failure
                
                /* Hide loading indicator */
                DispatchQueue.main.async {
                    self.delegate?.screenViewModel(self, loadingState: .loaded)
                }
            }
        }
    }
    
    private func prepareData(updatedHashtagList: [AmityHashtagModel]) {
        DispatchQueue.main.async { [self] in
            self.hashtagsList += updatedHashtagList
            if updatedHashtagList.isEmpty {
                delegate?.screenViewModelDidSearchNotFound(self)
            } else {
                delegate?.screenViewModelDidSearch(self)
            }
            hashtagLoadingState = .idle // Reset loading state after preparing data
            
            /* Hide loading indicator */
            delegate?.screenViewModel(self, loadingState: .loaded)
        }
    }
    
    func loadMore() {
        print("[hashtaglist] check must to load more")
        /* Check loading state for decrease duplicate trigger loadmore frequently */
        guard hashtagLoadingState != .loadingMore else {
            return // Return if a loadMore operation is already in progress
        }
        print("[hashtaglist] can load more")
        
        /* Set status of loading state to loading more check in first step of this function */
        hashtagLoadingState = .loadingMore
        
        /* Get data next section */
        fromIndex += 20
        search(withText: currentKeyword)
    }
    
    func refreshData() {
        hashtagsList = []
    }
    
    func checkDuplicateResponseOfHashtagList(updatedHashtagList: [AmityHashtagModel]) -> Bool {
        /* Get name of hashtag from updated data */
        let updatedHashtagListName = updatedHashtagList.map { hashtag in
            return hashtag.text ?? ""
        }
        print("[hashtaglist] updatedHashtagListName: \(updatedHashtagListName)")
        
        /* Get name of hashtag from previous data */
        let previousHashtagListName = previousResponseHashtagsList.map { previousResponseHashtag in
            return previousResponseHashtag.text ?? ""
        }
        print("[hashtaglist] previousHashtagListName: \(previousHashtagListName)")
        
        /* Check data between updated and previous data is same data */
        let isSameData = updatedHashtagListName == previousHashtagListName
        print("[hashtaglist] isSameData: \(isSameData)")
        
        /* Check count between hashtag from updated data and result filtered is same for conclude to same data or not */
        if (updatedHashtagListName.count == previousHashtagListName.count) && isSameData {
            print("[hashtaglist] checkDuplicateResponseOfHashtagList: true")
            return true
        } else {
            print("[hashtaglist] checkDuplicateResponseOfHashtagList: false")
            return false
        }
    }
}
