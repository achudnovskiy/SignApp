//
//  LocationTracker.swift
//  Sign
//
//  Created by Andrey on 2015-02-12.
//  Copyright (c) 2015 Simple Matters. All rights reserved.
//

import UIKit
import CoreLocation

let kCurrentLocationRadius:CLLocationDistance = 150
let kFirstLocationUpdateNotification = "LocationTracker_FirstUpdate"

open class LocationTracker: NSObject, CLLocationManagerDelegate {
    

    internal let locationManager:CLLocationManager
    internal let regionRadius:CLLocationDistance
    
    internal var allLocations:[SignObject]
    internal var currentLocation:CLLocation? {
        willSet(newCurrentLocation) {
            if currentLocation == nil && newCurrentLocation != nil {
                NotificationCenter.default.post(name: Notification.Name(rawValue: kFirstLocationUpdateNotification), object: nil)
            }
        }
    }
    internal var monitoredRegion:CLCircularRegion?
    
    internal var preciseMonitoring:Bool
    internal var closeLocations:[CLLocation]
    internal var lastHitRegion:SignObject?
    
    
    internal var completionHandler:((_ location:SignObject) -> Void)?
    
    //MARK:- Public API
    
    public init (radius:Double)
    {
        regionRadius = radius
        locationManager = CLLocationManager()
        allLocations = []
        closeLocations = []
        preciseMonitoring = true
        
        super.init()
    }
    
    open func startMonitoringForLocations(_ locationsToMonitor: [SignObject], completion:@escaping (_ location:SignObject) -> Void)
    {
        locationManager.delegate = self
        locationManager.distanceFilter = 2
        locationManager.desiredAccuracy = 5

        completionHandler = completion
        allLocations = locationsToMonitor
        CLLocationManager.authorizationStatus()
    }
    
    fileprivate func startTracking(_ currentAuthorizationStatus:CLAuthorizationStatus)
    {
        if permissionCheck(currentAuthorizationStatus) == false
        {
            locationManager.requestAlwaysAuthorization()
        }
        else
        {
            locationManager.startUpdatingLocation()
            locationManager.startMonitoringSignificantLocationChanges()
        }
    }
    
    //MARK:
    //MARK: internal API
    
    internal func permissionCheck(_ currentPermission:CLAuthorizationStatus) -> Bool
    {
        //CLLocationManager.authorizationStatus()
        switch (currentPermission)
        {
        case .authorizedWhenInUse: fallthrough
        case .denied: fallthrough
        case .restricted:
            NSLog("Not enough permissions")
            return false
        case .notDetermined:
            NSLog("Requesting authorization")
            return false
        case .authorizedAlways:
            return true
        }
    }
    
    open func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        startTracking(status)
    }
    
    internal func updatetLocationMonitoringState() -> Bool {
        if updateCurrentRegion() != nil {
            
            closeLocations = currentLocation!.findCloseLocationsFrom(locationSet: allLocations, within: kCurrentLocationRadius)
            
            if closeLocations.count != 0 {
                startPrecisionMonitoring()
            }
            else {
                stopPrecisionMonitoring()
            }
            return true
        }
        return false
    }
    
    internal func updateCurrentRegion() -> CLCircularRegion? {
        currentLocation = locationManager.location
        
        if monitoredRegion != nil {
            locationManager.monitoredRegions.first!
            locationManager.stopMonitoring(for: monitoredRegion!)
        }
        
        
        monitoredRegion = CLCircularRegion(center: currentLocation!.coordinate, radius: kCurrentLocationRadius, identifier: "Current Region")
        locationManager.startMonitoring(for: monitoredRegion!)

        return monitoredRegion
    }
    
    internal func startPrecisionMonitoring()
    {
        preciseMonitoring = true
        locationManager.startUpdatingLocation()
    }
    internal func stopPrecisionMonitoring()
    {
        if preciseMonitoring
        {
            preciseMonitoring = false
            locationManager.stopUpdatingLocation()
        }
    }
    
    internal func didHitRegion(_ currentLocation:CLLocation, closeRegions:[CLCircularRegion]) -> CLCircularRegion?
    {
        for region in closeRegions
        {
            if region.contains(currentLocation.coordinate)
            {
                return region
            }
        }
        
        return nil
    }

   internal func handleCloseProximity()
   {
        let regionHit = (currentLocation?.findCloseLocationsFrom(locationSet: allLocations, within: regionRadius) as! [SignObject]).first
    
        if regionHit != nil && regionHit?.locationId != lastHitRegion?.locationId
        {
            lastHitRegion = regionHit
            completionHandler!(regionHit!)
        }
    }
    
    var closestSign:SignObject?
    {
        get {
            if (currentLocation != nil) {
                
                let allUndiscovered = allLocations.filter { (location:SignObject) -> Bool in
                    return !location.isDiscovered
                }
                return getClosestSignFrom(locationSet: allUndiscovered, to: currentLocation!)
            }
            else {
                return nil
            }
        }
    }
    
    //MARK:- CLLocaitonManager Delegate protocol
    
    open func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion)
    {
        updatetLocationMonitoringState()
    }

    open func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion)
    {
        updatetLocationMonitoringState()
    }
    
    open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        let locationUpdate = locations.last!
        currentLocation = self.locationManager.location

        if self.preciseMonitoring
        {
            self.handleCloseProximity()
        }
        else
        {
            self.updateCurrentRegion()
        }
    }
    
    
    open func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
    }
    
    
    

    func findCloseSignsFrom(locationSet:[SignObject],to location:CLLocation, within radius:CLLocationDistance) -> [SignObject] {
        var result:[SignObject] = []
        
        for sign in locationSet {
            if sign.location.distance(from: location) < radius {
                result.append(sign)
            }
        }
        
        return result
    }
    
    func getClosestSignFrom(locationSet:[SignObject], to location:CLLocation) -> SignObject? {
        if locationSet.isEmpty{
            return nil
        }
        
        var closestSign:SignObject = locationSet.first as SignObject!
        for sign in locationSet {
            if closestSign.location.distance(from: location) > sign.location.distance(from: location) {
                closestSign = sign
            }
        }
        
        return closestSign
    }

}
