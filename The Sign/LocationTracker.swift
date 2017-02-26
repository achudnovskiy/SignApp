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
    
    internal var closeLocations:[CLLocation]
    
    internal var completionHandler:((_ location:SignLocation) -> Void)!
    
    internal var closestSignRequestHandler:((_ closestSign:SignLocation?) -> Void)?
    internal var shouldUpdateMonitoredRegions:Bool = false
    
    //MARK:- Public API
    
    override init ()
    {
        locationManager = CLLocationManager()
        allLocations = []
        closeLocations = []
        
        super.init()
    }
    
    open func startMonitoringForLocations(_ locationsToMonitor: [SignLocation], completion:@escaping (_ location:SignLocation) -> Void)
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
        if shouldUpdateCurrentLocation(current: self.currentLocation) {
            shouldUpdateMonitoredRegions = true
            locationManager.requestLocation()
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
    
    func getClosestSign(with completioHandler:@escaping (_ location:SignLocation?) -> Void) {
        if shouldUpdateCurrentLocation(current: self.currentLocation) {
            closestSignRequestHandler = completioHandler
            locationManager.requestLocation()
        }
        else {
            let closest = getClosestSign(location: self.currentLocation!, from: self.allLocations)
            completioHandler(closest)
        }
    }

    //MARK:- CLLocaitonManager Delegate protocol
    
    open func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion)
    {
        if region.identifier == "CurrentRegion" {
            print("Detected Enter. Requesting data to update all regions")
            shouldUpdateMonitoredRegions = true
            locationManager.requestLocation()
        }
        else {
            print("Checking for location hit with \(region.identifier)")
            let hit = allLocations.first(where: { (sign) -> Bool in
                return sign.objectId == region.identifier
            })
            if hit != nil {
                print("Got location hit \(hit!.objectId)")
                completionHandler(hit!)
            }
        }
    }

    open func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion)
    {
        print("Detected Exit. Requesting data to update alll regions")
        shouldUpdateMonitoredRegions = true
        locationManager.requestLocation()
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

    open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = manager.location
        print("Updating current location to \(manager.location?.coordinate)")
        if closestSignRequestHandler != nil {
            let closest = getClosestSign(location: currentLocation, from: self.allLocations)
            closestSignRequestHandler!(closest)
            closestSignRequestHandler = nil
            print("Finding closest sign: \(closest)")
        }
        
        if shouldUpdateMonitoredRegions {
            print("Starting Updating regions")
            if currentLocation != nil {
                updateMonitoredRegions(location: currentLocation!)
            }
            else {
                locationManager.requestLocation()
            }
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

}
