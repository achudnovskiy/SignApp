//
//  SignDataSource.swift
//  The Sign
//
//  Created by Andrey Chudnovskiy on 2017-01-22.
//  Copyright © 2017 Simple Matters. All rights reserved.
//

import UIKit
import CloudKit
import CoreData

class SignDataSource: NSObject {

    static let sharedInstance = SignDataSource()
    
    let publicDB = CKContainer.default().publicCloudDatabase
    
    override init() {
        super.init()
        checkDataForUpdate()
    }
    
    public var collectedSignsOrdered:[SignObject] {
        do {
            let signEntities = try persistentContainer.viewContext.fetch(self.collectedSignsRequest)
            var result:[SignObject] = []
            signEntities.forEach({ (signEntity) in
                result.append(signEntityToSignObject(entity: signEntity))
            })
            return result
        }
        catch {
            let nserror = error as NSError
            print("new signs querying error \(nserror), \(nserror.userInfo)")
            return []
        }
    }
    
    public var uncollectedSigns:[SignObject] {
        do {
            let signEntities = try persistentContainer.viewContext.fetch(self.undiscoveredSignsRequest)
            var result:[SignObject] = []
            signEntities.forEach({ (signEntity) in
                result.append(signEntityToSignObject(entity: signEntity))
            })
            return result
        }
        catch {
            let nserror = error as NSError
            print("uncollected signs querying error \(nserror), \(nserror.userInfo)")
            return []
        }
    }
    
    public var isEverythingCollected:Bool {
        do {
            return try persistentContainer.viewContext.count(for:self.undiscoveredSignsRequest) == 0
        }
        catch {
            let nserror = error as NSError
            print("new signs querying error \(nserror), \(nserror.userInfo)")
            return false
        }
    }
    
    
    public var locations:[SignLocation] {
        do {
            let signEntities = try persistentContainer.viewContext.fetch(self.allSignsRequest)
            var result:[SignLocation] = []
            signEntities.forEach({ (signEntity) in
                result.append(SignLocation(objectId: signEntity.recordId!, location: CLLocation(latitude: signEntity.latitude, longitude: signEntity.longitude), isCollected: signEntity.isCollected, name:signEntity.business!))
            })
            return result
        }
        catch {
            let nserror = error as NSError
            print("locations querying error \(nserror), \(nserror.userInfo)")
            return []
        }
    }
    
  
    
    var newSignsCount:Int {
        do {
            return try persistentContainer.viewContext.count(for: self.newSignsRequest)
        }
        catch {
            let nserror = error as NSError
            print("new signs count querying error \(nserror), \(nserror.userInfo)")
            return 0
        }
    }
    
    func collectSignWithId(_ signId:String) {
        guard let signEntity = self.findSignEntityById(objectId: signId) else { return }
        signEntity.isCollected = true
        saveData(notifyUI: true)
    }
    
    func discoverSignWith(_ signId:String) {
        guard let sign = self.findSignEntityById(objectId: signId) else { return }
        sign.isDiscovered = true
        sign.isCollected = true
        saveData(notifyUI: false)
    }

    
    func findSignEntityById(objectId: String) -> SignEntity? {
        do {
            let signEntities = try backgroundContext.fetch(self.signByIdRequest(signId: objectId))
            return signEntities.first
        }
        catch {
            let nserror = error as NSError
            print("new signs count querying error \(nserror), \(nserror.userInfo)")
            return nil
        }
    }
    
    func findSignObjById(objectId: String) -> SignObject? {
        guard let signEntity = self.findSignEntityById(objectId: objectId) else { return nil }
        return signEntityToSignObject(entity: signEntity)
    }
    
    func signEntityToSignObject(entity:SignEntity) -> SignObject {
        let signObject = SignObject(objectId: entity.recordId!,
                                    title: entity.keyword!,
                                    content: entity.content!,
                                    image: UIImage(data: entity.image! as Data)!,
                                    latitude: entity.latitude,
                                    longitude: entity.longitude,
                                    locationName: entity.business!,
                                    appLinkUrl: entity.appLinkUrl!)
        signObject.isDiscovered = entity.isDiscovered
        signObject.isCollected  = entity.isCollected
        return signObject
    }
    
