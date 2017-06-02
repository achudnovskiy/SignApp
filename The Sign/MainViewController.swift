//
//  MainViewController.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-01-14.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit
import QuartzCore
import FBSDKShareKit

enum SignAppState {
    case ThumbnailView
    case FullscreenView
    case MapView
}

protocol SignShareProtocol {
    func updateShareProgress(progress:CGFloat, didPassThreshold:Bool)
    func resetShareProgress()
    func didShareSignCard(signCard:SignCard)
}

extension UICollectionView {
    var indexPathForLastRow:IndexPath {
        get {
            let lastSection = numberOfSections - 1
            let lastRow = numberOfItems(inSection: lastSection)
            return IndexPath(row: lastRow, section: lastSection)
        }
    }
}


class MainViewController: UIViewController, UICollectionViewDelegate, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, UIGestureRecognizerDelegate, SignShareProtocol {

    //MARK: Outlets
    
    @IBOutlet weak var signCollectionView: UICollectionView!
    @IBOutlet weak var signCollectionLayout: SignCollectionLayout!
    @IBOutlet weak var mapContainerView: UIView!
    
    @IBOutlet weak var mapButtonView: UIView!
    @IBOutlet weak var stateButtonView: UIView!
    @IBOutlet weak var stateButtonLabel: UILabel!
    @IBOutlet weak var shareProgressLabel: UILabel!
    
    @IBOutlet weak var cnstrStateButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var cnstrMapButtonWidth: NSLayoutConstraint!
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    //MARK: Properties
    
    var mapViewController:MapViewController!
    var delayedTransition = false
    var currentState:SignAppState = .ThumbnailView
    var collectionSigns:[SignObject] = []
    var collectionNewItems:[SignObject] = []
    var discoverySign:SignObject?
    var cachedImages = NSCache<NSString,UIImage>()
    
