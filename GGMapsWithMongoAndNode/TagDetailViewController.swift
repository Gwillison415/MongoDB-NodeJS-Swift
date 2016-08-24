//
//  TagDetailViewController.swift
//  GGMapsWithMongoAndNode
//
//  Created by Tran Duc Trong on 8/16/16.
//  Copyright © 2016 TDT. All rights reserved.
//

import UIKit

let kCategoryRow = 2

class TagDetailViewController: UITableViewController, CategoryDelegate {
    
    var location:Location!
    var picture:UIImage = #imageLiteral(resourceName: "WhiteRectangle")
    var homeView = ViewController()
    
    var isImageChanged:Bool = false
    
    let imagePicker: UIImagePickerController = UIImagePickerController()
    
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var detailTextLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleTextField.text = location.name
        descriptionTextField.text = location.details
        imageView.image = location.image
        if (self.location.categories.count != 0){
            detailTextLabel?.text = (self.location.categories as! [String]).joined(separator: ", ")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isMovingFromParentViewController() {
            self.persistLocation()
            homeView.recentLocation = self.location
        }
    }
    
    // MARK: - Model
    func persistLocation() {
        var modified: Bool = false
        if (self.location.name != self.titleTextField.text){
            self.location.name = self.titleTextField.text!
            modified = true
            }
        if (self.location.details != self.descriptionTextField.text){
            self.location.details = self.descriptionTextField.text!
            modified = true
        }
        if (isImageChanged == true) {
            self.location.image = self.picture
            modified = true
        }
        if (modified == true){
            print("okay, now it've been modified")
            self.location.configuredBySystem = false
            let appDelegate = UIApplication.shared().delegate as! AppDelegate
            appDelegate.locations.persist(location: self.location)
        }
    }
    
    //MARK - UIImagePickerController
    @IBAction func takePicture(_ sender: AnyObject) {
        imagePicker.delegate = self;
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
        }
        else {
            imagePicker.sourceType = .photoLibrary
        }
        self.present(self.imagePicker, animated: true, completion: nil)
    }
    
    
    //MARK - UITableViewController
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == kCategoryRow {
            let flvc: FilterListViewController = FilterListViewController(selectedCategories: self.location.categories, deleagte: self)
            self.navigationController!.pushViewController(flvc, animated: true)
        }
    }
    
    func selectedCategories(array: [AnyObject]) {
        self.location.categories = array
        
        detailTextLabel?.text = (self.location.categories as! [String]).joined(separator: ", ")
    }
}

//MARK - UIImagePickerController
extension TagDetailViewController:UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage{
            print("abcdefghijkl")
            self.picture = pickedImage
            self.imageView.image = pickedImage
            isImageChanged = true
        }
        self.dismiss(animated: true, completion: nil)
    }
}

