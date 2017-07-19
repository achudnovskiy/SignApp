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

enum ExtraSignType {
    case Discovery
    case Problem
    case StayTuned
    case Loading
}

protocol SignShareProtocol {
    func updateShareProgress(progress:CGFloat, didPassThreshold:Bool)
    func resetShareProgress()
    func didShareSignCard(signCard:SignCard)
}


extension UICollectionView {
    var indexPathForLastRow:IndexPath {
        let lastSection = numberOfSections - 1
        let lastRow = numberOfItems(inSection: lastSection) > 0 ? numberOfItems(inSection: lastSection) - 1 : 0
        return IndexPath(row: lastRow, section: lastSection)
    }
    var numberOfItems:Int {
        return self.numberOfItems(inSection: 0)
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
    
    @IBOutlet weak var cnstrMapButtonLeading: NSLayoutConstraint!
    @IBOutlet weak var cnstrMapButtonWidth: NSLayoutConstraint!
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    //MARK: Properties
    
    let discoveryQueue = DispatchQueue(label: "thesign.discoveryQueue")
    var mapViewController:MapViewController!
    
    var delayedTransition = false
    var discoverySign:SignObject?
    var currentState:SignAppState = .ThumbnailView
    var currentExtraSignType:ExtraSignType = .Loading

    var cachedImages = NSCache<NSString,UIImage>()
    
    func prepareConstraints() {
        
        DimensionGenerator.current.phoneSizeRatio = view.bounds.width / 320
        self.cnstrMapButtonWidth.constant = DimensionGenerator.current.mapButtonWidth
    }
    
    var collectionSigns:[SignObject] = []
    
    var collectionNewItemsCount:Int {
        return SignDataSource.sharedInstance.newSignsCount
    }
    
    //TODO: REVIEW
    func prepareDataSource() {
        
        collectionSigns = SignDataSource.sharedInstance.collectedSignsOrdered
        if collectionSigns.count != 0 && SignDataSource.sharedInstance.isEverythingCollected {
            currentExtraSignType = .StayTuned
        }
        
        if collectionSigns.count == 0
        {
            return
        }
        
        //load cache for first three signs
        let cacheCount = collectionSigns.count < 3 ? collectionSigns.count : 3
        for i in 0...cacheCount - 1 {
            let sign = collectionSigns[i]
            cachedImages.setObject(sign.proccessImage(), forKey: sign.uniqueId)
        }
    }

    
    //MARK: - UIViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareConstraints()
        prepareDataSource()
        observerNotifications()
        adjustFont()
        
        stateButtonView.applyPlainShadow()
        mapButtonView.applyPlainShadow()
        setCollectionLayoutProperties(collectionLayout: signCollectionLayout, isFullscreen: false)
        signCollectionView.backgroundColor = UIColor.clear
        
        updateStateButton()
        
        if collectionSigns.count != 0 {
            backgroundImage.image = collectionSigns.first?.image.applyDefaultEffect()?.optimizedImage()
        }
        else {
            backgroundImage.image = UIImage(named: "DefaultBackgroundImage")?.applyDefaultEffect()?.optimizedImage()
        }
        self.view.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showIntroViewIfNeeded()
    }
    
