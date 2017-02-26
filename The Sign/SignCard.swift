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

class SignCard: UICollectionViewCell {
    
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var keywordLabel: UILabel!
  
    @IBOutlet weak var contentWrapperView: UIView!
    @IBOutlet weak var contentImage: UIImageView!
    
    @IBOutlet weak var cnstrContentWrapperHeight: NSLayoutConstraint!
    @IBOutlet weak var cnstrContentWrapperCenterY: NSLayoutConstraint!
    @IBOutlet weak var cnstrContentWrapperBottom: NSLayoutConstraint!

    override func prepareForReuse() {
        contentImage.alpha = 1
        keywordLabel.alpha = 1
        keywordLabel.isHidden = true
        contentImage.isHidden = true
        contentImage.image = nil
        backgroundImage.image = nil
        keywordLabel.text = nil
    }
    
    func prepareViewForMode(viewMode:SignCardViewMode, isFullscreenView isFullscreen :Bool) {
        switch viewMode {
        case .Discovered:
            isFullscreen ? setConstraintsForFullscreen() : setConstraintsForThumbnail()
        case .NotDiscovered:
            isFullscreen ? setConstraintsForFullscreenNotDiscovered() : setConstraintsForThumbnailNotDiscovered()
        case .NotCollected:
            isFullscreen ? setConstraintsForFullscreenNotCollected() : setConstraintsForThumbnailNotCollected()
        }
    }
    
    //MARK: - View Animation

    func prepareViewForAnimation(toFullscreen:Bool) {
        layer.zPosition = 1
        if toFullscreen {
            setConstraintsForFullscreen()
            contentImage.alpha = 0
            contentImage.isHidden =  false
        }
        else {
            setConstraintsForThumbnail()
            keywordLabel.alpha = 0
            keywordLabel.isHidden = false
        }
    }
    
    func setViewSizeForAnimation(newSize:CGSize) {
        var frame = self.bounds;
        let center = self.center
        frame.size = newSize
        self.bounds = frame;
        self.center = center
    }
    
    func setComponentsForAnimation(toFullscreen:Bool) {
        if toFullscreen {
            keywordLabel.alpha = 0
            contentImage.alpha = 1
        }
        else {
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
        cnstrContentWrapperHeight.constant = self.bounds.height
        cnstrContentWrapperBottom.isActive = false
        cnstrContentWrapperCenterY.isActive = true
        
        contentImage.isHidden = true
        keywordLabel.isHidden = false
    }
    
    func setConstraintsForThumbnailNotDiscovered() {
        cnstrContentWrapperHeight.constant = self.bounds.height
        cnstrContentWrapperBottom.isActive = false
        cnstrContentWrapperCenterY.isActive = true
        
        contentImage.isHidden = true
        keywordLabel.isHidden = false
    }
    
    func setConstraintsForFullscreenNotCollected() {
        cnstrContentWrapperHeight.constant = self.bounds.height
        cnstrContentWrapperBottom.isActive = false
        cnstrContentWrapperCenterY.isActive = true
        
        contentImage.isHidden = true
        keywordLabel.isHidden = false
        backgroundImage.image = backgroundImage.image?.applyDefaultEffect()
    }
    
    func setConstraintsForThumbnailNotCollected() {
        cnstrContentWrapperHeight.constant = self.bounds.height
        cnstrContentWrapperBottom.isActive = false
        cnstrContentWrapperCenterY.isActive = true
        
        contentImage.isHidden = true
        keywordLabel.isHidden = false
        backgroundImage.image = backgroundImage.image?.applyDefaultEffect()
    }
}
