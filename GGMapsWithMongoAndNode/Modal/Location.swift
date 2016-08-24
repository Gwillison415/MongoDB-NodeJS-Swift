//
//  Location.swift
//  GGMapsWithMongoAndNode
//
//  Created by Tran Duc Trong on 8/16/16.
//  Copyright © 2016 TDT. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps


class Location: NSObject {
    
    var location: AnyObject!
    var categories:Array<AnyObject>!
    var id:String!
    
    var name:String!
    var placeName:String!
    var details:String!
    var image:UIImage!
    var configuredBySystem:Bool!
    
    var latitude:CLLocationDegrees!
    var imageId:String!
    
    
    
    override init() {
        super.init()
        self.categories = Array<AnyObject>()
        image = #imageLiteral(resourceName: "WhiteRectangle")
        details = ""
    }
    
    // MARK: - MKAnnotation
    
    private func title() -> String {
        return self.name as String
    }
    
    private func subtitle() -> String {
        return ((self.details != nil && details.characters.count > 0) ? self.details : self.placeName) as String
    }
    
    
    func setCoordinate(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.location = ["type": "Point", "coordinates": [longitude, latitude]]
        self.latitude = latitude
    }
    
    func setGeoJSON(geoPoint: AnyObject) {
        self.location = geoPoint
    }
    // MARK: - serialization
    
    init(dictionary: Dictionary<String, AnyObject>) {
        super.init()
        self.name = dictionary["name"] as! String
        self.placeName = dictionary["placename"]  as! String
        self.location = dictionary["location"]
        self.imageId = dictionary["imageId"]  as! String
        self.details = dictionary["details"]  as! String
        self.categories = dictionary["categories"] as! Array<Dictionary<String, AnyObject>>
    }
    
    func toDictionary() -> Dictionary<String, AnyObject> {
        var jsonable: Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()
        jsonable["name"] = self.name
        jsonable["placename"] = self.placeName
        jsonable["location"] = self.location
        jsonable["details"] = self.details
        jsonable["imageId"] = self.imageId
        jsonable["categories"] = self.categories
        return jsonable
    }
}