    //TODO: REVIEW
    func prepareDataSource() {
        collectionSigns = SignDataSource.sharedInstance.collectedSignsOrdered
        collectionNewItems = SignDataSource.sharedInstance.newSigns
        
        //load cache for first three signs
        let cacheCount = collectionSigns.count < 3 ? collectionSigns.count : 3
        for i in 0...cacheCount {
            let sign = collectionSigns[i]
            cachedImages.setObject(sign.proccessImage(), forKey: sign.uniqueId)
        }
        
        LocationTracker.sharedInstance.getClosestSign(with: { (sign) in
            guard sign != nil else {
                return
            }
            
            self.discoverySign = SignDataSource.sharedInstance.findSignObjById(objectId: sign!.objectId)
            guard self.discoverySign != nil else {
                return
            }
            
            DispatchQueue.main.async {
                self.signCollectionView.performBatchUpdates({
                    self.collectionSigns = self.collectionSigns + [self.discoverySign!]
                    self.signCollectionView.performBatchUpdates({
                        self.signCollectionView.insertItems(at: [self.signCollectionView.indexPathForLastRow])
                    }, completion: nil)
                }, completion: nil)
            }
            
        })
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareDataSource()
        
        stateButtonView.applyPlainShadow()
        mapButtonView.applyPlainShadow()
        
        currentState = .ThumbnailView
        signCollectionView.backgroundColor = UIColor.clear
        updateStateButton()
        
        if collectionSigns.count != 0 {
            backgroundImage.image = collectionSigns.first?.image.applyDefaultEffect()?.optimizedImage()
        }
        else {
            let path = Bundle.main.path(forResource: "DefaultBackgroundImage", ofType: "png", inDirectory: "Content")!
            backgroundImage.image = UIImage(contentsOfFile: path)!.applyDefaultEffect()?.optimizedImage()
        }
        
        setCollectionLayoutProperties(collectionLayout: signCollectionLayout, isFullscreen: false)
        
        NotificationCenter.default.addObserver(forName: kNotificationReloadData, object: nil, queue: OperationQueue.main) { (notification) in
            self.prepareDataSource()
            self.signCollectionView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - UI Animations
    func transitionCollectionView(newState:SignAppState) {
        if newState != .FullscreenView && newState != .ThumbnailView {
            return
        }
        self.view.isUserInteractionEnabled = false
        let toFullscreen = newState == .FullscreenView
        let newSize = toFullscreen ? signCollectionView.bounds.size : kCollectionItemSize;
        
        let cellId = indexForItemInFocus!
        let signInTransition = collectionSigns[cellId.row]
        signInTransition.isDiscovered = true
        let cellView = signInFocus!

        
        resetZPosition()
        if toFullscreen {
            signCollectionLayout.fullScreenItemIndex = indexForItemInFocus
            signCollectionLayout.referencePoint = view.convert(view.center, to: signCollectionView)
        }
        else {
            stopMagnification()
        }

        
        cellView.viewMode = .Discovered
        cellView.prepareViewForAnimation(toFullscreen: toFullscreen)

        UIView.animate(withDuration: 0.33, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [], animations: {
            cellView.setViewSizeForAnimation(newSize: newSize, toFullscreen: toFullscreen)
            cellView.layoutIfNeeded()
        }) { (Bool) in
            cellView.prepareViewAfterAnimation(toFullscreen: toFullscreen)
            
            cellView.keywordLabel.text = signInTransition.thumbnailText
            self.currentState = newState
            self.view.isUserInteractionEnabled = true
            self.updateStateButton()
        }
    }
    func stopMagnification() {
        if self.signCollectionLayout.fullScreenItemIndex != nil {
            
            let signCell = self.signCollectionView.cellForItem(at: self.signCollectionLayout.fullScreenItemIndex!) as? SignCard
            signCell?.prepareViewAfterAnimation(toFullscreen: false)
            self.currentState = .ThumbnailView
            self.updateStateButton()

            
            self.signCollectionLayout.fullScreenItemIndex = nil
            self.signCollectionLayout.referencePoint = nil
            
        }
    }
    func resetZPosition() {
        self.signCollectionView.visibleCells.forEach { (cell) in
            cell.layer.zPosition = 0
        }
    }
    
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionSigns.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cardCollectionViewItemIdentifier, for: indexPath) as! SignCard
        let signToShow = collectionSigns[indexPath.row]
        cell.isOpaque = true
        cell.keywordLabel.text = signToShow.thumbnailText.uppercased()
        cell.contentImage.image = signToShow.infographic
        
        var cachedImage = cachedImages.object(forKey: signToShow.uniqueId)
        if cachedImage == nil {
            let imageToCache = signToShow.proccessImage()
            cachedImages.setObject(imageToCache, forKey: signToShow.uniqueId)
            cachedImage = imageToCache
        }
        
        cell.wrapperView.image = cachedImages.object(forKey: signToShow.uniqueId)
        cell.prepareViewForMode(viewMode: signToShow.viewMode, isFullscreenView: false)

        cell.prepareGestureRecognition()
        signCollectionView.panGestureRecognizer.require(toFail: cell.panGesture!)
        cell.shareDelegate = self
        
        return cell
    }
    
    //MARK:- SignShareProtocol
    func updateShareProgress(progress: CGFloat, didPassThreshold:Bool) {
        if didPassThreshold {
            self.updateProgressShareLabel(alphaValue: 1)
        }
        else {
            self.updateProgressShareLabel(alphaValue: progress / 2)
        }
    }
    
    func resetShareProgress() {
        self.updateProgressShareLabel(alphaValue: 0)
    }
    
    func didShareSignCard(signCard: SignCard) {
        if User.current.isLoggedIn {
            let indexPath = self.signCollectionView.indexPath(for: signCard)
            if indexPath == nil {
                return
            }
            let sign = collectionSigns[indexPath!.row]
            FbHandler.shared.createFbStory(sign: sign)
        }
        else {
            performSegue(withIdentifier: "authorizationSegue", sender: nil)
        }
    }
    
