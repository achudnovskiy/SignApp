//
//  SignDataSource.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-01-22.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit

class SignDataSource: NSObject {

    static let sharedInstance = SignDataSource()
    
    let dataArray:[SignObject]
    
    var discoveredSigns:[SignObject] {
        get {
            return dataArray.filter { (sign) -> Bool in
                return sign.isCollected && sign.isDiscovered
            }
        }
    }
    var newSigns:[SignObject] {
        get {
            return dataArray.filter { (sign) -> Bool in
                return sign.isCollected && !sign.isDiscovered
            }
        }
    }
    var notCollectedSigns:[SignObject] {
        get {
            return dataArray.filter { (sign) -> Bool in
                return !sign.isCollected
            }
        }
    }
    var collectedSignsOrdered:[SignObject] {
        get {
            return newSigns + discoveredSigns
        }
    }
    var locations:[SignLocation] {
        get {
            var result:[SignLocation] = []
            dataArray.forEach { (sign) in
                result.append(sign.location)
            }
            return result
        }
    }
    override init() {
        let pathRamen = Bundle.main.path(forResource: "RamenImage", ofType: "png", inDirectory: "Content")!
        let pathRamenContent = Bundle.main.path(forResource: "RamenContent", ofType: "png", inDirectory: "Content")!
        let pathHomer = Bundle.main.path(forResource: "HomerImage", ofType: "png", inDirectory: "Content")!
        let pathHomerContent = Bundle.main.path(forResource: "RamenContent", ofType: "png", inDirectory: "Content")!
        let pathRevolver = Bundle.main.path(forResource: "RevolverImage", ofType: "png", inDirectory: "Content")!
        let pathRevolverContent = Bundle.main.path(forResource: "RevolverContent", ofType: "png", inDirectory: "Content")!
        let pathMario = Bundle.main.path(forResource: "MarioImage", ofType: "png", inDirectory: "Content")!
        let pathMarioContent = Bundle.main.path(forResource: "MarioContent", ofType: "png", inDirectory: "Content")!
        let pathThiery = Bundle.main.path(forResource: "ThieryImage", ofType: "png", inDirectory: "Content")!
        let pathThieryContent = Bundle.main.path(forResource: "ThieryContent", ofType: "png", inDirectory: "Content")!
        let pathBuzz = Bundle.main.path(forResource: "BuzzImage", ofType: "png", inDirectory: "Content")!
        let pathBuzzContent = Bundle.main.path(forResource: "BuzzContent", ofType: "png", inDirectory: "Content")!

        let ramenSign = SignObject(objectId:"2C518C01-233B-4BE1-9ACC-58DF80B1CC33",
                                   title: "Ramen",
                                   image: UIImage(contentsOfFile: pathRamen)!,
                                   infographic:UIImage(contentsOfFile: pathRamenContent)!,
                                   latitude: 49.290084,
                                   longitude: -123.133972,
                                   locationName: "Hokkaido Santouka",
                                   locationDescription: "Something clever")
        let homerSign = SignObject(objectId:"3D10AA5F-D9C4-4D56-8E39-960AC323AB4E",
                                   title: "French",
                                   image: UIImage(contentsOfFile: pathHomer)!,
                                   infographic: UIImage(contentsOfFile: pathHomerContent)!,
                                   latitude: 49.278409,
                                   longitude: -123.118361,
                                   locationName: "Homer St. Cafe",
                                   locationDescription: "Something clever")
        let revolverSign = SignObject(objectId:"59C370A4-5480-41AA-A431-507D67346A7F",
                                      title: "Coffee",
                                      image: UIImage(contentsOfFile: pathRevolver)!,
                                      infographic: UIImage(contentsOfFile: pathRevolverContent)!,
                                      latitude: 49.283170,
                                      longitude: -123.109484,
                                      locationName: "Revolver",
                                      locationDescription: "Something clever")
        let marioSign = SignObject(objectId:"59A7C34B-3963-43B6-A4CC-422E4422D496",
                                   title: "Espresso",
                                   image: UIImage(contentsOfFile: pathMario)!,
                                   infographic: UIImage(contentsOfFile: pathMarioContent)!,
                                   latitude: 49.284614,
                                   longitude: -123.117142,
                                   locationName: "Mario's Cafe",
                                   locationDescription: "Something clever")
        let thierySign = SignObject(objectId:"B72D8A76-98D6-4618-B089-EF6FA9E078D8",
                                    title: "Desert",
                                    image: UIImage(contentsOfFile: pathThiery)!,
                                    infographic: UIImage(contentsOfFile: pathThieryContent)!,
                                    latitude: 49.284789,
                                    longitude: -123.122712,
                                    locationName: "Therry Chocolatier",
                                    locationDescription: "Something clever")
        let buzzSign = SignObject(objectId:"ABC34261-6E61-4FF6-AFC0-7C2C785EA968",
                                  title: "Gallery",
                                  image: UIImage(contentsOfFile: pathBuzz)!,
                                  infographic: UIImage(contentsOfFile: pathBuzzContent)!,
                                  latitude: 49.27841,
                                  longitude: -123.118711,
                                  locationName: "Buzz Cafe",
                                  locationDescription: "Something clever")
        
        thierySign.isCollected = true
        thierySign.isDiscovered = true
        
        ramenSign.isDiscovered = true
        ramenSign.isCollected = true
        
        marioSign.isCollected = true
        
        buzzSign.isCollected = true
        buzzSign.isDiscovered = true
        
        dataArray = [ramenSign, homerSign, revolverSign, marioSign, thierySign, buzzSign];

        super.init()
        
        reloadCollections()
    }
    
    func findSignObjById(objectId: String) -> SignObject? {
        var result:SignObject?
        dataArray.forEach { (sign) in
            if sign.objectId == objectId {
                result = sign
            }
        }
        return result
    }
    
    func exportUserData()->AnyObject {
        var result:[String:[String:AnyObject]] = [:]
        dataArray.forEach { (sign) in
            result[sign.objectId] = sign.archivedData
        }
        return result as AnyObject
    }
    
    func restoreUserData(userData:[String:AnyObject]) {
        dataArray.forEach { (sign) in
            if userData[sign.objectId] != nil {
                restoreUserData(userData: userData[sign.objectId] as! [String : AnyObject])
            }
        }
    }
    
    func reloadCollections() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ReloadData"), object: nil)
    }
}
