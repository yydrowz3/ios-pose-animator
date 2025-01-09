//
//  DrawPose.swift
//  PoseEstimationTest
//
//  Created by 殷卓尔 on 2023/2/21.
//

import Foundation
import UIKit
//import Surge
import Upsurge

class PoseEstimate {
    
    let opencv = OpenCVWrapper()
    var heatRows = 0
    var heatColumns = 0
    
    let nmsThreshold = 0.1
    let localPAFThreshold = 0.1
    let pafCountThreshold = 5
    let partCountThreshold = 4.0
    let partScoreThreshold = 0.6

    init(_ imageWidth: Int,_ imageHeight: Int){
        heatRows = imageWidth / 8
        heatColumns = imageHeight / 8
    }


    func estimate_start(_ mm: [Double]) -> [Human] {
        
//        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 存储的是二维化的，每张图的宽和高展平了
        let separateLen = 19 * heatRows * heatColumns
//        var heatMat = Matrix<Double>(rows: 19, columns: heatRows*heatColumns, elements: Array<Double>(mm[0..<separateLen]))
        let pafMat = Matrix<Double>(rows: 38, columns: heatRows*heatColumns,
                                    elements: Array<Double>(mm[separateLen..<mm.count]))
        

        var pcmData = Array<Double>(mm[0..<separateLen])
        opencv.matrixMin(&pcmData, data_size: Int32(pcmData.count), data_rows: Int32(19), heat_rows: Int32(heatRows))
        // 这里也是展平的
        let pcmMat = Matrix<Double>(rows: 19, columns: heatRows*heatColumns, elements: pcmData )

//
//        heatMat = Matrix<Double>(
//            (0..<heatMat.rows).map({ heatMat.row($0) - min(heatMat.row($0)) }))
//
//        // Separate every 2116 (46 x 46) and find the minimum value
//        let q = ValueArray<Double>(capacity: heatMat.elements.count)
//
//        for i in 0..<heatMat.rows {
//            let a = Matrix<Double>(rows: heatRows, columns: heatColumns, elements: heatMat.row(i))
//            q.append(contentsOf:
//                ((0..<a.rows).map{ a.row($0) - min(a.row($0)) }).joined()
//            )
//        }
//        heatMat = q.toMatrix(rows: 19, columns: heatRows*heatColumns)


        // 对pcm热点图做非极大值抑制
//        var _nmsThreshold = max(mean(pcmData) * 4.0, nmsThreshold)
        var _nmsThreshold = max(mean(pcmMat.elements) * 4.0, nmsThreshold)
        _nmsThreshold = min(_nmsThreshold, 0.3)



        let coordinates: [[(Int, Int)]] = (0..<pcmMat.rows - 1).map { i in
            var nms = Array<Double>(pcmMat.row(i))
            nonMaxSuppression(&nms, dataRows: Int32(heatColumns), maskSize: 5, threshold: _nmsThreshold)
            return nms.enumerated().filter{ $0.1 > _nmsThreshold }.map { x in
                // 因为数组是被铺平了的一维向量，所以这里算出第几行第几列
                (x.0 / heatRows, x.0 % heatRows)
            }
        }

        // $0 为总的 $1 为当前的
        // 这边有错误应该是36，这边是47
        let pairsByConn = zip(CocoPairsInOutput, CocoPairInPAF).reduce(into: [Connection]()) {
            $0.append(contentsOf: scorePairs($1.0.0, $1.0.1, coordinates[$1.0.0], coordinates[$1.0.1], Array<Double>(pafMat.row($1.1.0)), Array<Double>(pafMat.row($1.1.1)), &pcmData, rescale: (1.0 / CGFloat(heatColumns), 1.0 / CGFloat(heatRows))))

        }

        var humans = pairsByConn.map{ Human([$0]) }
        if humans.count == 0 {
            return humans
        }


        while true {
            var items: (Int,Human,Human)!
            for x in combinations([[Int](0..<humans.count), [Int](1..<humans.count)]){
                if x[0] == x[1] {
                    continue
                }
                let k1 = humans[x[0]]
                let k2 = humans[x[1]]

                if k1.isConnected(k2){
                    items = (x[1],k1,k2)
                    break
                }
            }

            if items != nil {
                items.1.merge(items.2)
                humans.remove(at: items.0)
            } else {
                break
            }
        }


        // reject by subset count
        humans = humans.filter{ $0.partCount() >= pafCountThreshold }
        // reject by subset max score
        humans = humans.filter{ $0.getMaxScore() >= partScoreThreshold }

        return humans
        
//        let startTime4 = CFAbsoluteTimeGetCurrent()
//
//        let separateLen = 19*heatRows*heatColumns
//        let pafMat = Matrix<Double>(rows: 38, columns: heatRows*heatColumns,
//                                    grid: Array<Double>(mm[separateLen..<mm.count]))
//
//
//        var data = Array<Double>(mm[0..<separateLen])
//        opencv.matrixMin(
//            &data,
//            data_size: Int32(data.count),
//            data_rows: 19,
//            heat_rows: Int32(heatRows)
//        )
//
//        let heatMat = Matrix<Double>(rows: 19, columns: heatRows*heatColumns, grid: data )
//
//        let timeElapsed4 = CFAbsoluteTimeGetCurrent() - startTime4
//        print("init elapsed for \(timeElapsed4) seconds")
//
//        let startTime3 = CFAbsoluteTimeGetCurrent()
//
//        // print(sum(heatMat.elements)) // 810.501374994155
//        var _nmsThreshold = max(mean(data) * 4.0, nmsThreshold)
//        _nmsThreshold = min(_nmsThreshold, 0.3)
//
////        print(_nmsThreshold) // 0.0806388792154168
//
//        let coords : [[(Int,Int)]] = (0..<heatMat.rows-1).map { i in
//            var nms = Array<Double>(heatMat[i])
//            nonMaxSuppression(&nms, dataRows: Int32(heatColumns),
//                              maskSize: 5, threshold: _nmsThreshold)
//            return nms.enumerated().filter{ $0.1 > _nmsThreshold }.map { x in
//                return ( x.0 / heatRows , x.0 % heatRows )
//            }
//        }
//
//        let pairsByConn = zip(CocoPairsInOutput, CocoPairInPAF).reduce(into: [Connection]()) {
//            $0.append(contentsOf: scorePairs(
//                $1.0.0, $1.0.1,
//                coords[$1.0.0], coords[$1.0.1],
//                Array<Double>(pafMat[$1.1.0]), Array<Double>(pafMat[$1.1.1]),
//                &data,
//                rescale: (1.0 / CGFloat(heatColumns), 1.0 / CGFloat(heatRows))
//            ))
//        }
//
//        var humans = pairsByConn.map{ Human([$0]) }
//        if humans.count == 0 {
//            return humans
//        }
//
//        let timeElapsed3 = CFAbsoluteTimeGetCurrent() - startTime3
//        print("others elapsed for \(timeElapsed3) seconds")
//
//        let startTime = CFAbsoluteTimeGetCurrent()
//
//        while true {
//            var items: (Int,Human,Human)!
//            for x in combinations([[Int](0..<humans.count), [Int](0..<humans.count)]){
//                if x[0] == x[1] {
//                    continue
//                }
//                let k1 = humans[x[0]]
//                let k2 = humans[x[1]]
//
//                if k1.isConnected(k2){
//                    items = (x[1],k1,k2)
//                    break
//                }
//            }
//
//            if items != nil {
//                items.1.merge(items.2)
//                humans.remove(at: items.0)
//            } else {
//                break
//            }
//        }
//
//        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
//        print("human_roop Time elapsed for roop: \(timeElapsed) seconds")
//
//        // reject by subset count
//        humans = humans.filter{ $0.partCount() >= pafCountThreshold }
//
//        // reject by subset max score
//        humans = humans.filter{ $0.getMaxScore() >= partScoreThreshold }
//
//        return humans
        
    }