    func updateProgressShareLabel(alphaValue:CGFloat) {
        if alphaValue == 0 {
            self.shareProgressLabel.textColor = UIColor.white
            self.shareProgressLabel.alpha = 0
            return
        }
        
        self.shareProgressLabel.alpha = alphaValue
        if alphaValue == 1 {
            self.shareProgressLabel.textColor = UIColor(red: 226.0/255, green: 106.0/255, blue: 42.0/255, alpha: 1)
        }
    }

    
    //MARK:- UICollectionViewDataSourcePrefetching
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let sign = collectionSigns[indexPath.row]
            cachedImages.setObject(sign.proccessImage(), forKey: sign.uniqueId)
        }
    }
    

    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if currentState == .ThumbnailView  && collectionSigns[indexPath.row].isCollected {
            if indexPath != indexForItemInFocus {
                delayedTransition = true
                collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }
            else {
                if let index = indexForItemInFocus {
                    openThumbnailSignAt(indexPath: index)
                }
            }
        }
    }
    
    func openThumbnailSignAt(indexPath:IndexPath) {
        if !collectionSigns[indexPath.row].isDiscovered {
            collectionSigns[indexPath.row].isDiscovered = true
        }
        transitionCollectionView(newState: .FullscreenView)
    }
    
    
    // MARK: - ScrollViewDelegate
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if delayedTransition {
            delayedTransition = false
            if currentState == .ThumbnailView {
                if let index = indexForItemInFocus {
                    openThumbnailSignAt(indexPath: index)
                }
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let index = indexForItemInFocus {
            scheduleUpdateBackgroundForItemAtImdex(index: index.row)
            
            if self.signCollectionLayout.fullScreenItemIndex != nil && self.signCollectionLayout.fullScreenItemIndex != index {
                stopMagnification()
                
                if self.currentState == .FullscreenView {
                    self.currentState = .ThumbnailView
                }
            }
        }
    }
    var startScrollOffset:CGPoint?
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        startScrollOffset = scrollView.contentOffset
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let itemWidth = signCollectionLayout.itemSize.width
        let itemSpacing = signCollectionLayout.minimumLineSpacing
        
        let index = Int(ceil((targetContentOffset.pointee.x) / (itemWidth + itemSpacing)))
        let newTarget = CGPoint( x: CGFloat(index)  * (itemWidth + itemSpacing) ,y: 0)
    
        if newTarget == startScrollOffset && velocity.x != 0 {
            //Avoid choppy return to original spot when user abruptly lifted the finger
            DispatchQueue.main.async {
                scrollView.setContentOffset(newTarget, animated: true)
            }
        }
        else
        {
            targetContentOffset.pointee = newTarget
        }
        
        if currentState == .FullscreenView && collectionSigns[index].isDiscovered == false {
            delayedTransition = true
        }
    }
    
    
    // MARK: - Helper methods
    
    var signInFocus:SignCard? {
        get {
            if let index = indexForItemInFocus {
                return signCollectionView.cellForItem(at: index) as? SignCard
            }
            else {
                return nil
            }
        }
    }
    
    var indexForItemInFocus:IndexPath? {
        get {
            let viewCenter = view.convert(view.center, to: signCollectionView)
            return signCollectionView.indexPathForItem(at: viewCenter)
        }
    }
    var isCollectionViewFullscreen:Bool {
        get {
            return signCollectionLayout.fullScreenItemIndex != nil
        }
    }
    
    func setCollectionLayoutProperties(collectionLayout:UICollectionViewFlowLayout, isFullscreen:Bool) {
        signCollectionView.decelerationRate = UIScrollViewDecelerationRateFast
        if isFullscreen {
            collectionLayout.itemSize = signCollectionView.bounds.size
            collectionLayout.minimumLineSpacing = 0
            collectionLayout.sectionInset = UIEdgeInsets();
        }
        else {
            collectionLayout.itemSize = kCollectionItemSize
            collectionLayout.minimumLineSpacing = kCollectionItemSpacing
            let sideInset = signCollectionView.bounds.size.width / 2 - collectionLayout.itemSize.width / 2
            collectionLayout.sectionInset = UIEdgeInsets(top: kCollectionItemThumbnailInset + kCollectionItemCenterOffset, left: sideInset, bottom: kCollectionItemThumbnailInset, right: sideInset)
        }
        collectionLayout.invalidateLayout()
    }
    
    
    //MARK: - Action Buttons
    
    func stateButtonTextForState(state:SignAppState) -> String {
        switch state {
        case .FullscreenView:
            return "See Collection"
        case .ThumbnailView:
            // TODO: get number of new signs
            let newSigns = collectionNewItems.count
            if newSigns == 0 {
                return "Collected signs"
            } else {
                return "What's New (\(newSigns))"
            }
        case .MapView:
            return "Return to signs"
        }
    }
    
    func updateMapButton(hide:Bool) {
        self.mapButtonView.isUserInteractionEnabled = false
        
        if hide {
            self.cnstrMapButtonWidth.constant = 0
        }
        else {
            self.mapButtonView.isHidden = false
            self.cnstrMapButtonWidth.constant = 35
        }
        
        UIView.animate(withDuration: 0.25, delay: 0.05, usingSpringWithDamping: 0.85, initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: {
            self.mapButtonView.subviews.first?.alpha = hide ? 0 : 1
            self.view.layoutIfNeeded()
        }, completion: {(Bool) in
            self.mapButtonView.isHidden = hide
            self.mapButtonView.isUserInteractionEnabled = !hide
        })
    }
    
    func updateStateButton() {
        let newButtonText = stateButtonTextForState(state: currentState)
        if newButtonText == stateButtonLabel.text {
            return
        }
        
        let attrString = NSAttributedString(string: newButtonText, attributes: [NSFontAttributeName:self.stateButtonLabel.font])
        self.cnstrStateButtonWidth.constant = ceil(attrString.size().width + 14)
        self.stateButtonView.isHidden = false
        
        self.stateButtonView.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.1, animations: {
            self.stateButtonLabel.alpha = 0
        }, completion: {(Bool) in
            self.stateButtonLabel.text = newButtonText
        })
        UIView.animate(withDuration: 0.25, delay: 0.05, usingSpringWithDamping: 0.85, initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: {
            self.stateButtonLabel.alpha = 1
            self.view.layoutIfNeeded()
        }, completion: {(Bool) in
            self.stateButtonView.isUserInteractionEnabled = true
        })
    }
    
    @IBAction func stateButtonAction(_ sender: Any) {
        switch currentState {
        case .FullscreenView:
            transitionCollectionView(newState: .ThumbnailView)
        case .ThumbnailView:
            if collectionNewItems.count != 0 {
                signCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: true)
            }
        case .MapView:
            mapViewController.animateDissappearance {
                self.mapViewController.clearMapView()
                self.mapContainerView.isHidden = true
                self.currentState = self.isCollectionViewFullscreen ? .FullscreenView : .ThumbnailView
                self.updateMapButton(hide: false)
            }
        }        
    }
    
    @IBAction func mapButtonAction(_ sender: Any) {
        if currentState == .FullscreenView {
            let signToLocate = collectionSigns[indexForItemInFocus!.row]
            mapViewController.prepareMapViewToShow(locations: [signToLocate])
        }
        else if currentState == .ThumbnailView {
            mapViewController.prepareMapViewToShow(locations: collectionSigns)
        }
        mapContainerView.isHidden = false
        mapViewController.animateAppearance {
            self.currentState = .MapView
            self.updateStateButton()
            self.updateMapButton(hide: true)
        }
    }
    
    //MARK: - Map View Controller
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EmbeddedMap" {
            mapViewController = segue.destination as! MapViewController
            mapViewController.parentViewBounds = view.bounds
            mapViewController.parentViewCenter = view.center
        }
    }
    

    //MARK: - Background blurred image update
    
    func scheduleUpdateBackgroundForItemAtImdex(index:Int) {
        let dispatchTime: DispatchTime = DispatchTime.now() + Double(Int64(2.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.global(qos: .background).asyncAfter(deadline: dispatchTime, execute: {
            if self.signCollectionView.isDecelerating || self.signCollectionView.isDragging {
                self.scheduleUpdateBackgroundForItemAtImdex(index: index)
                return
            }
            
            let newIndex = self.indexForItemInFocus
            if newIndex == nil {
                return
            }
            
            if index == newIndex?.row
            {
                let actualNextSign = self.collectionSigns[newIndex!.row]
                self.updateBackgroundBlurWithImage(image: actualNextSign.image, imageTag: actualNextSign.objectId)
            }
        })
    }
    
    func updateBackgroundBlurWithImage(image:UIImage, imageTag:String) {
        let newHash = imageTag.hash
        if backgroundImage.tag != newHash {
            let newImageBlurred = image.applyDefaultEffect()?.optimizedImage()
            backgroundImage.tag = newHash
            DispatchQueue.main.async {
                UIView.transition(with: self.backgroundImage, duration: 5.8, options: [.transitionCrossDissolve], animations: {
                    self.backgroundImage.image = newImageBlurred
                }, completion:nil)
                
            }
        }
    }
}
