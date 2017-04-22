//
//  SignCard.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-01-14.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit

enum SignCardViewMode {
    case Discovered
    case NotDiscovered
    case NotCollected
}

class SignCard: UICollectionViewCell, UIGestureRecognizerDelegate {

    @IBOutlet weak var wrapperView: UIImageView!
    @IBOutlet weak var keywordLabel: UILabel!
  
    @IBOutlet weak var contentWrapperView: UIView!
    @IBOutlet weak var contentImage: UIImageView!
    
    @IBOutlet weak var cnstrContentWrapperHeight: NSLayoutConstraint!
    @IBOutlet weak var cnstrContentWrapperCenterY: NSLayoutConstraint!
    @IBOutlet weak var cnstrContentWrapperBottom: NSLayoutConstraint!
    
    var viewMode:SignCardViewMode = .Discovered


    var shareProgressHandler:((_ progress:CGFloat, _ finished:Bool) -> Void)!

    var panGesture: UIPanGestureRecognizer!
    var originalCenter:CGPoint?
    var panOffset:CGFloat?

    override func prepareForReuse() {
        removeGestureRecognizer(panGesture)
        contentImage.alpha = 1
        keywordLabel.alpha = 1
        keywordLabel.isHidden = true
        contentImage.isHidden = true
        contentImage.image = nil
        wrapperView.image = nil
        keywordLabel.text = nil
        wrapperView.isOpaque = true
        super.prepareForReuse()
    }
    
    func prepareViewForMode(viewMode:SignCardViewMode, isFullscreenView isFullscreen :Bool) {
        self.viewMode = viewMode
        switch viewMode {
        case .Discovered:
            isFullscreen ? setConstraintsForFullscreen() : setConstraintsForThumbnail()
        case .NotDiscovered:
            isFullscreen ? setConstraintsForFullscreenNotDiscovered() : setConstraintsForThumbnailNotDiscovered()
        case .NotCollected:
            isFullscreen ? setConstraintsForFullscreenNotCollected() : setConstraintsForThumbnailNotCollected()
        }
    }
    
    func prepareGestureRecognition() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.actionPan(_:)))
        panGesture.delegate = self
        panGesture.delaysTouchesBegan = true
        addGestureRecognizer(panGesture)
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let velocity = panGesture!.velocity(in: self)
        return fabs(velocity.y) > fabs(velocity.x)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func actionPan(_ sender: UIGestureRecognizer)
    {
        let location:CGPoint = sender.location(in: superview)

        switch sender.state {
        case .began:
            originalCenter = center
            panOffset = center.y -  location.y
            break
        case .changed:
            //moving down
            let newLoc = location.y + panOffset!
            let diff = originalCenter!.y - newLoc
            center.y = newLoc + 0.5*diff
            
            shareProgressHandler(shareProgressValue(originalPoint: originalCenter!, newPoint: center, itemFrame: bounds), false)
            break
        case .cancelled:
            break
        case .ended:
            shareProgressHandler(shareProgressValue(originalPoint: originalCenter!, newPoint: center, itemFrame: bounds), true)
            snapBack()
            self.panOffset = nil
            
            break
        default:
            break
        }
        
    }
    
    func shareProgressValue(originalPoint:CGPoint, newPoint:CGPoint, itemFrame:CGRect) -> CGFloat {
        return (originalPoint.y - newPoint.y) / (itemFrame.height / 2)
    }
    
    func snapOut(_ completionHandler:@escaping (Bool)->()) {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: {
            self.center.y = 4 * self.originalCenter!.y
        }, completion: completionHandler)
    }
    
    func snapBack() {
        if originalCenter == nil {
            return
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: {
            self.center.y = self.originalCenter!.y
        }, completion: nil)
    }

    //MARK: - View Animation

    func prepareViewForAnimation(toFullscreen:Bool) {
        layer.zPosition = 1
        prepareViewForMode(viewMode: viewMode, isFullscreenView: toFullscreen)
        if toFullscreen {
            contentImage.alpha = 0
            contentImage.isHidden =  false
        }
        else {
            keywordLabel.alpha = 0
            keywordLabel.isHidden = false
        }
    }
    
    func setViewSizeForAnimation(newSize:CGSize, toFullscreen:Bool) {
        var frame = self.bounds;
        let center = self.center
        frame.size = newSize
        self.bounds = frame;
        if toFullscreen {
            self.center = CGPoint(x: center.x, y: center.y - kCollectionItemCenterOffset / 2)
            keywordLabel.alpha = 0
            contentImage.alpha = 1

        }
        else {
            self.center = CGPoint(x: center.x, y: center.y + kCollectionItemCenterOffset / 2)
            keywordLabel.alpha = 1
            contentImage.alpha = 0

        }
    }

    
    func prepareViewAfterAnimation(toFullscreen:Bool) {
        contentImage.isHidden =  !toFullscreen
        keywordLabel.isHidden =  toFullscreen
    }

    func setConstraintsForFullscreen() {
        cnstrContentWrapperHeight.constant = 140
        cnstrContentWrapperCenterY.isActive = false
        cnstrContentWrapperBottom.isActive = true
        
        contentImage.isHidden = false
        keywordLabel.isHidden = true
    }

    func setConstraintsForThumbnail() {
        cnstrContentWrapperHeight.constant = 70
        cnstrContentWrapperBottom.isActive = false
        cnstrContentWrapperCenterY.isActive = true
        
        contentImage.isHidden = true
        keywordLabel.isHidden = false

    }

    func setConstraintsForFullscreenNotDiscovered() {
        cnstrContentWrapperHeight.constant = wrapperView.bounds.height
        cnstrContentWrapperBottom.isActive = false
        cnstrContentWrapperCenterY.isActive = true
        
        contentImage.isHidden = true
        keywordLabel.isHidden = false
    }
    
    func setConstraintsForThumbnailNotDiscovered() {
        cnstrContentWrapperHeight.constant = wrapperView.bounds.height
        cnstrContentWrapperBottom.isActive = false
        cnstrContentWrapperCenterY.isActive = true
        
        contentImage.isHidden = true
        keywordLabel.isHidden = false
    }
    
    func setConstraintsForFullscreenNotCollected() {
        cnstrContentWrapperHeight.constant = wrapperView.bounds.height
        cnstrContentWrapperBottom.isActive = false
        cnstrContentWrapperCenterY.isActive = true
        
        contentImage.isHidden = true
        keywordLabel.isHidden = false
    }
    
    func setConstraintsForThumbnailNotCollected() {
        cnstrContentWrapperHeight.constant = wrapperView.bounds.height
        cnstrContentWrapperBottom.isActive = false
        cnstrContentWrapperCenterY.isActive = true
        
        contentImage.isHidden = true
        keywordLabel.isHidden = false
    }
}
