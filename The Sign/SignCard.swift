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
}

class SignCard: UICollectionViewCell, UIGestureRecognizerDelegate {

    @IBOutlet weak var wrapperView: UIImageView!
    @IBOutlet weak var keywordLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    
    @IBOutlet weak var signOverlayView: UIView!
    @IBOutlet weak var signLabelTop: UILabel!
    @IBOutlet weak var signLabelBottom: UILabel!
    
    @IBOutlet weak var signLogoImageView: UIImageView!
    
    @IBOutlet weak var cnstrKeywordTop: NSLayoutConstraint!
    @IBOutlet weak var cnstrKeywordAllignY: NSLayoutConstraint!
    @IBOutlet weak var cnstrKeywordAlignX: NSLayoutConstraint!
    @IBOutlet weak var cnstrKeywordHeight: NSLayoutConstraint!
    @IBOutlet weak var cnstrKeywordLead: NSLayoutConstraint!
    
    @IBOutlet weak var contentWrapperView: UIView!
    @IBOutlet weak var cnstrContentWrapperHeightLess: NSLayoutConstraint!
    @IBOutlet weak var cnstrContentWrapperHeight: NSLayoutConstraint!
    @IBOutlet weak var cnstrContentWrapperWidth: NSLayoutConstraint!
    
    @IBOutlet weak var signLogoHeight: NSLayoutConstraint!
    @IBOutlet weak var signLogoTopMargin: NSLayoutConstraint!
    @IBOutlet weak var signLogoBottomMargin: NSLayoutConstraint!
    
    
    
    var blurEffectView: UIVisualEffectView!
    var animator: UIViewPropertyAnimator!

    var viewMode:SignCardViewMode = .Discovered

    var shareDelegate:SignShareProtocol?

    var panGesture: UIPanGestureRecognizer!
    var originalCenter:CGPoint?
    var panOffset:CGFloat?

    var isFullscreen:Bool = false
    
