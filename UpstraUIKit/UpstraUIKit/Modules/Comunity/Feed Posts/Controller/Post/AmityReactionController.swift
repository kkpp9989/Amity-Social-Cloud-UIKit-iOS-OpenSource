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
    case sangsun = "สร้างสรรค์"
    case satsue = "สัตย์ซื่อ"
    case samakki = "สามัคคี"
    case sumrej = "สำเร็จ"
    case sangkom = "สังคม"
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