    func nonMaxSuppression(_ data: inout [Double], dataRows: Int32, maskSize: Int32, threshold: Double) {
        opencv.maximum_filter(&data, data_size: Int32(data.count), data_rows: dataRows, mask_size: maskSize, threshold: threshold)
    }


    func calcScore(_ x1: Int, _ y1: Int, _ x2: Int, _ y2: Int, _ pafMatX: [Double], _ pafMatY: [Double]) -> (Double, Int) {
        let __numInter = 10
        let __numInterF = Double(__numInter)

        let dx = Double(x2 - x1)
        let dy = Double(y2 - y1)
        // 两个点的距离
        let normVec = sqrt(dx * dx + dy * dy)

        if normVec < 1e-4 {
            return (0.0, 0)
        }

        // 单位向量，表示一个方向
        let vx = dx / normVec
        let vy = dy / normVec

        let xs = (x1 == x2) ? Array(repeating: x1, count: __numInter) : stride(from: Double(x1), to: Double(x2), by: Double(dx / __numInterF)).map { Int($0) }

        let ys = (y1 == y2) ? Array(repeating: y1 , count: __numInter) : stride(from: Double(y1), to: Double(y2), by: Double(dy / __numInterF)).map {Int($0)}

        var pafXs = Array<Double>(repeating: 0.0 , count: xs.count)
        var pafYs = Array<Double>(repeating: 0.0 , count: ys.count)
        // 行和列这里是反的
        for (idx, (mx, my)) in zip(xs, ys).enumerated(){
            pafXs[idx] = pafMatX[my*heatRows+mx]
            pafYs[idx] = pafMatY[my*heatRows+mx]
        }

        let localScores = pafXs * vx + pafYs * vy
        var thidxs = localScores.filter { $0 > localPAFThreshold }

        if (thidxs.count > 0) {
            thidxs[0] = 0.0
        }
        return (sum(thidxs), thidxs.count)
    }


