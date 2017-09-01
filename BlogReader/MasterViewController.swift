//
//  MasterViewController.swift
//  BlogReader
//
//  Created by Henrik Gustavii on 13/08/2017.
//  Copyright © 2017 aecasorg. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var titleMaster: UINavigationItem!
    var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil
    


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        var message = ""
        
        if let url = URL(string: "http://opensource.googleblog.com/feeds/posts/default?alt=json") {
            
            let task = URLSession.shared.dataTask(with: url) {
                (data, response, error) in
                
                if error != nil {
                    
                    print(error)
                    
                } else {
                    
                    if let urlContent = data {
                        
                        var articleCount = 0
                        var blogArticleTitle = ""
                        var blogArticleContent = ""
                        var blogArticlePublished = ""
                        
                        do {
                            
                            let jsonResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String:Any]
                            
                            articleCount = ((jsonResult["feed"] as? [String:AnyObject])? ["entry"]  as? NSArray)?.count as Int!
                            
                            // print(jsonResult)
                            
                            // print(jsonResult["name"])
                            
//                            if let description = ((jsonResult["weather"] as? NSArray)?[0] as? NSDictionary)?["description"] as? String {
//                                
//                                message = "Description: " + description
//                                
//                            }
                            
                            
                            print(articleCount)
                            
                            if let title = ((jsonResult["feed"] as? [String:AnyObject])? ["title"] as? [String:AnyObject])? ["$t"] as? String {
                                
                                // message += "Title: " + title
                                print("--> \(title) <--")
                                DispatchQueue.main.sync(execute: {
                                    
                                    self.titleMaster.title = title
                                    
                                })
                                
                            } else {
                                
                                print("Blog title is misbehaving")
                                
                            }
                            
                            // Section deleting previous content from CoreData before populating DB again
                            let context = self.fetchedResultsController.managedObjectContext
                            
                            let request = NSFetchRequest<Event>(entityName: "Event")
                            
                            do {
                                
                                let results = try context.fetch(request)
                                
                                if results.count > 0 {
                                
                                    for result in results {
                                        
                                        context.delete(result)
                                        
                                        do {
                                            
                                            try context.save()
                                            
                                        } catch {
                                            
                                            print("Specific delete unaccomplished")
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            } catch {
                                
                                print("Delete utterly failed")
                                
                            }
                            
                            // Pulling JSON data from Google blogs
                            for i in 0..<articleCount {
                                
                                if let titleArticle = ((((jsonResult["feed"] as? [String:AnyObject])? ["entry"]  as? NSArray)?[i] as? NSDictionary)? ["title"] as? [String:AnyObject])? ["$t"] as? String {
                                    
                                    message += "\nArticle Title: " + titleArticle
                                    blogArticleTitle = titleArticle
                                    
                                } else {
                                    
                                    print("Article title is being naughty")
                                    
                                }
                            
                            
                                if let articleContent = ((((jsonResult["feed"] as? [String:AnyObject])? ["entry"]  as? NSArray)?[i] as? NSDictionary)? ["content"] as? [String:AnyObject])? ["$t"] as? String {
                                    
                                    message += "\nArticle Content: " + articleContent
                                    blogArticleContent = articleContent
                                    
                                } else {
                                    
                                    print("Article content is being rebellious")
                                    
                                }
                                
                                if let articlePublished = ((((jsonResult["feed"] as? [String:AnyObject])? ["entry"]  as? NSArray)?[i] as? NSDictionary)? ["published"] as? [String:AnyObject])? ["$t"] as? String {
                                    
                                    message += "\nArticle Published: " + articlePublished
                                    blogArticlePublished = articlePublished
                                    
                                } else {
                                    
                                    print("Article published date is ignoring me completely")
                                    
                                }
                                
                                let newEvent = Event(context: context)
                                
                                // Populating DB in CoreData.
                                newEvent.timestamp = NSDate()
                                newEvent.setValue(blogArticlePublished, forKey: "published")
                                newEvent.setValue(blogArticleTitle, forKey: "title")
                                newEvent.setValue(blogArticleContent, forKey: "content")

                                // Save the context.
                                do {
                                    try context.save()
                                } catch {
                                    // Replace this implementation with code to handle the error appropriately.
                                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                                    let nserror = error as NSError
                                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                                }
                            }
                            self.tableView.reloadData()
                            
                        } catch {
                            
                            print("JSON Processing just simply refuses to play ball")
                            
                        }
                    }
                    
                }
                
                DispatchQueue.main.sync(execute: {
                    
                    print(message)
                    
                })
                
            }
            
            task.resume()
            
        } else {
            
            print("The weather there (wherever 'there' is) could not be found. Please try again.")
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(_ sender: Any) {
        let context = self.fetchedResultsController.managedObjectContext
        let newEvent = Event(context: context)
             
        // If appropriate, configure the new managed object.
        newEvent.timestamp = NSDate()

        // Save the context.
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
            let object = fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let event = fetchedResultsController.object(at: indexPath)
        configureCell(cell, withEvent: event)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }

    func configureCell(_ cell: UITableViewCell, withEvent event: Event) {
        cell.textLabel!.text = event.value(forKey: "title") as? String
    }

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController<Event> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<Event> = Event.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "published", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
             // Replace this implementation with code to handle the error appropriately.
             // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             let nserror = error as NSError
             fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return _fetchedResultsController!
    }    
    var _fetchedResultsController: NSFetchedResultsController<Event>? = nil

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
            case .insert:
                tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            case .delete:
                tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            default:
                return
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                tableView.insertRows(at: [newIndexPath!], with: .fade)
            case .delete:
                tableView.deleteRows(at: [indexPath!], with: .fade)
            case .update:
                configureCell(tableView.cellForRow(at: indexPath!)!, withEvent: anObject as! Event)
            case .move:
                configureCell(tableView.cellForRow(at: indexPath!)!, withEvent: anObject as! Event)
                tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    /*
     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
     func controllerDidChangeContent(controller: NSFetchedResultsController) {
         // In the simplest, most efficient, case, reload the table view.
         tableView.reloadData()
     }
     */

}

