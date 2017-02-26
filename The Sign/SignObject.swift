//
//  SignObject.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-01-14.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit
import CoreLocation

public struct SignLocation {
    let objectId:String
    let location:CLLocation
    let isCollected:Bool
    func regionWithRadius(radius:CLLocationDistance) -> CLCircularRegion {
        return CLCircularRegion(center: location.coordinate, radius: radius, identifier: objectId)
    }
}

public class SignObject: NSObject {
    
    let objectId:String
    
    let title:String
    let mysteryText:String
    let image:UIImage
    let infographic:UIImage
    var isDiscovered: Bool = false;
    var isCollected: Bool = false;
    
    var location:SignLocation {
        get {
            return SignLocation(objectId: objectId, location: CLLocation(latitude: latitude, longitude: longitude), isCollected: isCollected)
        }
    }
    let latitude:Double
    let longitude:Double
    let locationName:String
    let LocationDescription:String
    
    var lastVisitedDate:Date?
    var sharedDate:Date?

    init(objectId:String,
         title:String,
         mysteryText:String,
         image:UIImage,
         infographic:UIImage,
         latitude: CLLocationDegrees,
         longitude: CLLocationDegrees,
         locationName:String,
         locationDescription:String) {
        self.objectId = objectId
        self.title = title
        self.mysteryText = mysteryText
        self.image = image
        self.infographic = infographic
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.LocationDescription = locationDescription
    }
    
    public override var description: String {
        return "ID:\(objectId) LocationName:\(locationName) Coordinates:\(location.location) Title:\(title) IsDiscovered:\(isDiscovered) isCollected:\(isCollected)"
    }
    
    var viewMode:SignCardViewMode {
        get {
            if isCollected {
                return isDiscovered ? .Discovered : .NotDiscovered
            }
            else {
                return .NotCollected
            }
        }
    }
    
    var thumbnailText:String {
        get {
            if isCollected {
                if isDiscovered {
                    return title
                }
                else {
                    return "Tap to see a new Sign"
                }
            }
            else {
                return mysteryText
            }
        }
    }
    
    func processLocationVisit() {
        if isCollected == false {
            isCollected = true
        }
        
        lastVisitedDate = Date()
    }
    
    func unarchive(archivedData:[String:AnyObject]) {
        isDiscovered = archivedData["isDiscovered"] as! Bool
        isCollected = archivedData["isCollected"] as! Bool
        lastVisitedDate = archivedData["lastVisitedDate"] as? Date
        sharedDate = archivedData["sharedDate"] as? Date

    }
    var archivedData:[String:AnyObject] {
        var result:[String:AnyObject] = ["isDiscovered":isDiscovered as AnyObject,
                                   "isCollected":isCollected as AnyObject]

        if lastVisitedDate != nil {
            result["lastVisitedDate"] = lastVisitedDate! as AnyObject!
        }
        if sharedDate != nil {
            result["sharedDate"] = sharedDate! as AnyObject!
        }
        
        return result
    }

    override public var hash: Int {
        return self.objectId.hash
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        if let object = object as? SignObject {
            return self.objectId == object.objectId
        }
        else {
            return false
        }
    }
    
}
