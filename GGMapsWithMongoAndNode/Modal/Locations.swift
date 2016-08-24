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
    
    //Iterate through the array of JSON dictionaries and create a new Location object for each item.
    func parseAndAddLocations(locations: Array<AnyObject>, toArray destinationArray: inout Array<AnyObject>) {
        for item in locations {
            //Here you use a custom initializer to turn the deserialized JSON dictionary into an instance of Location.
            let location = item as! Dictionary<NSObject, AnyObject>
            destinationArray.append(location)
        }
        if (self.delegate != nil) {
            //The model signals the UI that there are new objects available.
            self.delegate.modelUpdated()
        }
    }
    
    func importSomething() {
        do {
            let url = URL(string: try URL(fileURLWithPath: kBaseURL).appendingPathComponent(kLocations).absoluteString!)
            let request = NSMutableURLRequest(url: url!)
            request.httpMethod = "GET"
            //"Accept" header use to determine type of response to send to the server
            //Returned bytes will be JSON instead of the default format of HTML
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            let config = URLSessionConfiguration.default()
            let session = URLSession(configuration: config)
            //Task for transferring data from a web service
            let dataTask = session.dataTask(with: request as URLRequest, completionHandler: {(data: Data?, response: URLResponse?, error: NSError?) -> Void in
                do {
                    if error == nil {
                        //deserialize the data
                        let responseArray = (try JSONSerialization.jsonObject(with: data!, options: [])) as! Array<AnyObject>
                        //Assuming the return value is an array of locations
                        //parses the objects and notifies the view controller with the updated data
                        
                        var objects = self.objects
                        self.parseAndAddLocations(locations: responseArray, toArray: &objects!)
                        self.objects = objects
                    }
                }
                catch {
                    print(error)
                }
            })
            //Start session
            dataTask.resume()
        } catch {
            print(error)
        }
    }
    
    func runQuery(queryString: String) {
    }
    
//    func queryRegion(region: MKCoordinateRegion) {
//    }
    
    func persist(location: Location) {
        if location.name == nil || location.name.characters.count == 0 {
            //input safety check
            return
        }
        do {
            let locations = try URL(fileURLWithPath: kBaseURL).appendingPathComponent(kLocations).absoluteString
            
            let isExistingLocation = location.id != nil
            
            //There are two endpoints for saving an object:
            // /locations when you’re adding a new location, and
            // /locations/_id when updating an existing location that already has an id
            let url = isExistingLocation ? try URL(string: URL(fileURLWithPath: locations!).appendingPathComponent(location.id).absoluteString!) : URL(string: locations!)
            
            let request = NSMutableURLRequest(url: url!)
            
            //The request uses either PUT for existing objects or POST for new objects.
            //The server code calls the appropriate handler for the route rather than using the default GET handler.
            request.httpMethod = isExistingLocation ? "PUT" : "POST"
            
            //Provide an HTTPBody in request which is an instance of NSData object created by the NSJSONSerialization class to updating entity
            let data = try JSONSerialization.data(withJSONObject: location.toDictionary(), options: [])
            
            request.httpBody = data
            
            //Tells the bodyParser on the server how to handle the bytes in the body
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let config = URLSessionConfiguration.default()
            let session = URLSession(configuration: config)
            let dataTask = session.dataTask(with: request as URLRequest, completionHandler: {(data: Data?, response: URLResponse?, error: NSError?) -> Void in
                do {
                    if error == nil {
                        //Takes the modified entity returned from the server, parses and adds it to the local collection of Location objects
                        let responseArray = [(try JSONSerialization.jsonObject(with: data!, options: []))]
                        var objects = self.objects
                        self.parseAndAddLocations(locations: responseArray, toArray: &objects!)
                        self.objects = objects
                    }
                }
                catch {
                    print(error)
                }
            })
            dataTask.resume()
        } catch {
            print(error)
        }
    }
    
}
