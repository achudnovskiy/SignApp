//
//  SignObject.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-01-14.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit

struct SignLocation {
    var lastHitDate: Date?
    var latitude: Double
    let locationTag: String?
    let longitude: Double
    let businessName: String
}
class SignObject: NSObject {
    
    let objectId:String
    
    let title:String
    let image:UIImage
    let infographic:UIImage
    var isDiscovered: Bool = true
//    var mysteryText: String
    
    let location:SignLocation 
    
    var sharedDate:Date?

    init(title:String, image:UIImage, infographic:UIImage, location:SignLocation) {
        objectId = UUID().uuidString
        self.title = title
        self.image = image
        self.infographic = infographic
        self.location = location
    }
    
    override var hash: Int {
        return self.objectId.hash
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? SignObject {
            return self.objectId == object.objectId
        }
        else {
            return false
        }
    }
    
}
