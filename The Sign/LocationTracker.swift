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

open class LocationTracker: NSObject, CLLocationManagerDelegate {

    static var sharedInstance:LocationTracker = LocationTracker()
    enum TrackerState {
        case ReadyToTrack
        case NeedConfiguration
        case NotReadyToTrack
    }

    internal let locationManager:CLLocationManager
    internal let regionRadius:CLLocationDistance = kRegionRadius
    
    internal var allLocations:[SignLocation]
    internal var currentLocation:CLLocation?
    internal var currentRegion:CLCircularRegion?
    
    internal var monitoredRegions:[CLCircularRegion] = []
    
    internal var detectionHandler:((_ location:SignLocation) -> Void)!
    
//    internal var closestSignRequestHandler:((_ closestSign:SignLocation?) -> Void)?
    internal var shouldUpdateMonitoredRegions:Bool = false
    
    //MARK:- Public API
    
    override init ()
    {
        locationManager = CLLocationManager()
        allLocations = []
        
        super.init()
    }
    
    open func startMonitoringForLocations(_ locationsToMonitor: [SignLocation], completion:@escaping (_ location:SignLocation) -> Void)
    {
        locationManager.delegate = self
        locationManager.distanceFilter = 5
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        detectionHandler = completion
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
        if shouldUpdateCurrentLocation(current: self.currentLocation) {
            shouldUpdateMonitoredRegions = true
            locationManager.startUpdatingLocation()
//            locationManager.requestLocation()
        }
        else {
            updateMonitoredRegions(location: self.currentLocation!)
        }
    }

    func checkIfPermissionsAreSufficient(_ currentPermission:CLAuthorizationStatus) -> TrackerState
    {
        switch(currentPermission) {
        case .notDetermined:
            return .NeedConfiguration
        case .authorizedAlways:
            return .ReadyToTrack
        case .authorizedWhenInUse, .denied, .restricted:
            return .NotReadyToTrack
        }
    }
    
    open func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        prepareForTracking()
    }

    func shouldUpdateCurrentLocation(current:CLLocation?) -> Bool {
        let minuteAgo = Date().addingTimeInterval(TimeInterval(-60))
        if current == nil || current!.timestamp < minuteAgo {
            return true
        }
        return false
    }
    
//    if shouldUpdateCurrentLocation(current: self.currentLocation) {
//    closestSignRequestHandler = completioHandler
//    locationManager.requestLocation()
//    }
//    else {
//    let closest = getClosestSign(location: self.currentLocation!, from: self.allLocations)
//    completioHandler(closest)
//    }
    
    func notifyAboutSignNearby(sign:SignLocation) {
        NotificationCenter.default.post(name: kNotificationSignNearby,
                                        object: nil,
                                        userInfo: [ kNotificationSignNearbyId: sign.objectId])
    }
    
    //MARK:- CLLocaitonManager Delegate protocol
    
    open func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion)
    {
        if manager.location!.horizontalAccuracy > kCLLocationAccuracyNearestTenMeters {
            return
        }
        if region.identifier == "CurrentRegion" {
            print("Detected Enter. Requesting data to update all regions")
            shouldUpdateMonitoredRegions = true
            locationManager.startUpdatingLocation()
//            locationManager.requestLocation()
        }
        else {
            print("Checking for location hit with \(region.identifier)")
            guard let hit = allLocations.first(where: { (sign) -> Bool in
                return sign.objectId == region.identifier
            }) else {return}
            print("Got location hit \(hit.objectId)")
            detectionHandler(hit)
        }
    }

    open func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion)
    {
        if manager.location!.horizontalAccuracy > kCLLocationAccuracyNearestTenMeters {
            return
        }
        print("Detected Exit. Requesting data to update all regions")
        shouldUpdateMonitoredRegions = true
        locationManager.startUpdatingLocation()
    }
    
    func getClosestSign(location:CLLocation?, from locationSet:[SignLocation]) -> SignLocation? {
        let allUndiscovered = locationSet.filter { (location:SignLocation) -> Bool in
            return !location.isCollected
        }
        
        return getClosestSignFrom(locationSet: allUndiscovered, to: location)
    }
    
    func updateMonitoredRegions(location:CLLocation) {
        updateHomeRegion(location: location)
        updateSignRegions(location: location)
    }
    
    func updateSignRegions(location:CLLocation) {
        print("Updating sign regions")
        let signsToMonitor = self.findCloseSignsFrom(locationSet: self.allLocations, to: location, within: kCloseSignRadius)
        print("Setting sign regions for \(signsToMonitor)")

        signsToMonitor.forEach({ (sign) in
            let region = sign.regionWithRadius(radius: kRegionRadius)
            //TODO: maintain a low number of monitored regions, cleanup old ones
            print("Monitoring \(region.identifier) for sign \(sign.objectId)")
            self.locationManager.startMonitoring(for: region)
        })
        

    }
    func updateHomeRegion(location:CLLocation) {
        print("Updating home region")
        if currentRegion != nil {
            locationManager.stopMonitoring(for: currentRegion!)
        }
        if currentLocation != nil {
            print("Setting home region to \(location.coordinate)")
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
        
        guard let newCurrentLocation = locations.last,  newCurrentLocation.horizontalAccuracy<=20 else {
            print("location accuracy \(locations.last?.horizontalAccuracy) is too low")
            return
        }
//        locationManager.stopUpdatingLocation()
        
        currentLocation = newCurrentLocation
        
        print("Updating current location to \(String(describing: newCurrentLocation.coordinate))")
        if let closest = getClosestSign(location: newCurrentLocation, from: self.allLocations) {
            notifyAboutSignNearby(sign: closest)
        }
        
        if shouldUpdateMonitoredRegions {
            print("Starting Updating regions")
            updateMonitoredRegions(location: newCurrentLocation)
            shouldUpdateMonitoredRegions = false
        }
    }
    
    
    
    
    open func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Something failed")
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
    
    func distanceFromLocation(signLocation:SignLocation)->Int {
        let meterToStepRatio = 1.3123
//        if self.locationManager.location!.horizontalAccuracy > kCLLocationAccuracyNearestTenMeters {
//            return
//        }
        let distance = self.locationManager.location!.distance(from: signLocation.location)
        
        return Int(distance * meterToStepRatio)
    }
}
