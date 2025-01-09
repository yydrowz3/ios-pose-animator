////
////  Human.swift
////  PoseEstimationTest
////
////  Created by 殷卓尔 on 2023/2/21.
////
//
//import Surge
//
//class Human {
//
//    var pairs : [Connection]
//    var bodyParts : [Int: BodyPart]
//    var uidxList: Set<String>
//
//    init(_ pairs: [Connection]) {
//        self.pairs = [Connection]()
//        self.bodyParts = [Int: BodyPart]()
//        self.uidxList = Set<String>()
//
//        for pair in pairs {
//            self.addPair(pair)
//        }
//    }
//
//    func getUidx(_ partIdx: Int,_ idx: Int) -> String {
//        return String(format: "%d-%d", partIdx, idx)
//    }
//
//    func addPair(_ pair: Connection) {
//        self.pairs.append(pair)
//
//        self.bodyParts[pair.partIdx1] = BodyPart(getUidx(pair.partIdx1, pair.idx1), pair.partIdx1, pair.coord1.0, pair.coord1.1, pair.score)
//
//        self.bodyParts[pair.partIdx2] = BodyPart(getUidx(pair.partIdx2, pair.idx2), pair.partIdx2, pair.coord2.0, pair.coord2.1, pair.score)
//
//        let uidx: [String] = [getUidx(pair.partIdx1, pair.idx1), getUidx(pair.partIdx2, pair.idx2)]
//        self.uidxList.formUnion(uidx)
//
//
//    }
//
//    // 合并其他
//    func mergeAnother(_ from: Human) {
//        for pair in from.pairs {
//            self.addPair(pair)
//        }
//    }
//
//    // 确认是否已有连接
//    func isConnected(_ target: Human) -> Bool {
//        self.uidxList.intersection(target.uidxList).count > 0
//    }
//
//    func partCount() -> Int {
//        self.bodyParts.count
//    }
//
//    func getMaxScore() -> Double {
////        return max(self.bodyParts.map{ $0.value.score })
//        let scoreArray: [Double] = self.bodyParts.map { $0.value.score }
//        let cnt = scoreArray.count
//        var tempMax: Double = -1
//        for i in 0..<cnt {
//            if i == 0 {
//                tempMax = scoreArray[i]
//            }
//            else {
//                if(scoreArray[i] > tempMax) {
//                    tempMax = scoreArray[i]
//                }
//            }
//        }
//
//        return tempMax
//    }
//
//}

class Human {
    
    var pairs : [Connection]
    var bodyParts : [Int: BodyPart]
    var uidxList: Set<String>
//    var name = ""
    
    init(_ pairs: [Connection]) {
        
        self.pairs = [Connection]()
        self.bodyParts = [Int: BodyPart]()
        self.uidxList = Set<String>()
        
        for pair in pairs {
            self.addPair(pair)
        }
//        self.name = (self.bodyParts.map{ $0.value.name }).joined(separator:" ")
    }
    func _getUidx(_ partIdx: Int,_ idx: Int) -> String {
        return String(format: "%d-%d", partIdx, idx)
    }
    func addPair(_ pair: Connection){
        self.pairs.append(pair)
        
        self.bodyParts[pair.partIdx1] = BodyPart(_getUidx(pair.partIdx1, pair.idx1),
                                                 pair.partIdx1,
                                                 pair.coord1.0, pair.coord1.1, pair.score)
        
        self.bodyParts[pair.partIdx2] = BodyPart(_getUidx(pair.partIdx2, pair.idx2),
                                                 pair.partIdx2,
                                                 pair.coord2.0, pair.coord2.1, pair.score)
        
        let uidx: [String] = [_getUidx(pair.partIdx1, pair.idx1),_getUidx(pair.partIdx2, pair.idx2)]
        self.uidxList.formUnion(uidx)
    }
    
    func merge(_ other: Human){
        for pair in other.pairs {
            self.addPair(pair)
        }
    }
    
    func isConnected(_ other: Human) -> Bool {
        return uidxList.intersection(other.uidxList).count > 0
    }
    func partCount() -> Int {
        return self.bodyParts.count
    }
    
    func getMaxScore() -> Double {
//        return max(self.bodyParts.map{ $0.value.score })
        let scoreArray: [Double] = self.bodyParts.map { $0.value.score }
        let cnt = scoreArray.count
        var tempMax: Double = -1
        for i in 0..<cnt {
            if i == 0 {
                tempMax = scoreArray[i]
            }
            else {
                if(scoreArray[i] > tempMax) {
                    tempMax = scoreArray[i]
                }
            }
        }
        
        return tempMax
    }
    
}
