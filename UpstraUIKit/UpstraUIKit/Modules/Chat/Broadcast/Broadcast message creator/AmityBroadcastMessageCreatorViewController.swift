//
//  AmityBroadcastMessageCreatorViewController.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 31/1/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import UIKit

/// A view controller for providing message full creator.
public class AmityBroadcastMessageCreatorViewController: AmityMessageTextFullEditorViewController {

    // This is a wrapper class to help fill in parameters.
    public static func make(messageTarget: AmityMessageTarget, settings: AmityMessageFullTextEditorSettings = AmityMessageFullTextEditorSettings()) -> AmityBroadcastMessageCreatorViewController {
        return AmityBroadcastMessageCreatorViewController(messageTarget: messageTarget, messageMode: .create, settings: settings)
    }
    
}
