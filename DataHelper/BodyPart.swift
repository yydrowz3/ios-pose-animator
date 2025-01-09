//
//  BodyPart.swift
//  PoseEstimationTest
//
//  Created by 殷卓尔 on 2023/2/21.
//


class BodyPart {
    
    var uidx: String
    var partIdx: Int
    var x: CGFloat
    var y: CGFloat
    var score: Double
//    var name: String
    
    init(_ uidx: String,_ partIdx: Int,_ x: CGFloat,_ y: CGFloat,_ score: Double){
        self.uidx = uidx
        self.partIdx = partIdx
        self.x = x
        self.y = y
        self.score = score
//        self.name = String(format: "BodyPart:%d-(%.2f, %.2f) score=%.2f" , self.partIdx, self.x, self.y, self.score)
    }
}
