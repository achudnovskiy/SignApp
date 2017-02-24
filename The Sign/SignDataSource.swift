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
    
    var collectedSignsOrdered:[SignObject]!
    var notCollectedSigns:[SignObject]!
    var discoveredSigns:[SignObject]!
    var newSigns:[SignObject]!
    
    override init() {
        
        let ramenSign = SignObject(objectId:"2C518C01-233B-4BE1-9ACC-58DF80B1CC33",
                                   title: "Ramen",
                                   image: UIImage(named: "TestRamenImage")!,
                                   infographic: UIImage(named: "TestRamenContent")!,
                                   latitude: 49.290084,
                                   longitude: -123.133972,
                                   locationName: "Hokkaido Santouka",
                                   locationDescription: "Something clever")
        let homerSign = SignObject(objectId:"3D10AA5F-D9C4-4D56-8E39-960AC323AB4E",
                                   title: "French",
                                   image: UIImage(named: "TestHomerImage")!,
                                   infographic: UIImage(named: "TestHomerContent")!,
                                   latitude: 49.278409,
                                   longitude: -123.118361,
                                   locationName: "Homer St. Cafe",
                                   locationDescription: "Something clever")
        let revolverSign = SignObject(objectId:"59C370A4-5480-41AA-A431-507D67346A7F",
                                      title: "Coffee",
                                      image: UIImage(named: "TestCoffeeImage")!,
                                      infographic: UIImage(named: "TestCoffeeContent")!,
                                      latitude: 49.283170,
                                      longitude: -123.109484,
                                      locationName: "Revolver",
                                      locationDescription: "Something clever")
        let marioSign = SignObject(objectId:"59A7C34B-3963-43B6-A4CC-422E4422D496",
                                   title: "Espresso",
                                   image: UIImage(named: "TestEspressoImage")!,
                                   infographic: UIImage(named: "TestEspressoContent")!,
                                   latitude: 49.284614,
                                   longitude: -123.117142,
                                   locationName: "Mario's Cafe",
                                   locationDescription: "Something clever")
        let thierySign = SignObject(objectId:"B72D8A76-98D6-4618-B089-EF6FA9E078D8",
                                    title: "Desert",
                                    image: UIImage(named: "TestThieryImage")!,
                                    infographic: UIImage(named: "TestThieryContent")!,
                                    latitude: 49.284789,
                                    longitude: -123.122712,
                                    locationName: "Therry Chocolatier",
                                    locationDescription: "Something clever")
        let buzzSign = SignObject(objectId:"ABC34261-6E61-4FF6-AFC0-7C2C785EA968",
                                  title: "Gallery",
                                  image: UIImage(named: "TestBuzzImage")!,
                                  infographic: UIImage(named: "TestBuzzContent")!,
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
                restoreUserData(userData: userData[sign.objectId])
            }
        }
    }
    
    func getDiscoverySign() -> SignObject {
    }
    
    func reloadCollections() {
        
        self.discoveredSigns = dataArray.filter { (sign) -> Bool in
            return sign.isCollected && sign.isDiscovered
        }
        self.newSigns = dataArray.filter { (sign) -> Bool in
            return sign.isCollected && !sign.isDiscovered
        }
        self.notCollectedSigns = dataArray.filter({ (sign) -> Bool in
            return !sign.isCollected
        })
        
        self.collectedSignsOrdered = newSigns + discoveredSigns
    
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ReloadData"), object: nil)
    }
}
