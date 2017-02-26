//
//  MainViewController.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-01-14.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit

let cardCollectionViewItemIdentifier = "Card"
let kCollectionItemSize = CGSize(width: 180, height: 320)
let kCollectionItemSpacing:CGFloat = 40
let kCollectionItemThumbnailInset:CGFloat = 40


enum SignAppState {
    case ThumbnailView
    case FullscreenView
    case MapView
}

extension UICollectionViewFlowLayout {
    open override func copy() -> Any {
        let copy = UICollectionViewFlowLayout()
        copy.estimatedItemSize = self.estimatedItemSize
        copy.footerReferenceSize = self.footerReferenceSize
        copy.headerReferenceSize = self.headerReferenceSize
        copy.itemSize = self.itemSize
        copy.minimumInteritemSpacing = self.minimumInteritemSpacing
        copy.minimumLineSpacing = self.minimumLineSpacing
        copy.scrollDirection = self.scrollDirection
        copy.sectionFootersPinToVisibleBounds = self.sectionFootersPinToVisibleBounds
        copy.sectionHeadersPinToVisibleBounds = self.sectionHeadersPinToVisibleBounds
        copy.sectionInset = self.sectionInset
        
        return copy
    }
}


class MainViewController: UIViewController, UICollectionViewDelegate, UIScrollViewDelegate, UICollectionViewDataSource {

    //MARK: Outlets
    
    @IBOutlet weak var signCollectionView: UICollectionView!
    @IBOutlet weak var collectionLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var mapContainerView: UIView!
    
    @IBOutlet weak var mapButtonView: UIView!
    @IBOutlet weak var stateButtonView: UIView!
    @IBOutlet weak var stateButtonLabel: UILabel!
    
    @IBOutlet weak var cnstrStateButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var cnstrMapButtonWidth: NSLayoutConstraint!
    
    
    //MARK: Properties
    var isFullscreen:Bool {
        get {
            return currentState == .FullscreenView
        }
    }
    var mapViewController:MapViewController!
    
    var delayedTransition = false
    
    var currentState:SignAppState = .ThumbnailView

    var collectionSigns:[SignObject] = []
    var collectionNewItems:[SignObject] = []
    var discoverySign:SignObject?
    
