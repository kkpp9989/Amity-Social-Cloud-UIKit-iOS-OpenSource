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
    private var fromIndex: Int = 0
    private var size: Int = 20
    private var currentKeyword: String = ""
    private var isEndingResult: Bool = false
    
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
        /* Check is current keyword with input text for clear data and reset static value or not */
        if currentKeyword != text {
            hashtagsList = []
            currentKeyword = text ?? ""
            fromIndex = 0
            isEndingResult = false
        }
        
        delegate?.screenViewModel(self, loadingState: .loading)
        var serviceRequest = RequestHashtag()
        serviceRequest.keyword = currentKeyword
        serviceRequest.size = size
        serviceRequest.from = fromIndex
//        print(#"[Search] Start search hashtag with keyword "\#(currentKeyword)" from \#(fromIndex) size 20"#)
        serviceRequest.request { [self] result in
            switch result {
            case .success(let dataResponse):
                let updatedHashtagList = dataResponse.hashtag ?? []
//                print(#"[Search] Result search hashtag with keyword "\#(currentKeyword)" from \#(fromIndex) size 20 | count: \#(updatedHashtagList.count) | data: \#(updatedHashtagList)"#)
                /* Check is data not more than size request is mean is ending result */
                if updatedHashtagList.count < size {
                    isEndingResult = true
                }
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
            self.hashtagsList += updatedHashtagList
            if self.hashtagsList.isEmpty {
                delegate?.screenViewModelDidSearchNotFound(self)
            } else {
                delegate?.screenViewModelDidSearch(self)
            }
            
            /* Hide loading indicator */
            delegate?.screenViewModel(self, loadingState: .loaded)
        }
    }
    
    func loadMore() {
        /* Check is ending result for ignore load more */
        if isEndingResult {
            return
        }
        
        /* Get data next section */
        delegate?.screenViewModel(self, loadingState: .loading)
        debouncer.run { [self] in
            fromIndex += size
            search(withText: currentKeyword)
        }
    }
}
