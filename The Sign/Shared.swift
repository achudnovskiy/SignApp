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
let kNotificationSignNearbyId       = "SignNearbyId"
let kNotificationSignNearbyDistance = "SignNearbyDistance"

let kNotificationReloadData         = NSNotification.Name(rawValue:"ReloadData")
let kNotificationScrollToSign       = NSNotification.Name(rawValue:"ScrollToSign")
let kNotificationScrollToSignId     = "ScrollToSignId"

let kNotificationErrorState         = NSNotification.Name(rawValue:"ErrorState")

let kNotificationPermissionsUpdate  = NSNotification.Name(rawValue:"PermissionsUpdate")

let signColor = UIColor(red: 226.0 / 255.0, green: 106.0 / 255.0, blue: 42.0 / 255.0, alpha: 1.0)
