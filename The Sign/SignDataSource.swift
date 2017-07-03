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
//        let pathRamen = Bundle.main.path(forResource: "RamenImage", ofType: "png", inDirectory: "Content")!
//        let pathHomer = Bundle.main.path(forResource: "HomerImage", ofType: "png", inDirectory: "Content")!
//        let pathRevolver = Bundle.main.path(forResource: "RevolverImage", ofType: "png", inDirectory: "Content")!
//        let pathMario = Bundle.main.path(forResource: "MarioImage", ofType: "png", inDirectory: "Content")!
//        let pathThiery = Bundle.main.path(forResource: "ThieryImage", ofType: "png", inDirectory: "Content")!
//        let pathBuzz = Bundle.main.path(forResource: "BuzzImage", ofType: "png", inDirectory: "Content")!
//
//        let ramenSign = SignObject(objectId:"2C518C01-233B-4BE1-9ACC-58DF80B1CC33",
//                                   title: "Ramen",
//                                   content: "JAPANESE TO ITS CORE. IT TAKES OVER 20 HOURS TO PREPARE ITS FAMOUS BROTH. TRADITIONAL CUISINE OF SUCH QUALITY IS RARE TO COME BY. PERFECT FOR LUNCH ON A COLD WINTER DAY.",
//                                   image: UIImage(contentsOfFile: pathRamen)!,
//                                   latitude: 49.290084,
//                                   longitude: -123.133972,
//                                   locationName: "Hokkaido Santouka")
//        let homerSign = SignObject(objectId:"3D10AA5F-D9C4-4D56-8E39-960AC323AB4E",
//                                   title: "French",
//                                   content: "ALTHOUGH NOT FRENCH AS PER DESCRIPTION, HOMER ST CAFE AND BAR IS THE BEST REPRESENTATION OF FRENCH CUISINE IN VANCOUVER WE COULD FIND. ROTISSERIE CHICKEN WITH SIDE DISHES IS A MUST.",
//                                   image: UIImage(contentsOfFile: pathHomer)!,
//                                   latitude: 49.278409,
//                                   longitude: -123.118361,
//                                   locationName: "Homer St. Cafe")
//        let revolverSign = SignObject(objectId:"59C370A4-5480-41AA-A431-507D67346A7F",
//                                      title: "Coffee",
//                                      content: "BEST WELL-CRAFTED LIVES IN REVOLVER. LOCAL BARISTAS MAKE A CUP SO DELICIOUS, YOU WOULD HAVE TO ALTER YOUR DAILY ROUTE TO POP BY ON A REGULAR BASIS FROM NOW ON.",
//                                      image: UIImage(contentsOfFile: pathRevolver)!,
//                                      latitude: 49.283170,
//                                      longitude: -123.109484,
//                                      locationName: "Revolver")
//        let marioSign = SignObject(objectId:"59A7C34B-3963-43B6-A4CC-422E4422D496",
//                                   title: "Espresso",
//                                   content: "ONLY ONE ESPRESSO CAN RIVAL THE TRADITIONAL ITALIAN CAFES. MARIO HONED HIS SKILLS FOR DECADES TO BE ABLE TO DELIVER AN AMAZINGLY BALANCE CUP OF COFFEE. FOR DAYS YOU NEED CAFFEINE TO KEEP ROCKING.",
//                                   image: UIImage(contentsOfFile: pathMario)!,
//                                   latitude: 49.284614,
//                                   longitude: -123.117142,
//                                   locationName: "Mario's Cafe")
//        let thierySign = SignObject(objectId:"B72D8A76-98D6-4618-B089-EF6FA9E078D8",
//                                    title: "Deserts",
//                                    content: "EXQUISITE IS THE PERFECT DESCRIPTION FOR THIERRY BUSSET’S VENTURE IN VANCITY. MACARONS, CROISSANTS & TARTS ARE SECOND TO NONE. PICK UP A SWEET FOR A LOVED ONE ON A WAY FROM A HARD DAY AT WORK.",
//                                    image: UIImage(contentsOfFile: pathThiery)!,
//                                    latitude: 49.284789,
//                                    longitude: -123.122712,
//                                    locationName: "Therry Chocolatier")
//        let buzzSign = SignObject(objectId:"ABC34261-6E61-4FF6-AFC0-7C2C785EA968",
//                                  title: "Gallery",
//                                  content: "A VISIT TO AN ART GALLERY DOESN’T HAVE TO BE GRANDIOSE. STOP BY HARRISON GALLERIES. GRAB A COFFEE AND WALK AROUND ENJOYING ART. MANY COMFY NOOKS INSIDE FOR WORK TOO.",
//                                  image: UIImage(contentsOfFile: pathBuzz)!,
//                                  latitude: 49.27841,
//                                  longitude: -123.118711,
//                                  locationName: "Buzz Cafe")
//
//        thierySign.isCollected = true
//        thierySign.isDiscovered = true
//
//        ramenSign.isDiscovered = true
//        ramenSign.isCollected = true
//
//        marioSign.isCollected = true
//
//        buzzSign.isCollected = true
//        buzzSign.isDiscovered = true
//
//        dataArray = [ramenSign, homerSign, revolverSign, marioSign, thierySign, buzzSign];
        
        super.init()
        getAllProductsFromCloud { (signObjects) in
            self.dataArray = signObjects
            self.reloadCollections()
        }
//        reloadCollections()
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
