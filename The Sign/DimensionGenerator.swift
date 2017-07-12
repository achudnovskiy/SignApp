//
//  DimensionGenerator.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-07-11.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import CoreGraphics

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
    
    var cardKeywordFontSize:CGFloat { return ceil(phoneSizeRatio*27)}
    var carLocationFontSize:CGFloat { return ceil(phoneSizeRatio*13)}
    var cardContentFontSize:CGFloat { return ceil(phoneSizeRatio*11)}
    var cardExtraTopSize:CGFloat { return ceil(phoneSizeRatio*20)}
    var cardExtraBottomFontSize:CGFloat { return ceil(phoneSizeRatio*32)}
    
}
