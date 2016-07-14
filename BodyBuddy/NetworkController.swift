//
//  NetworkController.swift
//  BodyBuddy
//
//  Created by Manuel Broncano Rodriguez on 7/13/16.
//  Copyright © 2016 Manuel Broncano Rodriguez. All rights reserved.
//

import Foundation
import UIKit
import CoreData

enum NetworkControllerError: ErrorType {
    case InvalidURL(String)
    case RequestError(ErrorType)
    case InvalidResponse(String)
    case MissingData
    case ParsingError
    case CoreDataError(String)
}

enum EntityClass: String {
    case Exercise
    case Language
    case WeightUnit
    case ExerciseCategory
}

let endpoint: [EntityClass: String] = [.Exercise: "exercise?language=2", .Language: "language", .WeightUnit: "weightunit"]

class NetworkController {
    // MARK: Singleton
    // note: this is implicitly lazy
    static var sharedInstance: NetworkController = {
        return NetworkController()
    }()


    // MARK: CoreData
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")!
        
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let persistentStoreCoordinator = self.persistentStoreCoordinator
        
        // Initialize Managed Object Context
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        
        // Configure Managed Object Context
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        // By default, overwrite the objects when i.e. there is a a unique constraint error
//        managedObjectContext.mergePolicy = NSOverwriteMergePolicy
        
        return managedObjectContext
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // Initialize Persistent Store Coordinator
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        // URL Documents Directory
        let URLs = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let applicationDocumentsDirectory = URLs.last! // [(URLs.count - 1)]
        
        // URL Persistent Store
        let URLPersistentStore = applicationDocumentsDirectory.URLByAppendingPathComponent("database.sqlite")
        
        do {
            // Add Persistent Store to Persistent Store Coordinator
            try persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: URLPersistentStore, options: nil)
            
        } catch {
            // Populate Error
            var userInfo = [String: AnyObject]()
            userInfo[NSLocalizedDescriptionKey] = "There was an error creating or loading the application's saved data."
            userInfo[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading the application's saved data."
            
            userInfo[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "CoreData", code: 1001, userInfo: userInfo)
            
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            
            abort()
        }
        
        return persistentStoreCoordinator
    }()
    
    // MARK: Data handing
    func mergeResults(entityClass: EntityClass, results: [[String: AnyObject]]) throws {
    
        // create temporary, subordinated context for the updates
        let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = self.managedObjectContext
    
        for result in results {
            // check if the entity is not duplicated
            let fetchRequest = NSFetchRequest(entityName: entityClass.rawValue)
            let predicate = NSPredicate(format: "id=%d", argumentArray: [result["id"]!])
            fetchRequest.predicate = predicate
            let fetchResults = try context.executeFetchRequest(fetchRequest)
            
            let object: NSManagedObject
            let entityDescription = NSEntityDescription.entityForName(entityClass.rawValue, inManagedObjectContext: context)
            if fetchResults.count == 0 {
                object = NSManagedObject(entity: entityDescription!, insertIntoManagedObjectContext: context)
            } else {
                object = fetchResults[0] as! NSManagedObject
            }
            
            if let attributes = entityDescription?.attributesByName {
                for (name, description) in attributes {
                    
                    // TODO: attr. mapping
                    var keyName = name
                    if name == "desc" {
                        keyName = "description"
                    }
                    
                    if let resultVal = result[keyName] {
                        switch description.attributeType {
                        case .ObjectIDAttributeType:
                            print("attribute not supported!")
                        default:
                            object.setValue(resultVal, forKey: name)
                        }
                    } else {
                        print("attribute <\(name)> not found!")
                    }
                }
            }
        }
        
        do {
            // this doesn't push the changes to disk, only to parent
            try context.save()
            
            // saves the changes to disk
            try self.managedObjectContext.save()
        } catch {
            print("Error: \(error)")
            context.reset()
        }
    }


    // MARK: Network
    let baseURL = NSURL(string: "http://wger.localhost:32768/api/v2/")!
    let token = "5c9b699ae4c71941bf9d770410dc4469f52a24f1"

    func retrieveData(endpoint endpoint: String, callback: ([[String: AnyObject]]) throws -> Void) {
        do {
            guard let url = NSURL(string: endpoint, relativeToURL: baseURL) else { throw NetworkControllerError.InvalidURL(endpoint) }
            
            retrieveData(URL: url, callback: callback)
        } catch {
            print(String(error))
        }
    }

    func retrieveData(URL URL: NSURL, callback: ([[String: AnyObject]]) throws -> Void) {
        print("retrieving: <\(URL)>")
        
        let request = NSMutableURLRequest(URL: URL)
        request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        
        let session = NSURLSession.sharedSession()
        let sessionDataTask = session.dataTaskWithRequest(request) { (data, response, error) in
            do {
                guard error == nil else { throw NetworkControllerError.RequestError(error!) }
                guard data != nil else { throw NetworkControllerError.MissingData }
                
                guard let jsonData =
                    try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? [String:AnyObject]
                    else { throw NetworkControllerError.ParsingError }
                
                if let httpResponse = response as? NSHTTPURLResponse {
                    guard httpResponse.statusCode == 200 else {
                        if let detail = jsonData["detail"] as? String {
                            throw NetworkControllerError.InvalidResponse(detail)
                        }
                        
                        throw NetworkControllerError.InvalidResponse("status: \(httpResponse.statusCode)")
                    }
                } else {
                    throw NetworkControllerError.InvalidResponse("Unknown response type")
                }
                
                guard let results = jsonData["results"] as? [[String: AnyObject]] else {
                    throw NetworkControllerError.InvalidResponse("Mssing response")
                }
                
                try callback(results)
                
                if let next = jsonData["next"] as? String {
                    if let URLComponents = NSURLComponents(string: next) {
                        // TODO: increase the limit
                        self.retrieveData(URL: URLComponents.URL!, callback: callback)
                    } else {
                        throw NetworkControllerError.InvalidURL(next)
                    }
                }
            } catch {
                // run in main thread
                /*
                dispatch_async(dispatch_get_main_queue(), {
                    let alert = UIAlertController(title: "Error", message: String(error), preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                })
                */
            }
        }
        sessionDataTask.resume()
    }
    
    func retrieveData(entityClass entityClass: EntityClass) {
        retrieveData(endpoint: endpoint[entityClass]!) { (results) in try self.mergeResults(entityClass, results: results) }
    }
    
    // MARK: NSFetchedResultsController
    func fetchedResultsController(entityClass entityClass: EntityClass, sortAttribute: String?) -> NSFetchedResultsController {
        // Initialize Fetch Request
        let fetchRequest = NSFetchRequest(entityName: entityClass.rawValue)
        
        // Add Sort Descriptors
        let sortDescriptor = NSSortDescriptor(key: sortAttribute, ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Initialize Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure Fetched Results Controller
//        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }
}