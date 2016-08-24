//
//  MapTasks.swift
//  GMapsDemo
//
//  Created by Tran Duc Trong on 7/16/16.
//  Copyright © 2016 Appcoda. All rights reserved.
//

import UIKit
import GoogleMaps

let ZERO_RESULTS:String = "ZERO_RESULTS"
let NO_VALID_ADDRESS:String = "NO_VALID_ADDRESS"
let DESTINATION_IS_NIL:String = "DESTINATION_IS_NIL"
let ORIGIN_IS_NIL:String = "ORIGIN_IS_NIL"
let MAX_WAYPOINTS_EXCEEDED:String = "MAX_WAYPOINTS_EXCEEDED"
let INVALID_ADDRESS:String = "INVALID_ADDRESS"

class MapTasks: NSObject {
    /*---------------------------------------FIND AN ADDRESS-------------------------------------------------------*/
    ///Tạo request cho geocoding để lấy mã json về
    let baseURLGeocode = "https://maps.googleapis.com/maps/api/geocode/json?"
    
    //(có thể có nhiều cái, nhưng ở đây chỉ lưu 1 cái đầu tiên)
    ///Lưu dữ liệu đầu tiên được trả về
    var lookupAddressResults: Dictionary<NSObject, AnyObject>!
    
    ///Đầy đủ địa chỉ bằng ngôn ngữ tự nhiên
    var fetchedFormattedAddress: String!
    
    ///Kinh độ
    var fetchedAddressLongitude: Double!
    
    ///Vĩ độ
    var fetchedAddressLatitude: Double!
    
    override init() {
        super.init()
    }
    
    /**  **Thực hiện hàm này trước khi hiển thị kết quả lên bản đồ.**
     - Parameters:
      1. address: Địa chỉ muốn trỏ đến trên bản đồ
      2. completionHandler: Hàm được gọi sau khi đã nhận và xử lý dữ liệu nhận được với status là trạng thái trả về để hiện message, success là biến Boolean để thực hiện hàm theo 2 trường hợp true | false
     - [Geocoding's documentation](https://developers.google.com/maps/documentation/geocoding/intro)
     */
    func geocodeAddress(_ address: String, withCompletionHandler completionHandler: ((status: String, success: Bool, fetchedFormattedAddress:String) -> Void)) {
        //Kiểm tra xem address có phải là giá trị nil hay không
        if address != "" {
            //Chuyển dạng search, vì browser không nhận các ký tự đặc biệt nên sẽ chuyển về dạng URL hết, ví dụ "sài gòn" sẽ thành "sài%20gòn"
            let encodedHost = address.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlHostAllowed())
            
            // Chuyển về dạng URL đúng chuẩn của geocoding
            let geocodeURLString = baseURLGeocode + "address=" + encodedHost!
            let geocodeURL:URL = URL(string: geocodeURLString)!
            print("Find: \(geocodeURL)")
            
            DispatchQueue.main.async(execute: { () -> Void in
                // Gửi yêu cầu đến geocoding api và lưu dữ liệu trả về thành dạng NSData
                let geocodingResultsData:Data = try! Data(contentsOf: geocodeURL)
                do {
                    // Convert data về dạng json
                    let result = try JSONSerialization.jsonObject(with: geocodingResultsData, options: JSONSerialization.ReadingOptions.mutableContainers)
                    if let dictionary: Dictionary<NSObject, AnyObject> = result as? Dictionary<NSObject, AnyObject>{
                        // "status" là trạng thái lấy được dữ liệu hay không do Google đặt
                        if let status:String = dictionary["status"] as? String{
                            if status == "OK" {
                                // "results" là mảng json có thành phần là các địa chỉ của lookupAddress
                                if let allResults:Array<Dictionary<NSObject, AnyObject>> = dictionary["results"] as? Array<Dictionary<NSObject, AnyObject>>{
                                    //Lấy về kết quả đầu tiên (cái này custom được nè)
                                    self.lookupAddressResults = allResults[0]
                                    
                                    /* Giữ lại mấy cái dữ liệu quan trọng trong json của Google trả về */
                                    // "formatted_address" là chuỗi đầy đủ địa chỉ do Google đặt
                                    self.fetchedFormattedAddress = self.lookupAddressResults["formatted_address"] as! String
                                    
                                    // "geometry" là json chứa dữ liệu theo dạng reverse-geocoding (số liệu) do Google đặt
                                    let geometry = self.lookupAddressResults["geometry"] as! Dictionary<NSObject, AnyObject>
                                    
                                    // "location" là json chứa dữ liệu kinh độ, vĩ độ do Google đặt
                                    let location = geometry["location"] as! Dictionary<NSObject, AnyObject>
                                    
                                    // "lng" là kinh độ, "lat" là vĩ độ do Google đặt
                                    self.fetchedAddressLongitude = (location["lng"] as! NSNumber).doubleValue
                                    self.fetchedAddressLatitude = (location["lat"] as! NSNumber).doubleValue
                                    completionHandler(status: status, success: true, fetchedFormattedAddress: self.fetchedFormattedAddress)
                                }
                            }
                            else {
                                completionHandler(status: status, success: false, fetchedFormattedAddress: "")
                            }
                        }
                    }
                } catch {
                    print(error)
                    completionHandler(status: "", success: false, fetchedFormattedAddress: "")
                }
            })
        }
        else {
            completionHandler(status: NO_VALID_ADDRESS, success: false, fetchedFormattedAddress: "")
        }
    }
}
