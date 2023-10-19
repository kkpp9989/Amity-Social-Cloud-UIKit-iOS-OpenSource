//
//  AmityChannelPickerScreenViewModelProtocol.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 15/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

protocol AmityChannelPickerScreenViewModelDelegate: AnyObject {
    func screenViewModelDidFetchChannel()
    func screenViewModelDidSearchChannel()
    func screenViewModelDidSelectChannel(title: String, isEmpty: Bool)
    func screenViewModelLoadingState(for state: AmityLoadingState)
    func screenViewModelCanDone(enable: Bool)
}

protocol AmityChannelPickerScreenViewModelDatasource {
    func numberOfAlphabet() -> Int
    func numberOfChannels(in section: Int) -> Int
    func numberOfSelectedChannels() -> Int
    func alphabetOfHeader(in section: Int) -> String
    func channel(at indexPath: IndexPath) -> AmitySelectChannelModel?
    func selectChannel(at indexPath: IndexPath) -> AmitySelectChannelModel
    func isSearching() -> Bool
    func getStoreChannels() -> [AmitySelectChannelModel]
}

protocol AmityChannelPickerScreenViewModelAction {
    func getChannels(type: AmityChannelListViewType)
    func searchChannel(with text: String, type: AmityChannelListViewType)
    func selectChannel(at indexPath: IndexPath)
    func deselectChannel(at indexPath: IndexPath)
    func loadmore()
    func setCurrentChannels(channels: [AmitySelectChannelModel])
}

protocol AmityChannelPickerScreenViewModelType: AmityChannelPickerScreenViewModelAction, AmityChannelPickerScreenViewModelDatasource {
    var delegate: AmityChannelPickerScreenViewModelDelegate? { get set }
    var action: AmityChannelPickerScreenViewModelAction { get }
    var dataSource: AmityChannelPickerScreenViewModelDatasource { get }
}

extension AmityChannelPickerScreenViewModelType {
    var action: AmityChannelPickerScreenViewModelAction { return self }
    var dataSource: AmityChannelPickerScreenViewModelDatasource { return self }
}
