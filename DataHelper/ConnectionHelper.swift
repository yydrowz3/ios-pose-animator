//
//  ConnectionHelper.swift
//  PoseEstimationTest
//
//  Created by 殷卓尔 on 2023/2/22.
//
import Foundation
import UIKit


enum CocoPart: Int {
    case Nose = 0
    case Neck = 1
    case RShoulder = 2
    case RElbow = 3
    case RWrist = 4
    case LShoulder = 5
    case LElbow = 6
    case LWrist = 7
    case RHip = 8
    case RKnee = 9
    case RAnkle = 10
    case LHip = 11
    case LKnee = 12
    case LAnkle = 13
    case REye = 14
    case LEye = 15
    case REar = 16
    case LEar = 17
    case Background = 18
}



// 19个 最后两个是辅助用的
let CocoPairsInOutput = [
    (1, 2), (1, 5), (2, 3), (3, 4), (5, 6), (6, 7), (1, 8), (8, 9), (9, 10), (1, 11),
    (11, 12), (12, 13), (1, 0), (0, 14), (14, 16), (0, 15), (15, 17), (2, 16), (5, 17)
]

let CocoPairsInRender = CocoPairsInOutput[0..<CocoPairsInOutput.count-2]
// 19个 代表每种连接方式对于的两张PAF图
let CocoPairInPAF = [
(12, 13), (20, 21), (14, 15), (16, 17), (22, 23), (24, 25), (0, 1), (2, 3), (4, 5),
(6, 7), (8, 9), (10, 11), (28, 29), (30, 31), (34, 35), (32, 33), (36, 37), (18, 19), (26, 27)
]



extension UIColor {
    class func rgb(_ r: Int,_ g: Int,_ b: Int) -> UIColor{
        return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: 1)
    }
}

// 18个 代表18个肢体关键点
let CocoKeyColors = [UIColor.rgb(255, 0, 0),  UIColor.rgb(255, 85, 0), UIColor.rgb(255, 170, 0),UIColor.rgb(255, 255, 0),
                  UIColor.rgb(170, 255, 0),UIColor.rgb(85, 255, 0), UIColor.rgb(0, 255, 0),  UIColor.rgb(0, 255, 85),
                  UIColor.rgb(0, 255, 170),UIColor.rgb(0, 255, 255),UIColor.rgb(0, 170, 255),UIColor.rgb(0, 85, 255),
                  UIColor.rgb(0, 0, 255),  UIColor.rgb(85, 0, 255), UIColor.rgb(170, 0, 255),UIColor.rgb(255, 0, 255),
                  UIColor.rgb(255, 0, 170),UIColor.rgb(255, 0, 85)]




