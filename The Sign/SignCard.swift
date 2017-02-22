//
//  SignCard.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-01-14.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit

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

    func setConstraintsForFullscreenMystery() {
        cnstrContentWrapperHeight.constant = self.bounds.height
        cnstrContentWrapperBottom.isActive = false
        cnstrContentWrapperCenterY.isActive = true
    }
    func setConstraintsForThumbnail() {
        cnstrContentWrapperHeight.constant = 70
        cnstrContentWrapperBottom.isActive = false
        cnstrContentWrapperCenterY.isActive = true
    }
    func setConstraintsForThumbnailMystery() {
        cnstrContentWrapperHeight.constant = self.bounds.height
        cnstrContentWrapperBottom.isActive = false
        cnstrContentWrapperCenterY.isActive = true
    }
    
    func setConstraintsForFullscreen() {
        cnstrContentWrapperHeight.constant = 140
        cnstrContentWrapperCenterY.isActive = false
        cnstrContentWrapperBottom.isActive = true
    }
}
