//
//  Locations.swift
//  GGMapsWithMongoAndNode
//
//  Created by Tran Duc Trong on 8/16/16.
//  Copyright © 2016 TDT. All rights reserved.
//

import Foundation
import GoogleMaps

let kBaseURL: String = "http://localhost:3000/"
let kLocations: String = "locations"
let kFiles: String = "files"

protocol LocationModelDelegate {
    func modelUpdated()
}

class Locations: NSObject {
    
    var objects:Array<AnyObject>!
    var delegate:LocationModelDelegate!
    
    override init() {
        super.init()
        self.objects = Array<AnyObject>()
    }
    
    func filteredLocations() -> Array<AnyObject> {
        return self.objects
    }
    
    func addLocation(location: Location) {
        self.objects.append(location)
    }
    
    func loadImage(location: Location) {
    }
    
    func parseAndAddLocations(locations: [AnyObject], toArray destinationArray: [AnyObject]) {
    }
    
    func importSomething() {
    }
    
    func runQuery(queryString: String) {
    }
    
//    func queryRegion(region: MKCoordinateRegion) {
//    }
    
    func persist(location: Location) {
    }
    
}
