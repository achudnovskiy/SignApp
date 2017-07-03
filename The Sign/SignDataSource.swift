//
//  SignDataSource.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-01-22.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit
import CloudKit

class SignDataSource: NSObject {

    static let sharedInstance = SignDataSource()
    
    let publicDB = CKContainer.default().publicCloudDatabase
    var dataArray:[SignObject] = []
    
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
        super.init()
        getAllProductsFromCloud { (signObjects) in
            self.dataArray = signObjects
            
            //TESTING
            self.dataArray[0].isCollected = true
            for index in 1...3 {
                self.dataArray[index].isDiscovered = true
                self.dataArray[index].isCollected = true
            }
            //TESTING
            
            self.reloadCollections()
        }
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
                sign.unarchive(archivedData: userData[sign.objectId] as! [String : AnyObject])
            }
        }
    }
    
    func reloadCollections() {
        NotificationCenter.default.post(name: kNotificationReloadData, object: nil)
    }
    
    
    //MARK:- CloudKit
    
    public func getAllProductsFromCloud(completionBlock:@escaping ([SignObject])->Void) {
        
        let query = CKQuery(recordType: "SignData", predicate: NSPredicate(value: true))
        
        publicDB.perform(query, inZoneWith: nil) { (records, error) in
            var result:[SignObject] = []
            
            if (error != nil || records == nil) {
                print("error in fetching cloudkit. Error info:\(String(describing: error))")
            }
            else {
                
                for record:CKRecord in records! {
                    
                    let businessName = record.object(forKey: "businessName") as? String
                    let content = record.object(forKey: "content") as? String
                    let keyword = record.object(forKey: "keyword") as? String
                    let location = record.object(forKey: "location") as? CLLocation
                    var image:UIImage?
                    if let asset = record.object(forKey: "image") as? CKAsset {
                        if let data = NSData(contentsOf: asset.fileURL) {
                            image = UIImage(data: data as Data)
                        }
                    }
                    
                    if businessName != nil && content != nil && keyword != nil && location != nil && image != nil {
                        result.append(SignObject(objectId: record.recordID.recordName, title: keyword!, content: content!, image: image!, latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude, locationName: businessName!))
                    }
                }
            }
            
            completionBlock(result)
        }
    }
    
    
    func saveSubscription() {
        let subscription = CKQuerySubscription(recordType: "SignData",
                                               predicate: NSPredicate(value: true),
                                               options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion])
        
        publicDB.save(subscription) { (subscription, error) in
            //TODO: handle error cases
        }
    }
}
