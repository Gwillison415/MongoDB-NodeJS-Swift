//
//  ViewController.swift
//  GGMapsWithMongoAndNode
//
//  Created by Tran Duc Trong on 8/16/16.
//  Copyright © 2016 TDT. All rights reserved.
//


import UIKit
import GoogleMaps

let tagDetail = "tagDetail"
let darkBlueColor = UIColor(red: 0, green: 140.0/255.0, blue: 186.0/255.0, alpha: 1)
class ViewController: UIViewController {

    @IBOutlet weak var mapView: GMSMapView!
    
    var recentLocation:Location!
    
    var mapTasks = MapTasks()
    
    var arrLocation:Array<Location> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
    }

    @IBAction func addAnotation(_ sender: AnyObject) {
        let centerPoint = self.mapView.center
        let centerCoordinate: CLLocationCoordinate2D = self.mapView.projection.coordinate(for: centerPoint)
        self.addLocationAtCoordinate(coordinate: centerCoordinate)
    }
    
    func addLocationAtCoordinate(coordinate: CLLocationCoordinate2D) {
        var canIAddNewLocation:Bool = true
        for location in arrLocation{
            if (location.latitude == coordinate.latitude){
                canIAddNewLocation = false
                break
            }
        }
        if (canIAddNewLocation == true){
            self.mapTasks.geocodeAddress("\(coordinate.latitude), \(coordinate.longitude)", withCompletionHandler: { (status, success, fetchedFormattedAddress) -> Void in
                // Tìm kiếm thất bại
                if !success {
                    // Không tìm thấy kết quả
                    if status == ZERO_RESULTS {
                        self.showAlertWithMessage(ZERO_RESULTS)
                    }
                        // Địa chỉ không hợp lệ
                    else {
                        self.showAlertWithMessage(INVALID_ADDRESS)
                    }
                }
                    // Tìm kiếm thành công
                else {
                    let newLocation: Location = Location()
                    newLocation.placeName = fetchedFormattedAddress
                    newLocation.name = fetchedFormattedAddress
                    newLocation.setCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    newLocation.configuredBySystem = true
                    self.locations().addLocation(location: newLocation)
                    self.arrLocation.append(newLocation)
                    self.setupLocationMarker(coordinate)
                    self.recentLocation = newLocation
                    //                MBProgressHUD.hideAllHUDsForView(self.view!, animated: false)
                    self.performSegue(withIdentifier: tagDetail, sender: self)
                }
            })
        } else {
            showAlertWithMessage("Trùng!")
        }
    }
    
    func locations() -> Locations {
        let appDelegate = UIApplication.shared().delegate as! AppDelegate
        return appDelegate.locations
    }
    
    func setupLocationMarker(_ coordinate: CLLocationCoordinate2D) {
        let locationMarker: GMSMarker = GMSMarker(position: coordinate)
        
        locationMarker.infoWindowAnchor = CGPoint(x: 0.6, y: 0.32);
        
        locationMarker.icon = GMSMarker.markerImage(with: darkBlueColor)
        
        locationMarker.map = mapView
    }
    
    
    ///Hiện thông báo với tin nhắn là một chuỗi truyền vào
    func showAlertWithMessage(_ message: String) {
        let alertController = UIAlertController(title: message, message: "", preferredStyle: UIAlertControllerStyle.alert)
        let closeAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel, handler: nil)
        alertController.addAction(closeAction)
        present(alertController, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? TagDetailViewController{
            destination.location = self.recentLocation
            destination.homeView = self
        }
    }
}

extension ViewController: GMSMapViewDelegate{
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        marker.tracksInfoWindowChanges = true
        for i in 0..<arrLocation.count{
            if (arrLocation[i].latitude == marker.position.latitude){
                self.recentLocation = arrLocation[i]
            }
        }
        let infoWindow:CustomInfoMarker = Bundle.main().loadNibNamed("CustomInfoMarker", owner: self, options: nil)[0] as! CustomInfoMarker
        infoWindow.lblPlaceName.text = recentLocation.name
        infoWindow.lblPlaceDescription.text = recentLocation.details
        infoWindow.imgPlace.transform = CGAffineTransform(rotationAngle: -0.08)
        infoWindow.imgPlace.image = recentLocation.image
        
        return infoWindow
        
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        self.performSegue(withIdentifier: tagDetail, sender: self)
        mapView.selectedMarker = nil
    }
    
    
}

