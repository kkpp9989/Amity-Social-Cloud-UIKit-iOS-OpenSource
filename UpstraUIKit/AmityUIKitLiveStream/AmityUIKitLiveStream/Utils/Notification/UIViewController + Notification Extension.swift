//
//  UIViewController + Notification Extension.swift
//  AmityUIKitLiveStream
//
//  Created by Thanaphat Thanawatpanya on 29/8/2566 BE.
//

// [Custom for ONE Krungthai][Improvement] Add UNUserNotificationCenterDelegate function for handle show notification in each viewcontroller

import UIKit
import UserNotifications

struct AmityNotificationUtilities {
    public static var pauseNotifications: Bool = false
}

extension UIViewController: UNUserNotificationCenterDelegate {
    // This method is called when a notification is received while the app is in the foreground.
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if AmityNotificationUtilities.pauseNotifications {
            print("[Notification] Set pauseNotifications is \(AmityNotificationUtilities.pauseNotifications) -> Don't show notification")
            if #available(iOS 14.0, *) {
                completionHandler([.badge, .list]) // Do not show the notification but show in list and still effect to badge for iOS 14.0 or later
            } else {
                completionHandler([.badge]) // Do not show the notification but still effect to badge for iOS 12 - 13
            }
        } else {
            print("[Notification] Set pauseNotifications is \(AmityNotificationUtilities.pauseNotifications) -> Show notification")
            completionHandler([.alert, .badge, .sound]) // Show the notification
        }
    }
}
