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
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let superAttributes = super.layoutAttributesForElements(in: rect),
            let attributes = NSArray(array: superAttributes, copyItems: true) as? [UICollectionViewLayoutAttributes]
            else { return nil }
        
        return attributes.map({
            atts in
            
            var atts = atts
            if atts.representedElementCategory == .cell {
                let ip = atts.indexPath
                atts = self.layoutAttributesForItem(at:ip)!
            }
            return atts
            
        })
        
        
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let layoutAttributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes else { return nil}
        guard let collectionView = self.collectionView else { return layoutAttributes }
        
        if indexPath == fullScreenItemIndex {
            
            guard let focusSignCenter = collectionView.cellForItem(at: fullScreenItemIndex!)?.center else {return layoutAttributes}
            let bound = collectionView.bounds.width / 3
            
            let diff =  abs(collectionView.contentOffset.x + collectionView.bounds.width / 2 - focusSignCenter.x) / bound
            
            let fullScreenSize = collectionView.bounds.size
            if diff <= 0.5 {
                layoutAttributes.size = CGSize(width: fullScreenSize.width * (1 - diff), height: fullScreenSize.height * (1 - diff))
//                layoutAttributes?.center = CGPoint(x: focusSignCenter.x, y: focusSignCenter.y + kCollectionItemCenterOffset / 2 * diff * 2)
            }
            layoutAttributes.zIndex = 1
        }
        else {
            let collectionCenter = collectionView.frame.size.width/2
            let offset = collectionView.contentOffset.x
            let normalizedCenter = layoutAttributes.center.x - offset
            
            let maxDistance = self.itemSize.width + self.minimumLineSpacing
            let distance = min(abs(collectionCenter - normalizedCenter), maxDistance)
            let ratio = (maxDistance - distance)/maxDistance
            
            let scaleFactor:CGFloat = 0.9
            let scale = ratio * (1 - scaleFactor) + scaleFactor
            layoutAttributes.transform3D = CATransform3DScale(CATransform3DIdentity, scale, scale, 1)
            
        }
        return layoutAttributes
    }
    
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override open func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView , !collectionView.isPagingEnabled,
            let layoutAttributes = self.layoutAttributesForElements(in: collectionView.bounds)
            else { return super.targetContentOffset(forProposedContentOffset: proposedContentOffset) }
        
        let midSide = collectionView.bounds.size.width / 2
        let proposedContentOffsetCenterOrigin = proposedContentOffset.x + midSide
        
        var targetContentOffset: CGPoint
        let closest = layoutAttributes.sorted { abs($0.center.x - proposedContentOffsetCenterOrigin) < abs($1.center.x - proposedContentOffsetCenterOrigin) }.first ?? UICollectionViewLayoutAttributes()
        targetContentOffset = CGPoint(x: floor(closest.center.x - midSide), y: proposedContentOffset.y)
        
        return targetContentOffset
    }
}
