//
//  AmityMemberSearchScreenViewModel.swift
//  AmityUIKit
//
//  Created by Hamlet on 11.05.21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit

final class AmityMemberSearchScreenViewModel: AmityMemberSearchScreenViewModelType {
    weak var delegate: AmityMemberSearchScreenViewModelDelegate?
    
    // MARK: - Manager
    private let memberListRepositoryManager: AmityMemberListRepositoryManagerProtocol
    
    // MARK: - Properties
    private let debouncer = Debouncer(delay: 0.5)
    private var memberList: [AmityUserModel] = []
    private var isEndingResult: Bool = false
    private let size: Int = 20
    
    init(memberListRepositoryManager: AmityMemberListRepositoryManagerProtocol) {
        self.memberListRepositoryManager = memberListRepositoryManager
    }
}

// MARK: - DataSource
extension AmityMemberSearchScreenViewModel {
    func numberOfmembers() -> Int {
        return memberList.count
    }
    
    func item(at indexPath: IndexPath) -> AmityUserModel? {
        guard !memberList.isEmpty else { return nil }
        return memberList[indexPath.row]
    }
}

// MARK: - Action
extension AmityMemberSearchScreenViewModel {
    
    func search(withText text: String?) {
        memberList = []
        isEndingResult = false
        guard let text = text, !text.isEmpty else {
            delegate?.screenViewModelDidClearText(self)
            delegate?.screenViewModel(self, loadingState: .loaded)
            return
        }

        delegate?.screenViewModel(self, loadingState: .loading)
        memberListRepositoryManager.search(withText: text, sortyBy: .displayName) { [weak self] (updatedMemberList) in
            /* Set is ending result static value to true if result is not more than 20 */
            guard let strongSelf = self else { return }
            if updatedMemberList.count < strongSelf.size {
                strongSelf.isEndingResult = true
            }

            self?.debouncer.run {
                self?.prepareData(memberList: updatedMemberList)
            }
        }
    }
    
    private func prepareData(memberList: [AmityUserModel]) {
        self.memberList = memberList
//        print("[Search][member][model] memberList: \(memberList) | count: \(memberList.count)")
        if memberList.isEmpty {
            delegate?.screenViewModelDidSearchNotFound(self)
        } else {
            delegate?.screenViewModelDidSearch(self)
        }
        delegate?.screenViewModel(self, loadingState: .loaded)
    }
    
    func loadMore() {
        /* Check is ending result or result not found for ignore load more */
        if isEndingResult || memberList.isEmpty { return }
        
        /* Get data next section */
        delegate?.screenViewModel(self, loadingState: .loading)
        debouncer.run { [self] in
            let isEndPage = memberListRepositoryManager.loadMore()
            if isEndPage {
                isEndingResult = true
                delegate?.screenViewModel(self, loadingState: .loaded)
            }
        }
    }
}
