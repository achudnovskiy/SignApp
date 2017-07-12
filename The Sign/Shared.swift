//
//  Shared.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-05-27.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import Foundation
import UIKit

let kNotificationSignNearby         = NSNotification.Name(rawValue:"SignNearby")
let kNotificationSignNearbyId       = "kNotificationSignNearbyId"
let kNotificationSignNearbyDistance = "kNotificationSignNearbyDistance"

let kNotificationReloadData         = NSNotification.Name(rawValue:"ReloadData")
let kNotificationScrollToSign       = NSNotification.Name(rawValue:"NotificationScrollToSign")
let kNotificationScrollToSignId     = "NotificationScrollToSignId"

let signColor = UIColor(red: 226.0 / 255.0, green: 106.0 / 255.0, blue: 42.0 / 255.0, alpha: 1.0)
