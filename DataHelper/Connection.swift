//
//  Connection.swift
//  PoseEstimationTest
//
//  Created by 殷卓尔 on 2023/2/21.
//



//class Connection {
//    var score: Double
//    var idx1: Int
//    var idx2: Int
//    var partIdx1: Int
//    var partIdx2: Int
//    var coord1: (CGFloat,CGFloat)
//    var coord2: (CGFloat,CGFloat)
//    var score1: Double
//    var score2: Double
//    
//    init(score: Double,
//         partIdx1: Int,partIdx2: Int,
//         idx1: Int,idx2: Int,
//         coord1: (CGFloat,CGFloat),coord2:(CGFloat,CGFloat),
//         score1: Double,score2: Double) {
//        self.score = score
//        self.score1 = score1
//        self.score2 = score2
//        self.coord1 = coord1
//        self.coord2 = coord2
//        self.idx1 = idx1
//        self.idx2 = idx2
//        self.partIdx1 = partIdx1
//        self.partIdx2 = partIdx2
//    }
//}

struct Connection {
    var score: Double
    var idx1: Int
    var idx2: Int
    var partIdx1: Int
    var partIdx2: Int
    var coord1: (CGFloat,CGFloat)
    var coord2: (CGFloat,CGFloat)
    var score1: Double
    var score2: Double
    
    init(score: Double,
         partIdx1: Int,partIdx2: Int,
         idx1: Int,idx2: Int,
         coord1: (CGFloat,CGFloat),coord2:(CGFloat,CGFloat),
         score1: Double,score2: Double) {
        self.score = score
        self.score1 = score1
        self.score2 = score2
        self.coord1 = coord1
        self.coord2 = coord2
        self.idx1 = idx1
        self.idx2 = idx2
        self.partIdx1 = partIdx1
        self.partIdx2 = partIdx2
    }
}


