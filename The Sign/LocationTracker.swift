//
//  LocationTracker.swift
//  Sign
//
//  Created by Andrey on 2015-02-12.
//  Copyright (c) 2015 Simple Matters. All rights reserved.
//

import UIKit
import CoreLocation

let kCurrentLocationRadius:CLLocationDistance = 50
let kCloseSignRadius:CLLocationDistance = 500
let kRegionRadius:CLLocationDistance = 25
let kNotificationNotEnoughPermissions = "LocationTracker_NotEnoughPermissions"

protocol LocationTrackerDelegate {
    func didHitLocation(location:SignLocation)
    func didFailWithError(error:String)
}

open class LocationTracker: NSObject, CLLocationManagerDelegate {

    static var sharedInstance:LocationTracker = LocationTracker()

    internal let locationManager:CLLocationManager
    internal let regionRadius:CLLocationDistance = kRegionRadius
    
    internal var allLocations:[SignLocation]
    internal var currentLocation:CLLocation?
    internal var currentRegion:CLCircularRegion?
    internal var monitoredRegions:[CLCircularRegion] = []
    internal var permissionRequestHandler:((_ granted:Bool) -> Void)?
    internal var shouldUpdateMonitoredRegions:Bool = false
    internal var delegate:LocationTrackerDelegate?
    
    //MARK:- Public API
    
    override init ()
    {
        locationManager = CLLocationManager()
        locationManager.distanceFilter = 5
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters

        allLocations = []
        
        super.init()
    }
    
    func prepareForMonitoring(delegate:LocationTrackerDelegate?, startMonitoring:Bool)
    {
        self.delegate = delegate
        locationManager.delegate = self
        allLocations = SignDataSource.sharedInstance.locations
        NotificationCenter.default.addObserver(forName: kNotificationReloadData,
                                               object: nil,
                                               queue: OperationQueue.main) {
                                                (notification) in
            self.allLocations = SignDataSource.sharedInstance.locations
            guard self.currentLocation != nil else { return }
            self.discoverLocationIfNeeded(location: self.currentLocation!)
        }
        if startMonitoring {
            self.startTracking()
        }
    }
    
    
    func requestPermission(completion:@escaping (_ granted:Bool) -> Void) {
        self.permissionRequestHandler = completion
        locationManager.requestAlwaysAuthorization()
    }
    
    fileprivate func startTracking()
    {
        // find N close locations, start monigoring their regions
        if shouldUpdateCurrentLocation(current: self.currentLocation) {
            shouldUpdateMonitoredRegions = true
            locationManager.startUpdatingLocation()
        }
        else {
            updateMonitoredRegionsIfNeeded(location: self.currentLocation!)
        }
    }

    
    func permittedByUser() -> Bool {
        let currentPermission = CLLocationManager.authorizationStatus()
        switch(currentPermission) {
        case .notDetermined:
            return false
        case .authorizedAlways:
            return true
        case .authorizedWhenInUse, .denied, .restricted:
            return false
        }
    }