    //MARK: - CoreData
    
    
    // MARK: - Core Data stack
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "The_Sign")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    private lazy var backgroundContext:NSManagedObjectContext = {
        return self.persistentContainer.newBackgroundContext()
    }()

    // MARK: - Core Data Saving support
    
    private func saveContext () {
        let context = self.backgroundContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
        persistentContainer.viewContext.refreshAllObjects()
    }
    
    
    
    private var collectedSignsRequest:NSFetchRequest<SignEntity> {
        let fetchRequest = (persistentContainer.managedObjectModel.fetchRequestTemplate(forName: "CollectedSigns") as! NSFetchRequest<SignEntity>).copy() as! NSFetchRequest<SignEntity>
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "isDiscovered", ascending: true)]
        
        return fetchRequest
    }
    private var undiscoveredSignsRequest:NSFetchRequest<SignEntity> {
        return (persistentContainer.managedObjectModel.fetchRequestTemplate(forName: "SignsToDiscover") as! NSFetchRequest<SignEntity>).copy() as! NSFetchRequest<SignEntity>
    }
    
    private var newSignsRequest:NSFetchRequest<SignEntity> {
        return (persistentContainer.managedObjectModel.fetchRequestTemplate(forName: "NewSigns") as! NSFetchRequest<SignEntity>).copy() as! NSFetchRequest<SignEntity>
    }
    
    var allSignsRequest:NSFetchRequest<SignEntity> {
        return (persistentContainer.managedObjectModel.fetchRequestTemplate(forName: "AllSigns") as! NSFetchRequest<SignEntity>).copy() as! NSFetchRequest<SignEntity>
    }
    
    private func signByIdRequest(signId:String) ->NSFetchRequest<SignEntity> {
        return persistentContainer.managedObjectModel.fetchRequestFromTemplate(withName: "SignById", substitutionVariables: ["signId":signId]) as! NSFetchRequest<SignEntity>
    }
    
    
    private func addCloudRecordToLocalStorage(cloudKitRecord:CKRecord) {
        let newSignEntity = NSEntityDescription.insertNewObject(forEntityName: "SignEntity", into: backgroundContext) as! SignEntity
        
        newSignEntity.recordId   = cloudKitRecord.recordID.recordName
        newSignEntity.changeTag  = cloudKitRecord.recordChangeTag
        newSignEntity.business   = cloudKitRecord.object(forKey: "businessName") as? String
        newSignEntity.content    = cloudKitRecord.object(forKey: "content") as? String
        newSignEntity.keyword    = cloudKitRecord.object(forKey: "keyword") as? String
        newSignEntity.appLinkUrl = cloudKitRecord.object(forKey: "appLinkUrl") as? String
        
        newSignEntity.latitude   = ((cloudKitRecord.object(forKey: "location") as? CLLocation)?.coordinate.latitude)!
        newSignEntity.longitude  = ((cloudKitRecord.object(forKey: "location") as? CLLocation)?.coordinate.longitude)!
        newSignEntity.image      = NSData(contentsOf: (cloudKitRecord.object(forKey: "image") as! CKAsset).fileURL)
        
        self.backgroundContext.insert(newSignEntity)
    }
    
    private func updateLocalStorageWithCloudRecord(coreDataEntity:SignEntity, cloudKitRecord:CKRecord) {
        coreDataEntity.changeTag  = cloudKitRecord.recordChangeTag
        coreDataEntity.business   = cloudKitRecord.object(forKey: "businessName") as? String
        coreDataEntity.content    = cloudKitRecord.object(forKey: "content") as? String
        coreDataEntity.keyword    = cloudKitRecord.object(forKey: "keyword") as? String
        coreDataEntity.appLinkUrl = cloudKitRecord.object(forKey: "appLinkUrl") as? String

        coreDataEntity.latitude   = ((cloudKitRecord.object(forKey: "location") as? CLLocation)?.coordinate.latitude)!
        coreDataEntity.longitude  = ((cloudKitRecord.object(forKey: "location") as? CLLocation)?.coordinate.longitude)!
        coreDataEntity.image      = NSData(contentsOf: (cloudKitRecord.object(forKey: "image") as! CKAsset).fileURL)
    }
    
    private func localCopyForCloudRecordWithId(_ recordId:CKRecordID) -> SignEntity? {
        do {
            let request:NSFetchRequest<SignEntity> = SignEntity.fetchRequest()
            request.predicate = NSPredicate(format:"recordId == %@", recordId.recordName)
            return try backgroundContext.fetch(request).first
        } catch {
            print("error in getting local record for cloudkit record. Error info:\(String(describing: error))")
            return nil
        }
    }
    
    private func allRecordsIds() -> [CKRecordID] {
        do {
            let request = self.allSignsRequest
            request.propertiesToFetch = ["recordId"]
            let entities  = try persistentContainer.viewContext.fetch(self.allSignsRequest)
            
            var result:[CKRecordID] = []
            entities.forEach({ (entity) in
                result.append(CKRecordID(recordName: entity.recordId!))
            })
            return result
        } catch {
            print("error in return all entities. Error info:\(String(describing: error))")
            return []
        }
    }
    
    private func queryCloudForRecords(recordIds:[CKRecordID], completionBlock:@escaping ([CKRecord])->Void){
        
        var recordRefs:[CKReference] = []
        recordIds.forEach { (recordId) in
            recordRefs.append(CKReference(recordID: recordId, action: .none))
        }
        
        let predicate = NSPredicate(format: "recordID IN %@", recordRefs)
        let query = CKQuery(recordType: "SignData", predicate: predicate)
        // worry about the size of the result
        publicDB.perform(query, inZoneWith: nil) { (result, error) in
            guard let records = result, error == nil else {
                print("error in fetching cloudkit. Error info:\(String(describing: error))")
                completionBlock([])
                return
            }
            completionBlock(records)
        }
    }
    
    func checkDataForUpdate() {
        let query = CKQuery(recordType: "SignData", predicate: NSPredicate(value: true))
        let queryOperation = CKQueryOperation(query: query)
        var recordsToUpdate = Set<CKRecordID>()
        var recordsToInsert = Set<CKRecordID>()
        var recordsUpToDate = Set<CKRecordID>()
        
        queryOperation.desiredKeys = []
        queryOperation.recordFetchedBlock = {(record) in
            
            let localCopy = self.localCopyForCloudRecordWithId(record.recordID)
            
            if localCopy == nil {
                recordsToInsert.insert(record.recordID)
            } else if localCopy != nil && localCopy!.changeTag != record.recordChangeTag  {
                recordsToUpdate.insert(record.recordID)
            } else if localCopy != nil && localCopy!.changeTag == record.recordChangeTag {
                recordsUpToDate.insert(record.recordID)
            }
        }
        
        queryOperation.queryCompletionBlock = { (queryRecords, error) in
            if error != nil {
                print("error in fetching cloudkit. Error info:\(String(describing: error))")
                return
            }
            
            let allLocalRecordIds = Set(self.allRecordsIds())
            let allCloudRecordIds = recordsToUpdate.union(recordsToInsert).union(recordsUpToDate)
            let recordsToDelete = allCloudRecordIds.subtracting(allCloudRecordIds)
            if recordsToUpdate.count == 0 && recordsToInsert.count == 0 && recordsUpToDate.count == allLocalRecordIds.count {
                print("everything is up to date")
            }
            else {
        
                self.syncCloudWithLocalStorage(recordsToUpdate: recordsToUpdate, recordsToInsert: recordsToInsert, recordsToDelete: recordsToDelete)
            }
        }
        CKContainer.default().publicCloudDatabase.add(queryOperation)
    }
    
    private func syncCloudWithLocalStorage(recordsToUpdate:Set<CKRecordID>, recordsToInsert:Set<CKRecordID>, recordsToDelete:Set<CKRecordID>) {
        self.queryCloudForRecords(recordIds: Array(recordsToUpdate.union(recordsToInsert)), completionBlock: { (records) in
            guard records.count != 0 else { return }
            
            recordsToInsert.forEach({ (recordToInsert) in
                guard let newRecord = records.first(where: { (record) -> Bool in
                    return record.recordID == recordToInsert
                }) else { return }
                self.addCloudRecordToLocalStorage(cloudKitRecord: newRecord)
            })
            
            recordsToUpdate.forEach({ (recordToUpdate) in
                guard let newRecord = records.first(where: { (record) -> Bool in
                    return record.recordID == recordToUpdate
                }) else { return }
                guard let localCopy = self.localCopyForCloudRecordWithId(recordToUpdate) else { return }
                
                self.updateLocalStorageWithCloudRecord(coreDataEntity: localCopy, cloudKitRecord: newRecord)
            })
            
            recordsToDelete.forEach({ (recordToDelete) in
                guard let localCopy = self.localCopyForCloudRecordWithId(recordToDelete) else { return }
                self.backgroundContext.delete(localCopy)
            })
            
            print("records inserted: \(recordsToInsert.count), records updated \(recordsToUpdate.count)")
            self.saveData(notifyUI: true)
        })
    }

    
    private func saveSubscription() {
        let subscription = CKQuerySubscription(recordType: "SignData",
                                               predicate: NSPredicate(value: true),
                                               options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion])
        
        publicDB.save(subscription) { (subscription, error) in
            //TODO: handle error cases
        }
    }
    
    
    // Saving/Restoring
    
    func saveData(notifyUI:Bool) {
        saveContext()
        if notifyUI {
            NotificationCenter.default.post(name: kNotificationReloadData, object: nil)
        }
    }
}
