//
//  SignDataSource.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-01-22.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit

class SignDataSource: NSObject {

    let dataArray:[SignObject]
    
    override init() {
        
        SignLocation(locationId: "345678", latitude: 49.283170, longitude: -123.109484, name: "Revolver", description: "Something clever")
        
        let testRamenLocation = SignLocation(locationId: "12345", latitude: 49.290084, longitude: -123.133972, name: "Hokkaido Santouka", description: "Something clever")
        let testFrenchLocation = SignLocation(locationId: "23456", latitude: 49.278409, longitude: -123.118361, name: "Homer St. Cafe", description: "Something clever")
        let testCoffeeLocation = SignLocation(locationId: "345678", latitude: 49.283170, longitude: -123.109484, name: "Revolver", description: "Something clever")
        
        let testEspressoLocation = SignLocation(latitude: 49.284614, locationTag: nil, longitude: -123.117142, businessName: "Mario's Cafe")
        let testChocolateLocation = SignLocation(latitude: 49.284789, locationTag: nil, longitude: -123.122712, businessName: "Therry Chocolatier")
        let testGalleryLocation = SignLocation(latitude: 49.27841, locationTag: nil, longitude: -123.118711, businessName: "Buzz Cafe")
        
        
        let ramenSign = SignObject(title: "Ramen",
                                   image: UIImage(named: "TestRamenImage")!,
                                   infographic: UIImage(named: "TestRamenContent")!,
                                   location:testRamenLocation)
        let homerSign = SignObject(title: "French Cuisine",
                                   image: UIImage(named: "TestHomerImage")!,
                                   infographic: UIImage(named: "TestHomerContent")!,
                                   location:testFrenchLocation)
        let revolverSign = SignObject(title: "Coffee",
                                      image: UIImage(named: "TestCoffeeImage")!,
                                      infographic: UIImage(named: "TestCoffeeContent")!,
                                      location:testCoffeeLocation)
        let marioSign = SignObject(title: "Espresso",
                                   image: UIImage(named: "TestEspressoImage")!,
                                   infographic: UIImage(named: "TestEspressoContent")!,
                                   location: testEspressoLocation)
        let thierySign = SignObject(title: "Desert",
                                    image: UIImage(named: "TestThieryImage")!,
                                    infographic: UIImage(named: "TestThieryContent")!,
                                    location: testChocolateLocation)
        let buzzSign = SignObject(title: "Gallery",
                                  image: UIImage(named: "TestBuzzImage")!,
                                  infographic: UIImage(named: "TestBuzzContent")!,
                                  location: testGalleryLocation)
        buzzSign.isDiscovered = false
        
        dataArray = [ramenSign, homerSign, revolverSign, marioSign, thierySign, buzzSign];
        
    }
    
    var orderedDataArray:[SignObject] {
        get {
            return newSigns + discoveredSigns
        }
    }
    
    var discoveredSigns:[SignObject] {
        get {
            return dataArray.filter { (sign) -> Bool in
                return sign.isDiscovered
            }
        }
    }

    var newSigns:[SignObject] {
        get {
            return dataArray.filter { (sign) -> Bool in
                return !sign.isDiscovered
            }
        }
    }

}