    open func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if self.permissionRequestHandler != nil {
            self.permissionRequestHandler!(permittedByUser())
            self.permissionRequestHandler = nil
        }
        startTracking()
    }

    func shouldUpdateCurrentLocation(current:CLLocation?) -> Bool {
        let minuteAgo = Date().addingTimeInterval(TimeInterval(-60))
        if current == nil || current!.timestamp < minuteAgo {
            return true
        }
        return false
    }
    
    func notifyAboutSignNearby(sign:SignLocation, distanceInSteps:Int) {
        NotificationCenter.default.post(name: kNotificationSignNearby,
                                        object: nil,
                                        userInfo: [ kNotificationSignNearbyId: sign.objectId,
                                                   kNotificationSignNearbyDistance: distanceInSteps ])
    }
    
    //MARK:- CLLocaitonManager Delegate protocol
    
    open func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion)
    {
        if manager.location!.horizontalAccuracy > kCLLocationAccuracyNearestTenMeters {
            return
        }
        if region.identifier == "CurrentRegion" {
            shouldUpdateMonitoredRegions = true
            locationManager.startUpdatingLocation()
        }
        else {
            guard let hit = allLocations.first(where: { (sign) -> Bool in
                return sign.objectId == region.identifier
            }) else {return}
            self.delegate?.didHitLocation(location: hit)
        }
    }

    open func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion)
    {
        if manager.location!.horizontalAccuracy > kCLLocationAccuracyNearestTenMeters {
            return
        }
        shouldUpdateMonitoredRegions = true
        locationManager.startUpdatingLocation()
    }
    
    func getClosestSign(location:CLLocation?, from locationSet:[SignLocation]) -> SignLocation? {
        let allUndiscovered = locationSet.filter { (location:SignLocation) -> Bool in
            return !location.isCollected
        }
        
        return getClosestSignFrom(locationSet: allUndiscovered, to: location)
    }
    
    func updateMonitoredRegionsIfNeeded(location:CLLocation) {
        if location.horizontalAccuracy<20 && shouldUpdateMonitoredRegions {
            updateHomeRegion(location: location)
            updateSignRegions(location: location)
            shouldUpdateMonitoredRegions = false
        }
    }
    
    func updateSignRegions(location:CLLocation) {
        let signsToMonitor = self.findCloseSignsFrom(locationSet: self.allLocations, to: location, within: kCloseSignRadius)

        signsToMonitor.forEach({ (sign) in
            let region = sign.regionWithRadius(radius: kRegionRadius)
            //TODO: maintain a low number of monitored regions, cleanup old ones
            self.locationManager.startMonitoring(for: region)
        })
        

    }
    func updateHomeRegion(location:CLLocation) {
        if currentRegion != nil {
            locationManager.stopMonitoring(for: currentRegion!)
        }
        if currentLocation != nil {
            currentRegion = CLCircularRegion(center: currentLocation!.coordinate, radius: kCurrentLocationRadius, identifier: "CurrentRegion")
            locationManager.startMonitoring(for: currentRegion!)
        }
    }
    
    func processDeferredLocationUpdates(locations:[CLLocation]) {
        //TODO: process delayed location updates for sign discoveries
    }
    
    open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count > 1 {
            let defferredLocatonUpadtes = locations[0...locations.count-1].filter({ (location) -> Bool in
                return location.horizontalAccuracy<=20
            })
            self.processDeferredLocationUpdates(locations: Array(defferredLocatonUpadtes))
        }
        
        guard let newCurrentLocation = locations.last else { return }
        
        discoverLocationIfNeeded(location: newCurrentLocation)
        updateMonitoredRegionsIfNeeded(location: newCurrentLocation)
        currentLocation = newCurrentLocation
    }
    
    func discoverLocationIfNeeded(location: CLLocation) {
        if location.horizontalAccuracy <= currentMinDistanceToDiscoverySign {
            if let closest = getClosestSign(location: location, from: self.allLocations) {
                self.bumbDistanceToDiscoverySign()
                let distance = self.distanceInStepsFromLocation(signLocation: closest)
                self.notifyAboutSignNearby(sign: closest, distanceInSteps: distance)
            }
        }
    }


    
    
    open func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Something failed \(error)")
        //TODO: notify UI about a problem
    }

    func findCloseSignsFrom(locationSet:[SignLocation],to location:CLLocation, within radius:CLLocationDistance) -> [SignLocation] {
        var result:[SignLocation] = []
        
        for sign in locationSet {
            if sign.location.distance(from: location) < radius {
                result.append(sign)
            }
        }
        
        return result
    }
    
    func getClosestSignFrom(locationSet:[SignLocation], to location:CLLocation?) -> SignLocation? {
        if location == nil || locationSet.isEmpty{
            return nil
        }
        
        var closestSign:SignLocation = locationSet.first as SignLocation!
        for sign in locationSet {
            if closestSign.location.distance(from: location!) > sign.location.distance(from: location!) {
                closestSign = sign
            }
        }
        
        return closestSign
    }
    
    func distanceInStepsFromLocation(signLocation:SignLocation)->Int {
        let meterToStepRatio = 1.3123
        let distance = self.locationManager.location!.distance(from: signLocation.location)
        return Int(distance * meterToStepRatio)
    }
    
    var currentMinDistanceToDiscoverySign: CLLocationDistance = Double.infinity
    
    
    func bumbDistanceToDiscoverySign() {
        if currentMinDistanceToDiscoverySign == Double.infinity {
            currentMinDistanceToDiscoverySign = 100
        } else if currentMinDistanceToDiscoverySign >= 20 {
            currentMinDistanceToDiscoverySign -= 10
        }
    }
}
