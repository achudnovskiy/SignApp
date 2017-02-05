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
let kRegionRadius:CLLocationDistance = 50
let kNotificationNotEnoughPermissions = "LocationTracker_NotEnoughPermissions"

open class LocationTracker: NSObject, CLLocationManagerDelegate {
    
    enum TrackerState {
        case ReadyToTrack
        case NeedConfiguration
        case NotReadyToTrack
    }

    internal let locationManager:CLLocationManager
    internal let regionRadius:CLLocationDistance = kRegionRadius
    
    internal var allLocations:[SignObject]
    internal var currentLocation:CLLocation?
    internal var currentRegion:CLCircularRegion?
    
    internal var monitoredRegions:[CLCircularRegion] = []
    
    internal var closeLocations:[CLLocation]
    
    internal var completionHandler:((_ location:SignObject) -> Void)?
    
    internal var closestSignRequestHandler:((_ closestSign:SignObject?) -> Void)?
//    internal var homeRegionRequestHandler:(() -> Void)?
    internal var shouldUpdateMonitoredRegions:Bool = false
    
    //MARK:- Public API
    
    override init ()
    {
        locationManager = CLLocationManager()
        allLocations = []
        closeLocations = []
        
        super.init()
    }
    
    open func startMonitoringForLocations(_ locationsToMonitor: [SignObject], completion:@escaping (_ location:SignObject) -> Void)
    {
        locationManager.delegate = self
//        locationManager.distanceFilter = 2
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters

        completionHandler = completion
        allLocations = locationsToMonitor
        prepareForTracking()
    }
    
    func prepareForTracking() {
        switch checkIfPermissionsAreSufficient(CLLocationManager.authorizationStatus()) {
        case .NeedConfiguration:
            locationManager.requestAlwaysAuthorization()
        case .NotReadyToTrack:
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kNotificationNotEnoughPermissions), object: nil)
        case .ReadyToTrack:
            startTracking()
        }
    }
    
    fileprivate func startTracking()
    {
        // find N close locations, start monigoring their regions
        if shouldUpdateCurrentLocation() {
            shouldUpdateMonitoredRegions = true
            locationManager.requestLocation()
        }
        else {
            updateHomeRegion()
            updateMonitoredRegions()
        }

    }

    
    func checkIfPermissionsAreSufficient(_ currentPermission:CLAuthorizationStatus) -> TrackerState
    {
        switch(currentPermission) {
        case .notDetermined:
            return .NeedConfiguration
        case .authorizedAlways:
            startTracking()
            return .ReadyToTrack
        case .authorizedWhenInUse, .denied, .restricted:
            return .NotReadyToTrack
        }
    }
    
    open func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        prepareForTracking()
    }
    


//    internal func getCurrentRegion() -> CLCircularRegion? {
//        currentLocation = locationManager.location
//        
//        if currentRegion != nil {
//            locationManager.monitoredRegions.first!
//            locationManager.stopMonitoring(for: currentRegion!)
//        }
//        
//        
//        currentRegion = CLCircularRegion(center: currentLocation!.coordinate, radius: kCurrentLocationRadius, identifier: "Current Region")
//        locationManager.startMonitoring(for: currentRegion!)
//
//        return currentRegion
//    }
    
    
    func shouldUpdateCurrentLocation() -> Bool {
        let minuteAgo = Date().addingTimeInterval(TimeInterval(-60))
        if currentLocation == nil || currentLocation!.timestamp < minuteAgo {
            return true
        }
        return false
    }
    func getClosestSign(with completioHandler:@escaping (_ location:SignObject?) -> Void) {
        if shouldUpdateCurrentLocation() {
            closestSignRequestHandler = completioHandler
            locationManager.requestLocation()
        }
        else {
            let closest = getClosestSign()
            completioHandler(closest)
        }
    }

    //MARK:- CLLocaitonManager Delegate protocol
    
    open func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion)
    {
        // if we deal with the currentRegion - update
        // if we deal with sign region - notify
    }

    open func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion)
    {
        // if we deal with the currentRegion - update
        // if we deal with sign region - notify
    }
    func getClosestSign() -> SignObject? {
        let allUndiscovered = allLocations.filter { (location:SignObject) -> Bool in
            return !location.isDiscovered
        }
        
        return getClosestSignFrom(locationSet: allUndiscovered, to: currentLocation!)
    }
    
    func updateMonitoredRegions() {
        
        let signsToMonitor = self.findCloseSignsFrom(locationSet: self.allLocations, to: self.currentLocation!, within: kCurrentLocationRadius)
        
        signsToMonitor.forEach({ (sign) in
            let region = sign.regionForLocation(with: kRegionRadius)
            //TODO: maintain a low number of monitored regions, cleanup old ones
            self.locationManager.startMonitoring(for: region)
        })
        

    }
    func updateHomeRegion() {
        if currentRegion != nil {
            locationManager.stopMonitoring(for: currentRegion!)
        }
        
        if currentLocation != nil {
            currentRegion = CLCircularRegion(center: currentLocation!.coordinate, radius: kCurrentLocationRadius, identifier: "CurrentRegion")
            locationManager.startMonitoring(for: currentRegion!)
        }
    }

    open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = manager.location
        if closestSignRequestHandler != nil {
            let closest = getClosestSign()
            closestSignRequestHandler!(closest)
            closestSignRequestHandler = nil
        }
        
        if shouldUpdateMonitoredRegions {
            updateMonitoredRegions()
            updateHomeRegion()
            shouldUpdateMonitoredRegions = false
        }
    }
    
    
    open func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        //TODO: notify UI about a problem
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
