//
//  PhotoViewController.swift
//  PoseEstimationTest
//
//  Created by 殷卓尔 on 2023/2/20.
//

import UIKit
import PhotosUI

class PhotoViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var upperBarLabel: UILabel!
    @IBOutlet weak var imageLabel: UILabel!
    @IBOutlet weak var imageDisplay: UIImageView!
    @IBOutlet weak var imageSaveOutlet: UIButton!
    
    @IBAction func imageSaveAction(_ sender: UIButton) {
        if self.imageDisplay.image != nil {
            UIImageWriteToSavedPhotosAlbum(self.imageDisplay.image!, nil, nil, nil)
        }
        self.upperBarLabel.isHidden = false
        self.imageSaveOutlet.isHidden = true
    }
    
    //    var myPicker: PHPickerViewController? = nil
    var tempPicker = UIImagePickerController()
    let pose = Pose()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        createPicker()
        
        self.pose.actionFlag = true
        
    }
    
    
    func createPicker() -> Void {
//        var config = PHPickerConfiguration()
//        config.selectionLimit = 1
//        config.filter = .images
//        myPicker = PHPickerViewController(configuration: config)
//        myPicker!.delegate = self
        
        tempPicker.sourceType = .photoLibrary
        tempPicker.delegate = self
        
        
        
    }
    
    @IBAction func imageShowButton(_ sender: Any) {
//        print("Button Clicked!")
//        present(myPicker!, animated: true, completion: nil)
        present(tempPicker, animated: true)
        
        
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true)
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        
//        DispatchQueue.main.sync {
        self.imageDisplay.image = image
        self.pose.setRawImage(image)
        self.pose.coreMLOperate()
        self.imageDisplay.image = self.pose.getResult()
        
        self.imageLabel.isHidden = false
        self.imageLabel.text = String(format: "耗时: %.3f | %.3f s", self.pose.modelTime - self.pose.startTime, self.pose.endTime - self.pose.startTime)
        
        self.upperBarLabel.isHidden = true
        self.imageSaveOutlet.isHidden = false
        //        }
    }
        
    
//    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
//        picker.dismiss(animated: true)
//        for result in results {
//            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
//                result.itemProvider.loadObject(ofClass: UIImage.self) { reading, error in
//                    guard let image = reading as? UIImage, error == nil else {
//                        print("Error in loading Image in PhotoController")
//                        return
//                    }
//                    DispatchQueue.main.sync {
//
//                        self.imageDisplay.image = image
//                        let pose = Pose()
//                        pose.setRawImage(image)
//                        pose.coreMLOperate()
//                        self.imageDisplay.image = pose.getResult()
//
//                        self.imageLabel.isHidden = false
//                        self.imageLabel.text = String(format: "耗时: %.3f | %.3f ms", pose.modelTime - pose.startTime, pose.endTime - pose.startTime)
//
//                    }
//                }
//            }
//        }
//    }
    
    // image picker
    
    
    
    
}
