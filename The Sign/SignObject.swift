//
//  SignObject.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-01-14.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit
import CoreLocation

public class SignObject: NSObject {
    
    let objectId:String
    
    let title:String
    let image:UIImage
    let infographic:UIImage
    var isDiscovered: Bool = false;
    var isCollected: Bool = false;
    
    let location:CLLocation
    let locationName:String
    let LocationDescription:String
    
    var lastVisitedDate:Date?
    var sharedDate:Date?

    init(title:String,
         image:UIImage,
         infographic:UIImage,
         latitude: CLLocationDegrees,
         longitude: CLLocationDegrees,
         locationName:String,
         locationDescription:String) {
        objectId = UUID().uuidString
        self.title = title
        self.image = image
        self.infographic = infographic
        self.location = CLLocation(latitude: latitude, longitude: longitude)
        self.locationName = locationName
        self.LocationDescription = locationDescription
    }
    public override var description: String {
        return "ID:\(objectId) LocationName:\(locationName) Coordinates:\(location.coordinate) Title:\(title) IsDiscovered:\(isDiscovered) isCollected:\(isCollected) LastVisitDate:\(lastVisitedDate)"
    }
    func regionForLocation(with radius:CLLocationDistance) -> CLCircularRegion {
        return CLCircularRegion(center: self.location.coordinate, radius: radius, identifier: self.objectId)
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