    func prepareDataSource() {
        collectionSigns = SignDataSource.sharedInstance.collectedSignsOrdered
        collectionNewItems = SignDataSource.sharedInstance.newSigns
        LocationTracker.sharedInstance.getClosestSign(with: { (sign) in
            if sign != nil {
                self.discoverySign = SignDataSource.sharedInstance.findSignObjById(objectId: sign!.objectId)
                if self.discoverySign != nil {
                    self.signCollectionView.performBatchUpdates({
                        self.collectionSigns = [self.discoverySign!] + self.collectionSigns
                        self.signCollectionView.performBatchUpdates({
                            self.signCollectionView.insertItems(at: [IndexPath(item: 0, section: 0)])
                        }, completion: nil)

                    }, completion: nil)
                }
            }
        })
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareDataSource()
        
        stateButtonView.applyPlainShadow()
        mapButtonView.applyPlainShadow()
        
        currentState = .ThumbnailView
        updateStateButton(animated: false)
        mapContainerView.isHidden = true
        
        if collectionSigns.count != 0 {
            backgroundImage.image = collectionSigns.first?.image.applyDefaultEffect()
        }
        else {
            let path = Bundle.main.path(forResource: "DefaultBackgroundImage", ofType: "png", inDirectory: "Content")!
            backgroundImage.image = UIImage(contentsOfFile: path)!.applyDefaultEffect()
        }
        
        signCollectionView.backgroundColor = UIColor.clear
        
        setCollectionViewProperties(isFullscreen: false)
        
        mapContainerView.isHidden = true
        
    
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue:"ReloadData"), object: nil, queue: OperationQueue.main) { (notification) in
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
        if newState == .FullscreenView || newState == .ThumbnailView {
            self.view.isUserInteractionEnabled = false
            let toFullscreen = newState == .FullscreenView
            let newSize = collectionItemSize(isFullscreen: toFullscreen)
            let cellView = signInFocus!
            
            let newLayout = getCollectionViewLayout(isFullscreen: toFullscreen)
            newLayout.minimumLineSpacing = newLayout.minimumLineSpacing * 5
            cellView.prepareViewForAnimation(toFullscreen: toFullscreen)
            
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [], animations: {
                cellView.setViewSizeForAnimation(newSize: newSize)
                cellView.setComponentsForAnimation(toFullscreen: toFullscreen)
                cellView.layoutIfNeeded()
            }) { (Bool) in
                cellView.prepareViewAfterAnimation(toFullscreen: toFullscreen)
                
                self.currentState = newState
                self.signCollectionView.setCollectionViewLayout(newLayout, animated: false, completion: { (finished) in
                    if finished {
                        
                        if toFullscreen == false {
                            let finalNewLayout = self.getCollectionViewLayout(isFullscreen: toFullscreen)
                            self.signCollectionView.setCollectionViewLayout(finalNewLayout, animated: true, completion:{(finished) in
                                if finished {
                                    self.collectionLayout = finalNewLayout
                                    cellView.layer.zPosition = 0
                                    self.view.isUserInteractionEnabled = true
                                }
                            })
                        }
                        else {
                            self.collectionLayout = newLayout
                            self.view.isUserInteractionEnabled = true
                        }
                    }
                })

                self.updateStateButton(animated: true)
            }
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionSigns.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cardCollectionViewItemIdentifier, for: indexPath) as! SignCard
        let signToShow = collectionSigns[indexPath.row]
        
        cell.backgroundImage.image = signToShow.image
        cell.keywordLabel.text = signToShow.thumbnailText.uppercased()
        cell.contentImage.image = signToShow.infographic
        cell.prepareViewForMode(viewMode: signToShow.viewMode, isFullscreenView: isFullscreen)
        cell.layoutIfNeeded()
        
        return cell
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
            scheduleUpdateBackgroundForItemAtImdex(index: index)
        }
        if delayedTransition {
            delayedTransition = false
            if currentState == .FullscreenView {
                transitionCollectionView(newState: .ThumbnailView)
            }
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let itemWidth = collectionLayout.itemSize.width
        let itemSpacing = collectionLayout.minimumLineSpacing
        
        let index = Int(ceil((targetContentOffset.pointee.x) / (itemWidth + itemSpacing)))
        
        if isFullscreen && collectionSigns[index].isDiscovered == false {
            delayedTransition = true
        } else {
            targetContentOffset.pointee = CGPoint( x: CGFloat(index)  * (itemWidth + itemSpacing) ,y: 0)
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
    
    func collectionItemSize(isFullscreen:Bool) -> CGSize{
        if isFullscreen {
            return signCollectionView.bounds.size
        }
        else {
            return kCollectionItemSize
        }
    }
    
    var isCollectionViewFullscreen:Bool {
        get {
            return collectionLayout.itemSize == view.bounds.size
        }
    }
    
    func getCollectionViewLayout(isFullscreen:Bool) -> UICollectionViewFlowLayout {

        let newLayout = collectionLayout.copy() as! UICollectionViewFlowLayout
        if isFullscreen {
            newLayout.itemSize = signCollectionView.bounds.size
            newLayout.minimumLineSpacing = 0
            newLayout.sectionInset = UIEdgeInsets();
        }
        else {
            newLayout.itemSize = kCollectionItemSize
            newLayout.minimumLineSpacing = kCollectionItemSpacing
            let sideInset = signCollectionView.bounds.size.width / 2 - newLayout.itemSize.width / 2
            newLayout.sectionInset = UIEdgeInsets(top: kCollectionItemThumbnailInset, left: sideInset, bottom: kCollectionItemThumbnailInset, right: sideInset)
        }
        return newLayout
    }
    
    func setCollectionViewProperties(isFullscreen:Bool) {
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
            collectionLayout.sectionInset = UIEdgeInsets(top: kCollectionItemThumbnailInset, left: sideInset, bottom: kCollectionItemThumbnailInset, right: sideInset)
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
    
    func updateMapButton(hide:Bool, animated:Bool) {
        if animated
        {
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
        else
        {
            self.mapButtonView.isHidden = hide
        }
    }
    
    func updateStateButton(animated:Bool) {
        let buttonText = stateButtonTextForState(state: currentState)
        if buttonText == stateButtonLabel.text {
            return
        }
        
        let hideButton = buttonText.characters.count == 0
        
        if !hideButton
        {
            let attrString = NSAttributedString(string: buttonText, attributes: [NSFontAttributeName:self.stateButtonLabel.font])
            self.cnstrStateButtonWidth.constant = ceil(attrString.size().width + 14)
            self.stateButtonView.isHidden = false
        }
        else
        {
            self.cnstrStateButtonWidth.constant = 0
        }
        
        if animated
        {
            self.stateButtonView.isUserInteractionEnabled = false
            UIView.animate(withDuration: 0.1, animations: {
                self.stateButtonLabel.alpha = 0
            }, completion: {(Bool) in
                self.stateButtonLabel.text = buttonText
            })
            UIView.animate(withDuration: 0.25, delay: 0.05, usingSpringWithDamping: 0.85, initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: {
                self.stateButtonLabel.alpha = 1
                self.view.layoutIfNeeded()
            }, completion: {(Bool) in
                self.stateButtonView.isUserInteractionEnabled = true
                self.stateButtonView.isHidden = hideButton
            })
        }
        else
        {
            self.stateButtonLabel.text = buttonText
            self.stateButtonView.isHidden = hideButton
            self.view.layoutIfNeeded()
        }
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
                self.updateMapButton(hide: false, animated: true)
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
            self.updateStateButton(animated: true)
            self.updateMapButton(hide: true, animated: true)
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
    func scheduleUpdateBackgroundForItemAtImdex(index:IndexPath) {
        let nextSignID = collectionSigns[index.row].objectId
        let dispatchTime: DispatchTime = DispatchTime.now() + Double(Int64(2.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.global(qos: .background).asyncAfter(deadline: dispatchTime, execute: {
            let newIndex = self.indexForItemInFocus
            if newIndex == nil {
                return
            }
            
            let actualNextSign = self.collectionSigns[newIndex!.row]
            if nextSignID == actualNextSign.objectId
            {
                self.updateBackgroundBlurWithImage(image: actualNextSign.image, imageTag: actualNextSign.objectId)
            }
        })
    }

    
    func updateBackgroundBlurWithImage(image:UIImage, imageTag:String) {
        let newHash = imageTag.hash
        if backgroundImage.tag != newHash {
            let newImageBlurred = image.applyDefaultEffect()
            backgroundImage.tag = newHash
            DispatchQueue.main.async {
                UIView.transition(with: self.backgroundImage, duration: 0.8, options: .transitionCrossDissolve, animations: {
                    self.backgroundImage.image = newImageBlurred
                }, completion:nil)
            }
        }
    }
}
