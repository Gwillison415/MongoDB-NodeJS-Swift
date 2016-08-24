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
        do {
            //The image’s id is appended to the path along with the name of the endpoint: files.
            let url = URL(string: try URL(fileURLWithPath: URL(fileURLWithPath: kBaseURL).appendingPathComponent(kFiles).absoluteString!).appendingPathComponent(location.imageId).absoluteString!)!
            
            let config = URLSessionConfiguration.default()
            let session = URLSession(configuration: config)
            
            //The downloadTask is the third kind of NSURLSession, downloads a file to a temporary location and returns a URL to that location (rather than the raw NSData object, as the raw object can be rather large).
            let task = session.downloadTask(with: url, completionHandler: {(fileLocation: URL?, response: URLResponse?, error: NSError?) -> Void in
                if error == nil {
                    //The temporary location is only guaranteed to be available during the completion block’s execution
                    //so we must either load the file into memory, or move it somewhere else.
                    let imageData = NSData(contentsOf: fileLocation!)!
                    
                    let image = UIImage(data: imageData as Data)
                    if image == nil {
                        print("unable to build image")
                    }
                    location.image = image!
                    if (self.delegate != nil) {
                        self.delegate.modelUpdated()
                    }
                }
            })
            task.resume()
        } catch {
            print(error)
        }
    }
    
    func saveNewLocationImageFirst(location: Location) {
        do {
            //files endpoint
            let url = URL(string: try URL(fileURLWithPath: kBaseURL).appendingPathComponent(kFiles).absoluteString!)
            let request = NSMutableURLRequest(url: url!)
            
            //using POST triggers handleUploadRequest of fileDriver to save the file.
            request.httpMethod = "POST"
            
            //The Content-Type header is important for determining the file extension on the server.
            //Setting the content type ensures the file will be saved appropriately on the server.
            request.addValue("image/png", forHTTPHeaderField: "Content-Type")
            
            let config = URLSessionConfiguration.default()
            let session = URLSession(configuration: config)
            
            //turns an instance of UIImage into PNG file data.
            let bytes = UIImagePNGRepresentation(location.image)
            
            //Use uploadTask to send NSData to the server in the request itself.
            //For example, upload tasks automatically set the Content-Length header based on the data length.
            //Upload tasks also report progress and can run in the background, but neither of those features is used here.
            let task = session.uploadTask(with: request as URLRequest, from: bytes!, completionHandler: {(data: Data?, response: URLResponse?, error: NSError?) -> Void in
                do {
                    if (error == nil) && ((response as! HTTPURLResponse).statusCode < 300) {
                        let responseDict = try JSONSerialization.jsonObject(with: data!, options: [])
                        //The response contains the new file data entity => save _id along with the location object for later retrieval.
                        location.imageId = responseDict["_id"] as! String
                        
                        //Once the image is saved and _id recorded => the main Location entity can be saved to the server
                        self.persist(location: location)
                    }
                }
                catch {
                    print(error)
                }
            })
            task.resume()
        } catch {
            print(error)
        }
    }
    
    //Iterate through the array of JSON dictionaries and create a new Location object for each item.
    func parseAndAddLocations(locations: Array<AnyObject>, toArray destinationArray: inout Array<AnyObject>) {
        for item in locations {
            //Here you use a custom initializer to turn the deserialized JSON dictionary into an instance of Location.
            let location:Location = item as! Location
            destinationArray.append(location)
            
            //Checks for an imageId; if it finds one, it calls loadImage:.
            if (location.imageId != nil) {
                self.loadImage(location: location)
            }
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
    
//    func runQuery(queryString: String) {
//        
//    }
    
//    func queryRegion(region: MKCoordinateRegion) {
//    }
    
    //Implement the ability to save Locations to the database
    func persist(location: Location) {
        if location.name == nil || location.name.characters.count == 0 {
            //input safety check
            return
        }
        
        //If there is an image, save it first
        //If there is an image but no image id, then the image hasn’t been saved yet.
        if location.image != nil && location.imageId == nil {
            //Call the new method to save the image, and exits.
            self.saveNewLocationImageFirst(location: location)
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
