//
//  Categories.swift
//  GGMapsWithMongoAndNode
//
//  Created by Tran Duc Trong on 8/18/16.
//  Copyright © 2016 TDT. All rights reserved.
//

import Foundation
import UIKit

class Categories: NSObject{
    var categoryMeta:NSMutableDictionary!
    
    override init() {
        categoryMeta = NSMutableDictionary()
    }
    
    func allCategories() -> Array<AnyObject> {
        let defaultCategories: Array<AnyObject> = ["Park", "Museum", "Battlefield", "Lunch Spot"]
        let maxCategories:NSMutableSet = NSMutableSet(array: defaultCategories)
        maxCategories.addObjects(from: self.activeCategories())
        return maxCategories.allObjects
    }
    
    func activeCategories() -> [AnyObject] {
        let appDelegate = UIApplication.shared().delegate as! AppDelegate
        let locations = appDelegate.locations.filteredLocations()
        let a = locations.flatMap{$0["categories"]}
        let categorySet:NSMutableSet = NSMutableSet()
        for categories in a{
            categorySet.addObjects(from: categories as! [AnyObject])
        }
        return categorySet.allObjects
    }
}
