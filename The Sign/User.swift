//
//  User.swift
//  The Sign
//
//  Created by Sophos on 2017-05-15.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import CoreLocation
import UserNotifications

typealias LocationPermissionCheck = () -> Bool
typealias NotificationPermissionCheck = () -> Bool

enum PermissionStatus:String {
    case Granted
    case Evaluating
    case Denied
}

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
    
    func evaluatePermissions() {
        locatingPermitted = CLLocationManager.authorizationStatus() == .authorizedAlways ? .Granted : .Denied
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            self.notificationsPermitted = settings.alertSetting == .enabled ? .Granted : .Denied
            NotificationCenter.default.post(name: kNotificationPermissionsUpdate, object: nil)
        }
    }
    
    var locatingPermitted:PermissionStatus = .Evaluating
    var notificationsPermitted:PermissionStatus = .Evaluating
}
