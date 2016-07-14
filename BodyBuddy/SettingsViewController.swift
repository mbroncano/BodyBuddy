//
//  ThirdViewController.swift
//  BodyBuddy
//
//  Created by Manuel Broncano Rodriguez on 7/13/16.
//  Copyright © 2016 Manuel Broncano Rodriguez. All rights reserved.
//

import UIKit
import CoreData

class SettingsViewController: UITableViewController {
    
    @IBOutlet weak var languageCell: UITableViewCell!
    @IBOutlet weak var unitsCell: UITableViewCell!
    
    var selectedLanguage: NSManagedObject? = nil
    
    @IBAction func selectLanguage(segue:UIStoryboardSegue) {
        let prevViewController = segue.sourceViewController as! SelectionTableViewController
        if let record = prevViewController.selected {
            selectedLanguage = record as? NSManagedObject
            NSUserDefaults.standardUserDefaults().setValue(selectedLanguage!.valueForKey("short_name"), forKeyPath: "lang")
        }
        
        configureCells()
    }

    func configureCells() {
        if let language = selectedLanguage {
            languageCell.detailTextLabel?.text = language.valueForKey("full_name") as? String
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print(sender)
        let nextViewController = segue.destinationViewController as! SelectionTableViewController
        let fetchedController = NetworkController.sharedInstance.fetchedResultsController(entityClass: .Language, sortAttribute: "short_name")

        nextViewController.fetchedResultsController = fetchedController
        nextViewController.selected = selectedLanguage
        nextViewController.navigationItem.title = "Language"
    }
    
    override func viewWillAppear(animated: Bool) {
        do {
            if let lang_code = NSUserDefaults.standardUserDefaults().valueForKey("lang") as? String {
                let fetchRequest = NSFetchRequest(entityName: EntityClass.Language.rawValue)
                fetchRequest.predicate = NSPredicate(format: "short_name == %@", lang_code)
                let languages = try NetworkController.sharedInstance.managedObjectContext.executeFetchRequest(fetchRequest)
                if languages.count > 0 {
                    selectedLanguage = languages[0] as? NSManagedObject
                }
            }
            
            configureCells()
        } catch {
            print(String(error))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        languageCell.detailTextLabel?.text = "<Unknown>"
        unitsCell.detailTextLabel?.text = "<Unknown>"

        NetworkController.sharedInstance.retrieveData(entityClass: .Language)
        NetworkController.sharedInstance.retrieveData(entityClass: .WeightUnit)
    }
}