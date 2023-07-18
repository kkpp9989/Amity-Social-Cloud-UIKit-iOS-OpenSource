//
//  AmityReactionController.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 2/13/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

public enum AmityReactionType: String {
    case create = "create"
    case honest = "honest"
    case harmony = "harmony"
    case success = "success"
    case society = "society"
    case like = "like"
    case love = "love"
}

protocol AmityReactionControllerProtocol {
    func addReaction(withReaction reaction: AmityReactionType, referanceId: String, referenceType: AmityReactionReferenceType, completion: AmityRequestCompletion?)
    func removeReaction(withReaction reaction: AmityReactionType, referanceId: String, referenceType: AmityReactionReferenceType, completion: AmityRequestCompletion?)
}

final class AmityReactionController: AmityReactionControllerProtocol {
    
    private let repository = AmityReactionRepository(client: AmityUIKitManagerInternal.shared.client)

    func addReaction(withReaction reaction: AmityReactionType, referanceId: String, referenceType: AmityReactionReferenceType, completion: AmityRequestCompletion?) {
        repository.addReaction(reaction.rawValue, referenceId: referanceId, referenceType: referenceType, completion: completion)
    }
    
    func removeReaction(withReaction reaction: AmityReactionType, referanceId: String, referenceType: AmityReactionReferenceType, completion: AmityRequestCompletion?) {
        repository.removeReaction(reaction.rawValue, referenceId: referanceId, referenceType: referenceType, completion: completion)
    }
}
