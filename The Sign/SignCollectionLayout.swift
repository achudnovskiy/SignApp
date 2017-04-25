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
    var referencePoint:CGPoint?

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let arr = super.layoutAttributesForElements(in: rect)!
        return arr.map {
            atts in
            
            var atts = atts
            if atts.representedElementCategory == .cell {
                let ip = atts.indexPath
                atts = self.layoutAttributesForItem(at:ip)!
            }
            return atts
        }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let layoutAttributes = super.layoutAttributesForItem(at: indexPath);
        if indexPath == fullScreenItemIndex && (collectionView != nil) {
            
            let bound = collectionView!.bounds.width / 3
            let diff =  abs(collectionView!.contentOffset.x + collectionView!.bounds.width / 2 - referencePoint!.x) / bound
            
            let fullScreenSize = collectionView!.bounds.size
            if diff <= 0.5 {
                layoutAttributes?.size = CGSize(width: fullScreenSize.width * (1 - diff), height: fullScreenSize.height * (1 - diff))
                layoutAttributes?.center = CGPoint(x: referencePoint!.x, y: referencePoint!.y + kCollectionItemCenterOffset / 2 * diff * 2)
            }
            layoutAttributes?.zIndex = 1
        }
        return layoutAttributes
    }
    
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return fullScreenItemIndex != nil
    }
}
