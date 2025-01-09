//
//  CameraViewController.swift
//  PoseEstimationTest
//
//  Created by 殷卓尔 on 2023/2/20.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    
    @IBOutlet weak var cameraView: UIImageView!
    
    @IBOutlet weak var maskView: UIImageView!
    @IBOutlet weak var cameraButtonOutlet: UIButton!
    
    @IBAction func cameraButton(_ sender: UIButton) {
        if self.isProcessing {
            processPowerOff()
        } else {
            processPowerOn()
        }
    }
    
    
    var canUseCamera: Bool = false
    var isProcessing: Bool = false
    
    
    
    var cameraSession: AVCaptureSession?
    var cameraDevice: AVCaptureDevice?
    var cameraInput: AVCaptureInput?
    var cameraVideoOutput =  AVCaptureVideoDataOutput()
    
//    let previewLayer = AVCaptureVideoPreviewLayer()
    
    
    // 模型
    var pose = Pose()
    
    // 相机数据处理
    //用于记录帧数
    var frameFlag: Int = 0
    //用于给异步线程加锁
    var lockFlagBool: Bool = false
    
    
    // 仅用于测试
//    var cnt = 0
    var startTime = CFAbsoluteTimeGetCurrent()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cameraCheck()
        if self.canUseCamera {
            print("here at viewdidload")
            cameraSetup()
            self.cameraView.image = nil
//            self.cameraView.layer.addSublayer(self.previewLayer)
        } else {
            print("viewdidload cannot use camera")
        }
        
        self.pose.maskFlag = true
//        self.pose.maskFlag = false
        
//        self.cameraView.isHidden = true
//        self.maskView.isHidden = true
        self.cameraButtonOutlet.isHidden = true
        
    }
    
    
    
    func processPowerOn() {
        DispatchQueue.main.async {
            self.cameraView.isHidden = false
            self.maskView.isHidden = false
        }
        self.isProcessing = true
    }
    
    func processPowerOff() {
        DispatchQueue.main.async {
            self.cameraView.isHidden = true
            self.maskView.isHidden = true
        }
        self.isProcessing = false
    }
    
    
    
    func cameraCheck() {
        var authFlag: Bool = false
        switch AVFoundation.AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                guard granted else {
                    return
                }
                authFlag = true
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            authFlag = true
        @unknown default:
            break
        }
        
        if authFlag == false {
            print("did not authorize camera")
//            showAlert(title: "alert", message: "did not authorize camera")
            return
        }
        
        
        self.cameraDevice = AVCaptureDevice.default(for: .video)
        if self.cameraDevice == nil {
            print("can not find camera")
//            showAlert(title: "alert", message: "can not find camera")
            return
        }
        
        self.canUseCamera = true
        self.cameraButtonOutlet.isHidden = false
        
        
        
        
    }
    
    
    func cameraSetup() {
        
        let session = AVCaptureSession()
        
        do {
            let input = try AVCaptureDeviceInput(device: self.cameraDevice!)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            if session.canAddOutput(self.cameraVideoOutput) {
                session.addOutput(self.cameraVideoOutput)
            }
            
//            self.previewLayer.frame = self.cameraView.bounds
//            self.previewLayer.videoGravity = .resizeAspectFill
//            self.previewLayer.session = session
            DispatchQueue(label: "cameraSession").async {
                session.startRunning()
            }
            self.cameraSession = session
            
            
            let videoDataOutputQueue = DispatchQueue(label: "videoDataOutputQueue")
            self.cameraVideoOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
            self.cameraVideoOutput.alwaysDiscardsLateVideoFrames = true // TODO:
//            self.cameraVideoOutput.alwaysDiscardsLateVideoFrames = false
//            let BGRA32PixelFormat = NSNumber(value: Int32(kCVPixelFormatType_32BGRA))
            let rgbOutputSetting = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            self.cameraVideoOutput.videoSettings = rgbOutputSetting
            
            guard let connection = self.cameraVideoOutput.connection(with: .video),
            connection.isVideoOrientationSupported else {return}
            connection.videoOrientation = .portrait
           
        } catch {
            print(error)
        }
        
    }
    
    
    
    
    
    // MARK: - Optional Helpers
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle:.alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        
        present(alert, animated: true)
    }
    
    
    
}


extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        print("hello world")
        if let image = sampleBuffer.imageWithCGImage(orientation: .up, scale: 1.0){
            
            let crop = image.imageByCroppingImage(size: CGSize(width: 736, height: 736))
//                .fixImageOrientation()
            
            
            self.frameFlag += 1
            if self.frameFlag != -1 {
                DispatchQueue.main.async {
                    self.cameraView.image = crop
                }
                
                if(self.lockFlagBool == false){
                    //此处必须开线程处理，否则会报错
                    DispatchQueue.global().async {
                        
                        self.lockFlagBool = true
                        
                        //addimageProcess为opencv图像处理过程，写在Objecj-C++文件中，本文后面记录
                        //                                        output = opencv_test.addimageProcess(output)
                        
                        let output = self.pose.runWithOptionalResult(crop)
//                        if output != nil {
//                            self.cnt = self.cnt + 1
//                            if self.cnt == 30 {
//                                print(CFAbsoluteTimeGetCurrent() - self.startTime)
//                            }
//                            print("OK")
//                        }
                        DispatchQueue.main.async {
                            self.maskView.image = output
                        }
                        
                        self.lockFlagBool = false
                    }
                }
            }
            
        } else {
            print("丢帧")
            self.frameFlag = 0
        }
        
        
        
        
        
    }
}


// 扩展CMSampleBuffer 提供图像转换功能
extension CMSampleBuffer {
    
    func imageWithCIImage(orientation: UIImage.Orientation = .up, scale: CGFloat = 1.0) -> UIImage? {
        if let buffer = CMSampleBufferGetImageBuffer(self) {
            let ciImage = CIImage(cvPixelBuffer: buffer)

            return UIImage(ciImage: ciImage, scale: scale, orientation: orientation)
        }
        
        

        return nil
    }

    func imageWithCGImage(orientation: UIImage.Orientation = .up, scale: CGFloat = 1.0) -> UIImage? {
        if let buffer = CMSampleBufferGetImageBuffer(self) {
            let ciImage = CIImage(cvPixelBuffer: buffer)

            let context = CIContext(options: nil)

            guard let cg = context.createCGImage(ciImage, from: ciImage.extent) else {
                return nil
            }
            
            return UIImage(cgImage: cg, scale: scale, orientation: orientation)
        }

        return nil
    }
}


// 扩展UIImage提供图片裁剪
extension UIImage {

     func imageByCroppingImage(size : CGSize) -> UIImage{
        let refWidth : CGFloat = CGFloat(self.cgImage!.width)
        let refHeight : CGFloat = CGFloat(self.cgImage!.height)
        let x = (refWidth - size.width) / 2
        let y = (refHeight - size.height) / 2
        let cropRect = CGRect(x: x, y: y, width: size.width, height: size.height)
        let imageRef = self.cgImage!.cropping(to: cropRect)
        let cropped : UIImage = UIImage(cgImage: imageRef!, scale: 0, orientation: self.imageOrientation)
        return cropped
    }
    
    func fixImageOrientation() -> UIImage {
        UIGraphicsBeginImageContext(self.size)
        self.draw(at: .zero)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
    
}
