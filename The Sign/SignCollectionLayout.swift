//
//  SignCollectionLayout.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-04-22.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit

class SignCollectionLayout: UICollectionViewFlowLayout {
    var fullScreenItemIndex:IndexPath?
    var fullScreenItemSize:CGSize!
    
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let layoutAttributes = super.layoutAttributesForItem(at: indexPath);
        if indexPath == fullScreenItemIndex {
            layoutAttributes?.size = fullScreenItemSize
            layoutAttributes?.zIndex = 1
        }
        return layoutAttributes
    }
}
