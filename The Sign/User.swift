//
//  User.swift
//  The Sign
//
//  Created by Sophos on 2017-05-15.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit
import FBSDKCoreKit

typealias LocationPermissionCheck = () -> Bool
typealias NotificationPermissionCheck = () -> Bool

class User: NSObject {
    
    static let current = User()

    var isFirstTime:Bool = false
    var locationPermissionCheck:LocationPermissionCheck = {() in return false}
    var notificationPermissionCheck:NotificationPermissionCheck = {() in return false}

    var isLoggedIn:Bool {
        get {
            return FBSDKAccessToken.current() != nil
        }
    }
    
    var locatingPermitted:Bool {
        get {
            return locationPermissionCheck()
        }
    }
    var notificationsPermitted:Bool {
        get {
            return notificationPermissionCheck()
        }
    }
}
