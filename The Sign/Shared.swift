//
//  Shared.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-05-27.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import Foundation
import UIKit

class DimensionGenerator {
    var phoneSizeRatio:CGFloat = 1
    
    static let current = DimensionGenerator()
    var gridSize:CGFloat { return round(phoneSizeRatio * 200) }
    var gridCellSize:CGFloat { return round(gridSize / 10) }
    var mapButtonWidth:CGFloat { return gridCellSize * 2 }
    var collectionItemSize:CGSize { return CGSize(width: gridSize, height: round(gridSize*1.77)) }
    var collectionItemSpacing:CGFloat { return gridCellSize }
    var collectionItemThumbnailInset:CGFloat { return gridCellSize * 2 }
    var collectionItemThumbnailOffset:CGFloat { return gridCellSize * 5 }
    var collectionItemContentSmallWidth:CGFloat { return round(gridSize * 0.75) }
    var collectionItemContentSmallHeight:CGFloat { return round(gridSize * 0.65) }
    var collectionItemContentFullWidth:CGFloat { return round(gridSize * 1.2) }
    var collectionItemContentFullHeight:CGFloat { return round(gridSize*1.5) }
}

let kNotificationSignNearby         = NSNotification.Name(rawValue:"SignNearby")
let kNotificationSignNearbyId       = "kNotificationSignNearbyId"
let kNotificationSignNearbyDistance = "kNotificationSignNearbyDistance"

let kNotificationReloadData         = NSNotification.Name(rawValue:"ReloadData")
let kNotificationScrollToSign       = NSNotification.Name(rawValue:"NotificationScrollToSign")
let kNotificationScrollToSignId     = "NotificationScrollToSignId"
