//
//  SignObject.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-01-14.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit
import CoreLocation

public struct SignLocation: CustomStringConvertible{
    public var description: String {
        return "ID:\(objectId), isCollected:\(isCollected)"
    }
    
    let objectId:String
    let location:CLLocation
    let isCollected:Bool
    let name:String
    func regionWithRadius(radius:CLLocationDistance) -> CLCircularRegion {
        return CLCircularRegion(center: location.coordinate, radius: radius, identifier: objectId)
    }
}

public class SignObject: NSObject {
    
    let objectId:String
    
    let title:String
    let image:UIImage
    let content:String
    var isDiscovered: Bool = false;
    var isCollected: Bool = false;
    var distance:Int
    
    var location:SignLocation {
        get {
            return SignLocation(objectId: objectId, location: CLLocation(latitude: latitude, longitude: longitude), isCollected: isCollected, name:locationName)
        }
    }
    let latitude:Double
    let longitude:Double
    let locationName:String
    let appLinkUrl:String
    
    var lastVisitedDate:Date?
    var sharedDate:Date?

    init(objectId:String,
         title:String,
         content:String,
         image:UIImage,
         latitude: CLLocationDegrees,
         longitude: CLLocationDegrees,
         locationName:String,
         appLinkUrl:String) {
        self.objectId = objectId
        self.title = title
        self.image = image
        self.content = content
        self.appLinkUrl = appLinkUrl
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        
        self.distance = 0
    }
    
    public override var description: String {
        return "ID:\(objectId) LocationName:\(locationName) Coordinates:\(location.location) Title:\(title) IsDiscovered:\(isDiscovered) isCollected:\(isCollected)"
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
                return "Steps to new Sign\n\(distance)"
            }
        }
    }
    
    func proccessImage() -> UIImage {
        if isCollected {
            return image.optimizedImage()
        }
        else {
            return image.applyDefaultEffect()!.optimizedImage()
        }
    }
    
    func processLocationVisit() {
        if isCollected == false {
            isCollected = true
        }
        
        lastVisitedDate = Date()
    }

    var uniqueId:NSString {
        get {
            return NSString(string: objectId)
        }
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
