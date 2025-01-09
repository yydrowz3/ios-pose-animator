//
//  File.swift
//  PoseEstimationTest
//
//  Created by 殷卓尔 on 2023/2/21.
//

import Foundation
import UIKit
import CoreML
//import Surge
import Vision



class Pose {
    
    let model: MobileOpenPose
    let imageWidth: Int
    let imageHeight: Int
    let finalSize: CGSize
    var rawImage: UIImage?
    var resImage: UIImage?
    
    var maskFlag: Bool = false
    var actionFlag: Bool = false
    
    var startTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    var modelTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    var endTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    
    init() {
        model = MobileOpenPose()
        imageWidth = 368
        imageHeight = 368
        finalSize = CGSize(width: self.imageWidth, height: self.imageHeight)
//        self.rawImage = raw
    }
    
    func ImageResize(_ image: UIImage, to newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return resizedImage
        
    }
    
    
    lazy var coreMLRequest: [VNRequest] = {
        do {
            let model = try VNCoreMLModel(for: self.model.model)
            let request = VNCoreMLRequest(model: model) { vnrequest, error in
                // 回调函数中获取处理的结果
                guard let ovservations = vnrequest.results as? [VNCoreMLFeatureValueObservation] else { fatalError("error at getting model results")}
                let mlarray = ovservations[0].featureValue.multiArrayValue!
                // 这里已经拿到MLMultiArray了 57*46*46
                let length = mlarray.count
                let doublePtr = mlarray.dataPointer.bindMemory(to: Double.self, capacity: length)
                let doubleBuffer = UnsafeBufferPointer(start: doublePtr, count: length)
                // 通过取地址拿到数据转换为数组
                let res = Array(doubleBuffer)
                
                self.modelTime = CFAbsoluteTimeGetCurrent()
                
                self.drawLines(res)
            }
            return [request]
        } catch {
            fatalError("fail to load Vision ML model: \(error)")
        }
    }()
    
    
    func drawLines(_ res: Array<Double>) {
        let openpose = PoseEstimate(imageWidth, imageHeight)
        let humans = openpose.estimate_start(res)
        
        
        var keypoints = [Int32]()
        var pos = [CGPoint]()
        
        var rectarrays = [Int32]()
        var actions = [Int32]()
        
        let humanNum = humans.count
//        print("humanNum")
//        print(humanNum)
        for human in humans {
            var centers = [Int: CGPoint]()
            var minLeft: Double = Double(imageWidth + 1)
            var maxRight: Double = -1
            var minTop: Double = Double(imageHeight + 1)
            var maxBottom: Double = -1
            for i in 0...CocoPart.Background.rawValue {
                if human.bodyParts.keys.firstIndex(of: i) == nil {
                    continue
                }
                let bodyPart = human.bodyParts[i]!
                
                centers[i] = CGPoint(x: bodyPart.x, y: bodyPart.y)
                if centers[i]!.x < minLeft {
                    minLeft = centers[i]!.x
                }
                if centers[i]!.x > maxRight {
                    maxRight = centers[i]!.x
                }
                if centers[i]!.y < minTop {
                    minTop = centers[i]!.y
                }
                if centers[i]!.y > maxBottom {
                    maxBottom = centers[i]!.y
                }
//                print(centers[i])
                
            }
            
//            print("--------------")
            actions.append(actionRecog(centers))
            
            rectarrays.append(Int32(minLeft * self.rawImage!.size.width))
            rectarrays.append(Int32(maxRight * self.rawImage!.size.width))
            rectarrays.append(Int32(minTop * self.rawImage!.size.height))
            rectarrays.append(Int32(maxBottom * self.rawImage!.size.height))
//            print("in human")
//            print(minLeft)
//            print(maxRight)
//            print(minTop)
//            print(maxBottom)
            
            for (pairOrder, (pair1,pair2)) in CocoPairsInRender.enumerated() {
                if human.bodyParts.keys.firstIndex(of: pair1) == nil || human.bodyParts.keys.firstIndex(of: pair2) == nil {
                    continue
                }
                if centers.index(forKey: pair1) != nil && centers.index(forKey: pair2) != nil{
                    keypoints.append(Int32(pairOrder))
                    pos.append(centers[pair1]!)
                    pos.append(centers[pair2]!)
                }
                
            }
        }
        
        let opencv = OpenCVWrapper()
        var uiImage: UIImage?
        if self.maskFlag {
            uiImage = opencv.renderMaskKeypoint(&keypoints, keypoint_size: Int32(keypoints.count), pos: &pos, rawImageWidth: Int32(self.rawImage!.size.width), rawImageHeight: Int32(self.rawImage!.size.height))
        } else {
            if self.actionFlag {
                uiImage = opencv.renderKeypointAction(&keypoints, keypoint_size: Int32(keypoints.count), pos: &pos, rawImage: self.rawImage, rectarray: &rectarrays, actions: &actions, humanNum: Int32(humanNum))
            }
            else {
                uiImage = opencv.renderKeypoint(&keypoints, keypoint_size: Int32(keypoints.count), pos: &pos, rawImage: self.rawImage)
            }
            
        }
        
        
        
        self.resImage = uiImage!
        
    }
    
    
    func coreMLOperate() {
        if self.rawImage == nil {
            print("do not have an input image!")
            return 
        }
        self.startTime = CFAbsoluteTimeGetCurrent()
//        let testImage = self.ImageResize(image, to: self.finalSize).cgImage!
        
//        print("before: ")
//        print(self.rawImage.size.width, self.rawImage.size.height)
//        let opencv = OpenCVWrapper()
//        let testImage = opencv.imageResize(withOpencv: self.rawImage, new_size: self.finalSize).cgImage!
//        print("after: ")
//        print(testImage.width, testImage.height)
        
        let testImage = OpenCVWrapper.imageResize(withOpencv: self.rawImage, new_size: self.finalSize).cgImage!
        
        
        let requestHandler = VNImageRequestHandler(cgImage: testImage, options: [:])
        do {
            try requestHandler.perform(self.coreMLRequest)
        } catch {
            print("error at calling coreML\(error)")
        }
        self.endTime = CFAbsoluteTimeGetCurrent()
    }
    