    func showIntroViewIfNeeded() {
        if UserDefaults.standard.object(forKey: "firstLaunch") == nil {
            let introVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "introScreen")
            
            self.present(introVC, animated: true, completion: {
                UserDefaults.standard.set(true, forKey: "firstLaunch")
            })
        }
    }
    
    func adjustFont() {
        self.stateButtonLabel.font = UIFont(descriptor: stateButtonLabel.font.fontDescriptor, size: DimensionGenerator.current.stateButtonFontSize)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        cachedImages.removeAllObjects()
    }
    
    
    // MARK: - Local notifications
    func observerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(processSignOpenNotification(_:)), name: kNotificationScrollToSign, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(processSignReloadNotification(_:)), name: kNotificationReloadData, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(processSignDicoveryNotification(_:)), name: kNotificationSignNearby, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(processErrorStateNotification(_:)), name: kNotificationErrorState, object: nil)
    }
    
    func processSignOpenNotification(_ notification:Notification) {
        let signId = notification.userInfo![kNotificationScrollToSignId] as! String
        guard let sign = SignDataSource.sharedInstance.findSignObjById(objectId: signId) else { return }
        
        guard let index = self.indexForSign(sign: sign) else { return }
        self.delayedTransition = true
        DispatchQueue.main.async {
            self.signCollectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: true)
        }
    }
    
    func processSignReloadNotification(_ notification:Notification) {
        DispatchQueue.main.async {
            //TODO: do something smarter than nuking the cache
            self.cachedImages.removeAllObjects()
            let pastLastIndex = self.signCollectionView.indexPathForLastRow
            self.collectionSigns = SignDataSource.sharedInstance.collectedSignsOrdered
            self.signCollectionView.reloadData()
            self.signCollectionView.reloadItems(at: [pastLastIndex])
        }
    }
        
    func processSignDicoveryNotification(_ notification:Notification) {
        discoveryQueue.async {
            guard
                let signId = notification.userInfo?[kNotificationSignNearbyId] as? String,
                let distanceInSteps = notification.userInfo?[kNotificationSignNearbyDistance] as? Int,
                let newDiscoverySign = SignDataSource.sharedInstance.findSignObjById(objectId: signId)  else { return }
            
            newDiscoverySign.distance = distanceInSteps
            

            if self.discoverySign != newDiscoverySign ||  self.discoverySign?.distance != distanceInSteps {
                self.discoverySign = newDiscoverySign
                self.currentExtraSignType = .Discovery
                DispatchQueue.main.async {
                    self.updateStateButton()
                    self.signCollectionView.reloadItems(at: [self.signCollectionView.indexPathForLastRow])
                }
            }
        }
    }
    
    func processErrorStateNotification(_ notification:Notification) {
    
    }
    
    // MARK: - UI Animations
    func transitionCollectionView(newState:SignAppState) {
        if newState != .FullscreenView && newState != .ThumbnailView {
            return
        }
        self.view.isUserInteractionEnabled = false
        let toFullscreen = newState == .FullscreenView
        let newSize = toFullscreen ? signCollectionView.bounds.size : DimensionGenerator.current.collectionItemSize;
        
        let cellId = indexForItemInFocus!
        let signInTransition = collectionSigns[cellId.row]
        let cellView = signInFocus!
        
        resetZPosition()
    
        signCollectionView.isScrollEnabled = !toFullscreen
        cellView.prepareViewForAnimation(toFullscreen: toFullscreen)
        self.processSignDiscovery(sign: signInTransition, signCard: cellView)
    
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [], animations: {
            cellView.setViewSizeForAnimation(newSize: newSize, toFullscreen: toFullscreen)
            cellView.layoutIfNeeded()
        }) { (Bool) in
            cellView.prepareViewAfterAnimation(toFullscreen: toFullscreen)
            
            self.currentState = newState
            self.view.isUserInteractionEnabled = true
            self.updateStateButton()
        }
    }
    
    func processSignDiscovery(sign:SignObject, signCard:SignCard) {
        if cachedImages.object(forKey: sign.uniqueId) != nil {
            cachedImages.removeObject(forKey: sign.uniqueId)
        }
        SignDataSource.sharedInstance.discoverSignWith(sign.objectId)
        sign.isDiscovered = true
        signCard.viewMode = .Discovered
        signCard.keywordLabel.text = sign.thumbnailText.uppercased()
    }
    
    func resetZPosition() {
        self.signCollectionView.visibleCells.forEach { (cell) in
            cell.layer.zPosition = 0
        }
    }
    
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionSigns.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Card", for: indexPath) as! SignCard
        
        if indexPath != collectionView.indexPathForLastRow {
            let signToShow = collectionSigns[indexPath.row]
            
            //TODO: remove later
            if signToShow.isCollected == false {
                return cell
            }
            
            if signToShow.isDiscovered {
                cell.shareDelegate = self
                cell.prepareViewForMode(viewMode: .Discovered, isFullscreenView: false)
            }
            else {
                cell.prepareViewForMode(viewMode: .NotDiscovered, isFullscreenView: false)
            }
            
            cell.keywordLabel.text = signToShow.thumbnailText.uppercased()
            cell.contentLabel.text = signToShow.content.uppercased()
            cell.locationLabel.text = signToShow.locationName.uppercased()
            cell.wrapperView.image = cachedImageForSign(signToCache: signToShow)
            
        }
        else {
            let cellText = self.extraSignText()
            cell.prepareForExtraSign(extraType: currentExtraSignType, topText: cellText["top"]!, bottomText: cellText["bottom"]!)
            cell.startLogoAnimatoin()
        }
        
        
        cell.prepareGestureRecognition()
        signCollectionView.panGestureRecognizer.require(toFail: cell.panGesture!)
        cell.prepareBlur()
        cell.layoutIfNeeded()
        self.updateCardBlur(card: cell)
        
        return cell
    }
    
    func cachedImageForSign(signToCache:SignObject) -> UIImage {
        var cachedImage = cachedImages.object(forKey: signToCache.uniqueId)
        if cachedImage == nil {
            cachedImage = signToCache.proccessImage()
            cachedImages.setObject(cachedImage!, forKey: signToCache.uniqueId)
        }
        return cachedImage!
    }
    
    func extraSignText()->[String:String] {
        switch currentExtraSignType {
        case .Discovery:
            return ["top":"steps to new sign:",
                    "bottom":"\(discoverySign!.distance)"]
        case .Loading:
            return ["top":"Looking for a sign",
                    "bottom":"Might take a moment"]
        case .Problem:
            return ["top":"Something's wrong",
                    "bottom":"Can't load the signs"]
        case .StayTuned:
            return ["top":"all signs collected",
                    "bottom":"more to come soon"]
        }
    
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
        if currentState == .ThumbnailView && indexPath != signCollectionView.indexPathForLastRow && collectionSigns[indexPath.row].isCollected {
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
            (self.signCollectionView.cellForItem(at: indexPath) as! SignCard).shareDelegate = self
        }
        transitionCollectionView(newState: .FullscreenView)
    }
    
    
    // MARK: - ScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCardBlur()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if delayedTransition {
            delayedTransition = false
            if currentState == .ThumbnailView {
                if let index = indexForItemInFocus {
                    DispatchQueue.main.async {
                        self.openThumbnailSignAt(indexPath: index)
                        
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                        
                    })
                }
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let index = indexForItemInFocus {
            scheduleUpdateBackgroundForItemAtImdex(index: index.row)
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
    
    func indexForSign(sign:SignObject) -> IndexPath? {
        guard let index = collectionSigns.index(of: sign) else {
            return nil
        }
        return IndexPath(item: index, section: 0)
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
            collectionLayout.itemSize = DimensionGenerator.current.collectionItemSize
            collectionLayout.minimumLineSpacing = DimensionGenerator.current.collectionItemSpacing
            let sideInset:CGFloat = self.view.bounds.size.width / 2 - collectionLayout.itemSize.width / 2
            collectionLayout.sectionInset = UIEdgeInsets(top: DimensionGenerator.current.collectionItemThumbnailInset + DimensionGenerator.current.collectionItemThumbnailOffset, left: sideInset, bottom: DimensionGenerator.current.collectionItemThumbnailInset, right: sideInset)
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
            let newSigns = collectionNewItemsCount
            if newSigns == 0 && self.discoverySign == nil {
                return "Collected signs"
            } else {
                if newSigns == 0 {
                    return "What's New"
                }
                else {
                    return "What's New (\(newSigns))"
                }
            }
        case .MapView:
            return "Return to signs"
        }
    }
    
    func updateMapButton(hide:Bool) {
        self.mapButtonView.isUserInteractionEnabled = false
        
        if hide {
            self.cnstrMapButtonLeading.constant = -100
                //(-1)*self.mapButtonView.bounds.width
        }
        else {
            self.mapButtonView.isHidden = false
            self.cnstrMapButtonLeading.constant = 0
        }
        
        UIView.animate(withDuration: 0.25, delay: 0.05, usingSpringWithDamping: 0.85, initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: {
            self.mapButtonView.subviews.first?.alpha = hide ? 0 : 1
            self.mapButtonView.layoutIfNeeded()
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
            if collectionNewItemsCount != 0 {
                signCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: true)
            }
        case .MapView:
            mapViewController.animateDissappearance {
                self.mapViewController.clearMapView()
                self.mapContainerView.isHidden = true
                self.currentState = self.isCollectionViewFullscreen ? .FullscreenView : .ThumbnailView
                self.updateStateButton()
                self.updateMapButton(hide: false)
            }
        }        
    }
    
    @IBAction func mapButtonAction(_ sender: Any) {
        
        if indexForItemInFocus == signCollectionView.indexPathForLastRow && currentExtraSignType == .Discovery && self.discoverySign != nil {
            mapViewController.prepareMapViewToShow(locations: [self.discoverySign!])
        }
        else if currentState == .FullscreenView {
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
        DispatchQueue.main.asyncAfter(deadline: dispatchTime) {
            if self.signCollectionView.isDecelerating || self.signCollectionView.isDragging {
                self.scheduleUpdateBackgroundForItemAtImdex(index: index)
                return
            }
            
            if index == self.signCollectionView.indexPathForLastRow.row {
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
        }
    }
    
    func updateBackgroundBlurWithImage(image:UIImage, imageTag:String) {
        let newHash = imageTag.hash
        if backgroundImage.tag != newHash {
            let newImageBlurred = image.applyDefaultEffect()?.optimizedImage()
            backgroundImage.tag = newHash
                UIView.transition(with: self.backgroundImage, duration: 2, options: [.transitionCrossDissolve], animations: {
                    self.backgroundImage.image = newImageBlurred
                }, completion:nil)
        }
    }
    
    func updateCardBlur() {
        let center = signCollectionView.contentOffset.x + signCollectionView.bounds.width / 2
        signCollectionView.visibleCells.forEach { (cell) in
            let card = (cell as! SignCard)
            let ratio = 1 - abs((cell.center.x - center) / self.signCollectionView.bounds.width / 5)
            card.animator.fractionComplete = ratio
        }
    }
    
    func updateCardBlur(card:SignCard) {
        let center = signCollectionView.contentOffset.x + signCollectionView.bounds.width / 2
        let ratio = 1 - abs((card.center.x - center) / self.signCollectionView.bounds.width / 5)
        card.animator.fractionComplete = ratio
    }
    //TESTING
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    var motionCount = 3
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            if motionCount > 0 {
                motionCount -= 1
                return
            }
            var discoverCount = 3
            for sign in SignDataSource.sharedInstance.uncollectedSigns {
                if discoverCount > 0 {
                    _ = SignDataSource.sharedInstance.collectSignWithId(sign.objectId)
                    discoverCount -= 1
                }
            }
        }
    }
}
