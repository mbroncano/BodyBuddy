//
//  SelectionTableViewController.swift
//  BodyBuddy
//
//  Created by Manuel Broncano Rodriguez on 7/14/16.
//  Copyright © 2016 Manuel Broncano Rodriguez. All rights reserved.
//

import UIKit
import CoreData

protocol SelectionTableItemProtocol: Equatable {
    var name: String { get }
}

class SelectionTableViewController: UITableViewController {

    var fetchedResultsController: NSFetchedResultsController? = nil
    var selected: AnyObject? = nil
    var selectedIndex: NSIndexPath? = nil

    // MARK: UITableViewDelegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let record = self.fetchedResultsController!.objectAtIndexPath(indexPath)
        print(record)
        
        selected = record
        selectedIndex = indexPath
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if let oldIndex = tableView.indexPathForSelectedRow {
            tableView.cellForRowAtIndexPath(oldIndex)?.accessoryType = .None
        }
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = .Checkmark
        
        return indexPath
    }

    // MARK: UITableViewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = self.fetchedResultsController!.sections {
            return sections.count
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = self.fetchedResultsController!.sections {
            return sections[section].numberOfObjects
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell")
        
        configureCell(cell!, atIndexPath: indexPath)
        
        return cell!
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath: NSIndexPath) {
        let record = self.fetchedResultsController!.objectAtIndexPath(atIndexPath)
        
        if let name = record.valueForKey("full_name") as? String {
            cell.textLabel?.text = name
        }
        
        if let desc = record.valueForKey("short_name") as? String {
            cell.detailTextLabel?.text = desc
        }
    }

    // MARK: NSFetchResultsControllerDelegate
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch (type) {
        case .Insert:
            if let indexPath = newIndexPath {
                tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
            break;
        case .Delete:
            if let indexPath = indexPath {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
            break;
        case .Update:
            if let indexPath = indexPath {
                let cell = tableView.cellForRowAtIndexPath(indexPath) //as UITableViewCell?
                configureCell(cell!, atIndexPath: indexPath)
            }
            break;
        case .Move:
            if let indexPath = indexPath {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
            
            if let newIndexPath = newIndexPath {
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
            }
            break;
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            try fetchedResultsController!.performFetch()
            
            if let selectedObject = selected {
                selectedIndex = fetchedResultsController?.indexPathForObject(selectedObject)
                tableView.selectRowAtIndexPath(selectedIndex, animated: false, scrollPosition: .Top)
                tableView(tableView, willSelectRowAtIndexPath: selectedIndex!)
                tableView(tableView, didSelectRowAtIndexPath: selectedIndex!)
            }
            
        } catch {
            print(String(error))
        }
        
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
//         self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