    func setRawImage(_ raw: UIImage) {
        self.rawImage = raw
    }
    
    func getResult() -> UIImage? {
//        if self.resImage == nil {
//            fatalError("Do not have a result image")
//        }
//        else {
//            return self.resImage
//        }
        return self.resImage
    }
    
    
    func runWithOptionalResult(_ raw: UIImage) -> UIImage? {
        self.rawImage = raw
        self.coreMLOperate()
        return self.resImage
    }
    
    
    
    func actionRecog(_ oriCenters: [Int:CGPoint]) -> Int32 {
        // 0: NoResult 1: stand 2: sit
        var centers = oriCenters
        
        if((centers[1] == nil) || (centers[8] == nil && centers[11] == nil) || (centers[9] == nil && centers[12] == nil)) {
            return 0
        }
        
        if(centers[8] == nil) {
            centers[8] = centers[11]
        } else if (centers[11] == nil) {
            centers[11] = centers[8]
        }
        
        if(centers[12] == nil) {
            centers[12] = centers[9]
        } else if(centers[9] == nil) {
            centers[9] = centers[12]
        }
        
        
        centers[1]!.x *= self.rawImage!.size.width
        centers[1]!.y *= self.rawImage!.size.height
        centers[8]!.x *= self.rawImage!.size.width
        centers[8]!.y *= self.rawImage!.size.height
        centers[11]!.x *= self.rawImage!.size.width
        centers[11]!.y *= self.rawImage!.size.height
        centers[9]!.x *= self.rawImage!.size.width
        centers[9]!.y *= self.rawImage!.size.height
        centers[12]!.x *= self.rawImage!.size.width
        centers[12]!.y *= self.rawImage!.size.height
        
        let neckToHip = abs((centers[8]!.y + centers[11]!.y) / 2 - centers[1]!.y)
        let hipToKnee = abs((centers[9]!.y + centers[12]!.y) / 2 - (centers[8]!.y + centers[11]!.y) / 2) + 1
        
//        print(neckToHip)
//        print(hipToKnee)
//        print(neckToHip / hipToKnee)
        
        let ratio = neckToHip / hipToKnee
        if (ratio > 1.73) {
            return 2
        } else {
            return 1
        }
        
    }
    
    
}





