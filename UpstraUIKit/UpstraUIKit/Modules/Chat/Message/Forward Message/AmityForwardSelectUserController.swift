//
//  AmityForwardSelectUserController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 25/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

final class AmityForwardSelectUserController {
    
    func selectUser(searchUsers: [AmitySelectMemberModel], users: inout AmityFetchForwardUserController.GroupUser, newSelectedUsers: inout [AmitySelectMemberModel], at indexPath: IndexPath, isSearch: Bool) {

        var selectedUser: AmitySelectMemberModel!
        
        if isSearch {
            selectedUser = searchUsers[indexPath.row]
            users.forEach {
                if let index = $0.value.firstIndex(where: { $0 == selectedUser }) {
                    $0.value[index].isSelected = !selectedUser.isSelected
                }
            }
        } else {
            selectedUser = users[indexPath.section].value[indexPath.row]
        }
        
        if let user = newSelectedUsers.first(where: { $0 == selectedUser}), let index = newSelectedUsers.firstIndex(of: user) {
            newSelectedUsers.remove(at: index)
            selectedUser.isSelected = false
        } else {
            if newSelectedUsers.count == 20 {
                let firstAction = AmityDefaultModalModel.Action(title: AmityLocalizedStringSet.General.ok,
                                                                textColor: AmityColorSet.baseInverse,
                                                                backgroundColor: AmityColorSet.primary)
                let communityPostModel = AmityDefaultModalModel(image: nil,
                                                                title: "Unable to select one more chat?",
                                                                description: "Maximun number of chats that you can forward to is 20.",
                                                                firstAction: firstAction, secondAction: nil,
                                                                layout: .horizontal)
                let communityPostModalView = AmityDefaultModalView.make(content: communityPostModel)
                communityPostModalView.firstActionHandler = {
                    AmityHUD.hide()
                }
                
                AmityHUD.show(.custom(view: communityPostModalView))
                
                return
            }
            newSelectedUsers.append(selectedUser)
            selectedUser.isSelected = true
        }
    }
    
    func deselect(searchUsers: inout [AmitySelectMemberModel], users: inout AmityFetchUserController.GroupUser, newSelectedUsers: inout [AmitySelectMemberModel], at indexPath: IndexPath) {
        let selectedUser = newSelectedUsers[indexPath.item]
        // Deselect in users list
        users.forEach {
            if let index = $0.value.firstIndex(where: { $0 == selectedUser }) {
                $0.value[index].isSelected = false
            }
        }
        
        // Deselect in search users list
        if let index = searchUsers.firstIndex(where: { $0 == selectedUser }) {
            searchUsers[index].isSelected = false
        }
        
        newSelectedUsers.remove(at: indexPath.item)
    }
}
