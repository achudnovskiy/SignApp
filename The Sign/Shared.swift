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
    var gridSize:CGFloat {
        return round(phoneSizeRatio * 200)
    }
    var gridCellSize:CGFloat {
        return round(gridSize / 10)
    }
    
    var mapButtonWidth:CGFloat {
        return gridCellSize * 2
    }
    
    var collectionItemSize:CGSize {
        return CGSize(width: gridSize, height: round(gridSize*1.77))
    }
    var collectionItemSpacing:CGFloat {
        return gridCellSize
    }
    
    var collectionItemThumbnailInset:CGFloat {
        return gridCellSize * 2
    }
    var collectionItemThumbnailOffset:CGFloat {
        return gridCellSize * 5
    }
    
    var collectionItemContentSmallWidth:CGFloat {
        return round(gridSize * 0.75)
    }
    
    var collectionItemContentSmallHeight:CGFloat {
        return round(gridSize * 0.65)
//        return round(gridSize)
    }
    
    var collectionItemContentFullWidth:CGFloat {
        return round(gridSize * 1.2)
    }
    
    var collectionItemContentFullHeight:CGFloat {
        return round(gridSize*1.5)
    }
}



//
//let phoneSizeRatio:CGFloat = 1.18
//let gridSize:CGFloat = round(200 * phoneSizeRatio)
//let gridCellSize = gridSize / 10
//
//let kMapButtonWidth = gridCellSize * 2
//
//let kCollectionItemSize = CGSize(width: gridSize, height: gridSize*1.77)
//let kCollectionItemSpacing:CGFloat = gridSize * 0.1
//let kCollectionItemThumbnailInset:CGFloat = 0.2*gridSize
//let kCollectionItemCenterOffset:CGFloat = kCollectionItemThumbnailInset * 2
//let kCollectionItemContentSmallWidth:CGFloat = 0.75 * gridSize
//let kCollectionItemContentSmallHeight:CGFloat = 150
//let kCollectionItemContentFullWidth:CGFloat = gridSize * 0.625
//let kCollectionItemContentFullHeight:CGFloat = kCollectionItemContentFullWidth * 5 / 6


let kNotificationReloadData = NSNotification.Name(rawValue:"ReloadData")
let kNotificationScrollToSign = NSNotification.Name(rawValue:"NotificationScrollToSign")
let kNotificationScrollToSignId = "NotificationScrollToSignId"
