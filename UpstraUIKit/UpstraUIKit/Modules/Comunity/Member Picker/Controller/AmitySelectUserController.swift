//
//  AmitySelectUserController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 21/12/2563 BE.
//  Copyright © 2563 BE Amity. All rights reserved.
//

import UIKit

final class AmitySelectUserController {
    
    func selectUser(searchUsers: [AmitySelectMemberModel], users: inout AmityFetchUserController.GroupUser, newSelectedUsers: inout [AmitySelectMemberModel], at indexPath: IndexPath, isSearch: Bool) {

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
        } else {
            newSelectedUsers.append(selectedUser)
        }
        selectedUser.isSelected.toggle()
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
