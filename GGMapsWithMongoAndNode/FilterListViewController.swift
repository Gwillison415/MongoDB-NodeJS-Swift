//
//  FilterListViewController.swift
//  GGMapsWithMongoAndNode
//
//  Created by Tran Duc Trong on 8/18/16.
//  Copyright © 2016 TDT. All rights reserved.
//

import UIKit

protocol CategoryDelegate{
    func selectedCategories(array: [AnyObject])
}

class FilterListViewController: UITableViewController {
    
    var selections = Array<AnyObject>()
    var delegate:CategoryDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.title = "Choose categories"
    }
    
    
    convenience init(selectedCategories selections: [AnyObject], delegate delegate: CategoryDelegate) {
        self.init(style: .plain)
        self.delegate = delegate
        self.selections = selections
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.delegate.selectedCategories(array: self.selections)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    var categories = Categories()
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.allCategories().count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let category = categories.allCategories()[indexPath.row]
        
        cell.textLabel?.text = category as? String
        
        let isContain = self.selections.contains{$0 as! String == category as! String}
        if isContain{
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        cell.selectionStyle = .none

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category:String = categories.allCategories()[indexPath.row] as! String
        let on = self.selections.contains{$0 as! String == category}
        if on{
            let a = self.selections.index {$0 as! String == category}
            self.selections.remove(at: a!)
        } else {
            self.selections.append(category as AnyObject)
        }
        self.tableView.reloadRows(at: [indexPath as IndexPath], with: .automatic)
    }

}

extension Array where Element: Equatable {
    
    // Remove first collection element that is equal to the given `object`:
    mutating func removeObject(object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}
