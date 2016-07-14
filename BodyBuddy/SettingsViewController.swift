//
//  ThirdViewController.swift
//  BodyBuddy
//
//  Created by Manuel Broncano Rodriguez on 7/13/16.
//  Copyright © 2016 Manuel Broncano Rodriguez. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
    
    @IBOutlet weak var languageCell: UITableViewCell!
    @IBOutlet weak var unitsCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        languageCell.detailTextLabel?.text = "<Unknown>"
        unitsCell.detailTextLabel?.text = "<Unknown>"
        
        do {
//            NetworkController.sharedInstance.retrieveData(entityClass: .Language)
//            try self.fetchedResultsController.performFetch()
        } catch {
            print(String(error))
        }
    }
}