    func applyBorder(visible:Bool) {
        self.layer.borderColor = UIColor.lightGray.cgColor
        if visible {
            self.layer.borderWidth = 1
        }
        else {
            self.layer.borderWidth = 0
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        removeGestureRecognizer(panGesture)
        shareDelegate = nil
        
        contentWrapperView.isHidden = false
        signOverlayView.isHidden = true
        
        contentLabel.alpha = 1
        contentLabel.isHidden = true
        contentLabel.text = nil
        locationLabel.alpha = 1
        locationLabel.isHidden = true
        locationLabel.text = nil
        
        keywordLabel.alpha = 1
        keywordLabel.text = nil
        wrapperView.image = nil
        wrapperView.isOpaque = true
        
        animator.stopAnimation(false)
        stopLogoAnimatoin()
        animator.finishAnimation(at: .end)
        animator = nil
        blurEffectView.removeFromSuperview()
        blurEffectView = nil
        
        signLabelBottom.font = UIFont(descriptor: signLabelBottom.font.fontDescriptor, size: signLabelTop.font.pointSize)
    }
    
    func prepareViewForMode(viewMode:SignCardViewMode, isFullscreenView isFullscreen :Bool) {
        self.viewMode = viewMode
        
        if isFullscreen {
            self.applyBorder(visible: false)
            setConstraintsForFullscreen()
            updateElementsVisibility(isVisible: true)
        }
        else {
            self.applyBorder(visible: true)
            switch viewMode {
            case .Discovered:
                setConstraintsForThumbnail()
            case .NotDiscovered:
                setConstraintsForThumbnailNotDiscovered()
            }
            
            updateElementsVisibility(isVisible: false)
        }
    }
    
    func prepareForExtraSign(extraType:ExtraSignType, topText:String, bottomText:String) {
        signOverlayView.isHidden = false
        contentWrapperView.isHidden = true
        signLabelTop.text = topText.uppercased()
        signLabelBottom.text = bottomText.uppercased()
        
        switch extraType {
        case .Discovery:
            signLogoHeight.constant = 0
            signLogoTopMargin.constant = -10
            signLogoBottomMargin.constant = 15
            signLabelBottom.font = UIFont(descriptor: signLabelBottom.font.fontDescriptor, size: signLabelBottom.font.pointSize + 10)
        case .Loading:
            signLogoHeight.constant = 32
            signLogoTopMargin.constant = 5
            signLogoBottomMargin.constant = 5
        case .Problem:
            signLogoHeight.constant = 32
            signLogoTopMargin.constant = 5
            signLogoBottomMargin.constant = 5
        case .StayTuned:
            signLogoHeight.constant = 32
            signLogoTopMargin.constant = 5
            signLogoBottomMargin.constant = 5
        }
        self.applyBorder(visible: true)
    }

    func startLogoAnimatoin() {
        stopLogoAnimatoin()
        DispatchQueue.main.async {
            UIView.animate(withDuration: 1.0, delay: 0, options: [.curveEaseInOut, .autoreverse, .repeat], animations: {
                self.signLogoImageView.alpha =  0.5
            }, completion: nil)
            
        }
    }
    func stopLogoAnimatoin() {
        self.signLogoImageView.layer.removeAllAnimations()
    }
    
    func prepareBlur() {
        self.blurEffectView = UIVisualEffectView(frame: self.bounds)
        self.blurEffectView.effect = UIBlurEffect(style: .light)
        self.addSubview(self.blurEffectView)
        self.animator = UIViewPropertyAnimator(duration: 0, curve: .linear) {
            self.blurEffectView.effect = nil
        }
        self.animator.startAnimation()
        self.animator.pauseAnimation()
    }
    
    func updateElementsVisibility(isVisible:Bool) {
        if isVisible {
            locationLabel.isHidden = false
            contentLabel.isHidden = false
        }
        else {
            locationLabel.isHidden = true
            contentLabel.isHidden = true
        }
    }
    
    func prepareGestureRecognition() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.actionPan(_:)))
        panGesture.delegate = self
        panGesture.delaysTouchesBegan = true
        addGestureRecognizer(panGesture)
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        
//        let ratio = layoutAttributes.frame.height / DimensionGenerator.current.collectionItemSize.height*1.9 - 0.9
//
//        if isFullscreen {
//
//            let maxDistance = UIScreen.main.bounds.height - DimensionGenerator.current.collectionItemSize.height
//            let curDistance = UIScreen.main.bounds.height - wrapperView.bounds.height
//            let ratio = curDistance / maxDistance //0 when fullscreen, 1 when thumbnail
//
//            let newHeight = round(70 + 70 * (1-ratio))
//            cnstrContentWrapperHeight.constant = DimensionGenerator.current/
//
//            locationLabel.alpha = 1 - ratio
//            contentLabel.alpha = 1 - ratio
//        }
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let velocity = panGesture!.velocity(in: self)
        return fabs(velocity.y) > fabs(velocity.x)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func actionPan(_ sender: UIGestureRecognizer) {
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
            
            
            reportShareProgress(progress: shareProgressValue(originalPoint: originalCenter!, newPoint: center, itemFrame: bounds), finished: false)
            
            break
        case .cancelled:
            break
        case .ended:
            reportShareProgress(progress: shareProgressValue(originalPoint: originalCenter!, newPoint: center, itemFrame: bounds), finished: true)
            snapBack()
            self.panOffset = nil
            
            break
        default:
            break
        }
    }
    
    func didPassShareThreshold(progress:CGFloat) -> Bool {
        if isFullscreen {
            return progress > 0.4
        }
        else {
            return progress > 0.5
        }
    }

    
    func reportShareProgress(progress:CGFloat, finished:Bool)  {
        if finished {
            shareDelegate?.resetShareProgress()
            if didPassShareThreshold(progress: progress) {
                shareDelegate?.didShareSignCard(signCard: self)
            }
        }
        else {
            shareDelegate?.updateShareProgress(progress: progress, didPassThreshold: didPassShareThreshold(progress: progress))
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
            self.updateElementsVisibility(isVisible: true)
            locationLabel.alpha = 0
            contentLabel.alpha = 0
        }
        else {
        }
    }
    
    func setViewSizeForAnimation(newSize:CGSize, toFullscreen:Bool) {
        var frame = self.bounds;
        let center = self.center
        frame.size = newSize
        self.bounds = frame;
        if toFullscreen {
            self.center = CGPoint(x: center.x, y: center.y - DimensionGenerator.current.collectionItemThumbnailOffset / 2)
            locationLabel.alpha = 1
            contentLabel.alpha = 1
            keywordLabel.textAlignment = .left
        }
        else {
            self.center = CGPoint(x: center.x, y: center.y + DimensionGenerator.current.collectionItemThumbnailOffset / 2)
            locationLabel.alpha = 0
            contentLabel.alpha = 0
        }
    }

    
    func prepareViewAfterAnimation(toFullscreen:Bool) {
        self.isFullscreen = toFullscreen
        self.updateElementsVisibility(isVisible: self.isFullscreen)
    }

    func setConstraintsForFullscreen() {
        
        cnstrContentWrapperHeight.priority = UILayoutPriorityDefaultLow
        cnstrContentWrapperHeightLess.priority = 999
        cnstrContentWrapperHeightLess.constant = DimensionGenerator.current.collectionItemContentFullHeight
        cnstrContentWrapperWidth.constant = DimensionGenerator.current.collectionItemContentFullWidth
        
        cnstrKeywordAlignX.priority = UILayoutPriorityDefaultLow
        cnstrKeywordLead.priority = 999
        cnstrKeywordAllignY.priority = UILayoutPriorityDefaultLow
        cnstrKeywordTop.priority = 999
        
        keywordLabel.numberOfLines = 1
    }

    func setConstraintsForThumbnail() {
        
        cnstrContentWrapperHeightLess.priority = UILayoutPriorityDefaultLow
        cnstrContentWrapperHeight.priority = 999
        cnstrContentWrapperHeight.constant = DimensionGenerator.current.collectionItemContentSmallHeight
        cnstrContentWrapperWidth.constant = DimensionGenerator.current.collectionItemContentSmallWidth
        
        cnstrKeywordAlignX.priority = 999
        cnstrKeywordLead.priority = UILayoutPriorityDefaultLow
        cnstrKeywordAllignY.priority = 999
        cnstrKeywordTop.priority = UILayoutPriorityDefaultLow
        
        cnstrKeywordHeight.priority = 999
        keywordLabel.numberOfLines = 1
    }
    
    func setConstraintsForThumbnailNotDiscovered() {
        cnstrContentWrapperHeightLess.priority = UILayoutPriorityDefaultLow
        cnstrContentWrapperHeight.priority = 999
        //TODO: replace with optional top/lead constraints to wrapperView
        cnstrContentWrapperHeight.constant = self.bounds.height
        cnstrContentWrapperWidth.constant = self.bounds.width
        
        cnstrKeywordLead.priority = UILayoutPriorityDefaultLow
        cnstrKeywordAlignX.priority = 999
        cnstrKeywordTop.priority = UILayoutPriorityDefaultLow
        cnstrKeywordAllignY.priority = 999
        
        cnstrKeywordHeight.priority = UILayoutPriorityDefaultLow
        keywordLabel.numberOfLines = 5
    }
}
