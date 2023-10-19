//
//  AmityChannelPickerScreenViewModel.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 15/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation

final class AmityChannelPickerScreenViewModel: AmityChannelPickerScreenViewModelType {
    
    // MARK: - Delegate
    weak var delegate: AmityChannelPickerScreenViewModelDelegate?
    
    // MARK: - Controller
    private var channelListController: AmityChannelListController = AmityChannelListController()
    
    
    // MARK: - Properties
    private var channels: AmityChannelListController.GroupChannel = []
    private var searchChannels: [AmitySelectChannelModel] = []
    private var storeChannels: [AmitySelectChannelModel] = [] {
        didSet {
            delegate?.screenViewModelCanDone(enable: !storeChannels.isEmpty)
        }
    }
    private var isSearch: Bool = false
    
    // MARK: - initial
    init() {
    }
}

// MARK: - Action
extension AmityChannelPickerScreenViewModel {
    func getChannels(type: AmityChannelListViewType) {
        channelListController.storeChannels = storeChannels
        channelListController.fetchChannelList(type: type) { result in
            switch result {
            case .success(let channels):
                self.channels = channels
                self.delegate?.screenViewModelDidFetchChannel()
            case .failure(let failure):
                break
            }
        }
    }
    
    func searchChannel(with text: String, type: AmityChannelListViewType) {
        
    }
    
    func selectChannel(at indexPath: IndexPath) {
        
    }
    
    func deselectChannel(at indexPath: IndexPath) {
        
    }
    
    func loadmore() {
        
    }
    
    func setCurrentChannels(channels: [AmitySelectChannelModel]) {
        storeChannels = channels
    }
}

// MARK: - Datasource
extension AmityChannelPickerScreenViewModel {
    func numberOfAlphabet() -> Int {
        return isSearch ? 1 : channels.count
    }
    
    func numberOfChannels(in section: Int) -> Int {
        return isSearch ? searchChannels.count : channels[section].value.count
    }
    
    func numberOfSelectedChannels() -> Int {
        return storeChannels.count
    }
    
    func alphabetOfHeader(in section: Int) -> String {
        return channels[section].key
    }
    
    func channel(at indexPath: IndexPath) -> AmitySelectChannelModel? {
        if isSearch {
            guard !searchChannels.isEmpty else { return nil }
            return searchChannels[indexPath.row]
        } else {
            guard !channels.isEmpty else { return nil }
            return channels[indexPath.section].value[indexPath.row]
        }
    }
    
    func selectChannel(at indexPath: IndexPath) -> AmitySelectChannelModel {
        return storeChannels[indexPath.item]
    }
    
    func isSearching() -> Bool {
        return isSearch
    }
    
    func getStoreChannels() -> [AmitySelectChannelModel] {
        return storeChannels
    }
}