    func scorePairs(_ partIdx1: Int, _ partIdx2: Int,
                    _ coordList1: [(Int,Int)], _ coordList2: [(Int,Int)],
                    _ pafMatX: [Double], _ pafMatY: [Double],
                    _ heatmap: inout [Double],
                    rescale: (CGFloat,CGFloat) = (1.0, 1.0)) -> [Connection] {

        // 先全联接
        var tempConnection = [Connection]()
        for (idx1,(y1,x1)) in coordList1.enumerated() {
            for (idx2,(y2,x2)) in coordList2.enumerated() {
                let (score, count) = calcScore(x1, y1, x2, y2, pafMatX, pafMatY)
                if count < pafCountThreshold || score <= 0.0 {
                    continue
                }

                tempConnection.append(Connection(score: score, partIdx1: partIdx1, partIdx2: partIdx2, idx1: idx1, idx2: idx2, coord1: (CGFloat(x1) * rescale.0, CGFloat(y1) * rescale.1), coord2: (CGFloat(x2) * rescale.0, CGFloat(y2) * rescale.1), score1: heatmap[partIdx1*y1*x1], score2: heatmap[partIdx2*y2*x2]))
            }
        }

        // 两个点之间只能有一条
        var connection = [Connection]()
        var usedIdx1 = [Int]()
        var usedIdx2 = [Int]()
        tempConnection.sorted { $0.score > $1.score }.forEach { conn in
            if usedIdx1.contains(conn.idx1) || usedIdx2.contains(conn.idx2) {
                return
            }
            connection.append(conn)
            usedIdx1.append(conn.idx1)
            usedIdx2.append(conn.idx2)
        }
        return connection
    }



    func combinations<T>(_ arr: [[T]]) -> [[T]] {
        return arr.reduce([[]]) {
            var x = [[T]]()
            for elem1 in $0 {
                for elem2 in $1 {
                    x.append(elem1 + [elem2])
                }
            }
            return x
        }
    }
}



