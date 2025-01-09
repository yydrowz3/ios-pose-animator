//
//  VideoTools.swift
//  PoseEstimationTest
//
//  Created by 殷卓尔 on 2023/2/27.
//

import Foundation
import AVFoundation


class VideoTools {
    
    func getDeviceName() -> String {
        var size: Int = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        
        return String(cString:machine)
    }
    
    func resizeImage(image: UIImage, size: CGSize, keepAspectRatio: Bool = false, useToMakeVideo: Bool = false) -> UIImage {
        var targetSize: CGSize = size
        
        if useToMakeVideo {
            // Resize width to a multiple of 16.
            let resizeRate: CGFloat = CGFloat(Int(image.size.width) / 16) * 16 / image.size.width
            targetSize = CGSize(width: image.size.width * resizeRate, height: image.size.height * resizeRate)
        }
        
        var newSize: CGSize = targetSize
        var newPoint: CGPoint = CGPoint(x: 0, y: 0)
        
        if keepAspectRatio {
            if targetSize.width / image.size.width <= targetSize.height / image.size.height {
                newSize = CGSize(width: targetSize.width, height: image.size.height * targetSize.width / image.size.width)
                newPoint.y = (targetSize.height - newSize.height) / 2
            } else {
                newSize = CGSize(width: image.size.width * targetSize.height / image.size.height, height: targetSize.height)
                newPoint.x = (targetSize.width - newSize.width) / 2
            }
        }
        
//        UIGraphicsBeginImageContext(targetSize)
//        image.draw(in: CGRect(x: newPoint.x, y: newPoint.y, width: newSize.width, height: newSize.height))
//        let resizedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
//        UIGraphicsEndImageContext()
        
        let resizedImage: UIImage = OpenCVWrapper.imageResize(withOpencv: image, new_size: newSize)
        
        return resizedImage
    }
    
    
    func getPixelBufferFromCGImage(cgImage: CGImage) -> CVPixelBuffer {
        let width = cgImage.width
        let height = cgImage.height
        
        let options = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        var pxBuffer: CVPixelBuffer? = nil
        
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, options as CFDictionary?, &pxBuffer)
        CVPixelBufferLockBaseAddress(pxBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        let pxdata = CVPixelBufferGetBaseAddress(pxBuffer!)
        let bitsPerComponent: size_t = 8
        let bytesPerRow: size_t = 4 * width
        let rgbColorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(
            data: pxdata,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        
        context?.draw(cgImage, in: CGRect(x:0, y:0, width:CGFloat(width),height:CGFloat(height)))
        
        CVPixelBufferUnlockBaseAddress(pxBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pxBuffer!
    }
    
    
    func extractAudio(originalURL: URL) -> URL? {
        
        let composition = AVMutableComposition()
        do {
            let asset = AVURLAsset(url: originalURL)
            guard let audioAssetTrack = asset.tracks(withMediaType: AVMediaType.audio).first else { return nil }
            guard let audioCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { return nil }
            try audioCompositionTrack.insertTimeRange(audioAssetTrack.timeRange, of: audioAssetTrack, at: CMTime.zero)
        } catch {
            print(error)
        }
        
        // Get url for output
        let outputUrl = URL(fileURLWithPath: NSTemporaryDirectory() + "out.m4a")
        if FileManager.default.fileExists(atPath: outputUrl.path) {
            try? FileManager.default.removeItem(atPath: outputUrl.path)
        }
        
        // Create an export session
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)!
        exportSession.outputFileType = AVFileType.m4a
        exportSession.outputURL = outputUrl
        
        // Export file
        exportSession.exportAsynchronously {
            guard case exportSession.status = AVAssetExportSession.Status.completed else { return }

//            DispatchQueue.main.async {
//                // Present a UIActivityViewController to share audio file
//                guard let outputURL = exportSession.outputURL else { return }
//                let activityViewController = UIActivityViewController(activityItems: [outputURL], applicationActivities: [])
//                self.present(activityViewController, animated: true, completion: nil)
//            }
        }
        
        return exportSession.outputURL
        
    }
    
    func extractAudioTest(originalURL: URL) async throws -> URL? {
        let composition = AVMutableComposition()
        
        do {
            let asset = AVURLAsset(url: originalURL)
            guard let audioAssetTrack = try await asset.loadTracks(withMediaType: AVMediaType.audio).first else {return nil}
            guard let audioCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { return nil}
            
            let timerange = try await audioAssetTrack.load(.timeRange)
            
            try audioCompositionTrack.insertTimeRange(timerange, of: audioAssetTrack, at: CMTime.zero)
            
        } catch {
            print(error)
        }
        
        let outputUrl = URL(fileURLWithPath: NSTemporaryDirectory() + "out.m4a")
        if FileManager.default.fileExists(atPath: outputUrl.path) {
            try? FileManager.default.removeItem(atPath: outputUrl.path)
        }
        
        
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)!
        exportSession.outputFileType = AVFileType.m4a
        exportSession.outputURL = outputUrl
        
        
        await exportSession.export()
        
        if exportSession.status == .completed {
            return outputUrl
        }
        
        if let error = exportSession.error {
            throw error
        } else {
            fatalError("unknown error at exporting audio")
        }
        
        
    }
    
    
    
    enum VideoAudioMergeError: Error {
        case compositionAddVideoFailed, compositionAddAudioFailed, compositionAddAudioOfVideoFailed, unknownError
    }

    
    func mergeVideoAndAudio(videoUrl: URL,
                            audioUrl: URL,
                            shouldFlipHorizontally: Bool = false) async throws -> URL {
        
        let mixComposition = AVMutableComposition()
        var mutableCompositionVideoTrack = [AVMutableCompositionTrack]()
        var mutableCompositionAudioTrack = [AVMutableCompositionTrack]()
        var mutableCompositionAudioOfVideoTrack = [AVMutableCompositionTrack]()
        
        //start merge
        
        let aVideoAsset = AVAsset(url: videoUrl)
        let aAudioAsset = AVAsset(url: audioUrl)
        
        guard let compositionAddVideo = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw VideoAudioMergeError.compositionAddVideoFailed
        }
        
        guard let compositionAddAudio = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw VideoAudioMergeError.compositionAddAudioFailed
        }
        
        guard let compositionAddAudioOfVideo = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw VideoAudioMergeError.compositionAddAudioOfVideoFailed
        }
        
        do {
            let aVideoAssetTrack: AVAssetTrack = try await aVideoAsset.loadTracks(withMediaType: AVMediaType.video)[0]
            let aAudioOfVideoAssetTrack: AVAssetTrack? = try await  aVideoAsset.loadTracks(withMediaType: AVMediaType.audio).first
            let aAudioAssetTrack: AVAssetTrack = try await aAudioAsset.loadTracks(withMediaType: AVMediaType.audio)[0]
            
            // Default must have transformation
            compositionAddVideo.preferredTransform = try await aVideoAssetTrack.load(.preferredTransform)
            
            if shouldFlipHorizontally {
                // Flip video horizontally
                var frontalTransform: CGAffineTransform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                let naturalSize = try await aVideoAssetTrack.load(.naturalSize)
                frontalTransform = frontalTransform.translatedBy(x: -naturalSize.width, y: 0.0)
                frontalTransform = frontalTransform.translatedBy(x: 0.0, y: -naturalSize.width)
                compositionAddVideo.preferredTransform = frontalTransform
            }
            
            mutableCompositionVideoTrack.append(compositionAddVideo)
            mutableCompositionAudioTrack.append(compositionAddAudio)
            mutableCompositionAudioOfVideoTrack.append(compositionAddAudioOfVideo)
            
            let videoTimeRange = try await aVideoAssetTrack.load(.timeRange)
            
            try mutableCompositionVideoTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: videoTimeRange.duration),of: aVideoAssetTrack,at: CMTime.zero)
            
            //In my case my audio file is longer then video file so i took videoAsset duration
            //instead of audioAsset duration
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: videoTimeRange.duration), of: aAudioAssetTrack, at: CMTime.zero)
            
            // adding audio (of the video if exists) asset to the final composition
            if let aAudioOfVideoAssetTrack = aAudioOfVideoAssetTrack {
                try mutableCompositionAudioOfVideoTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: videoTimeRange.duration), of: aAudioOfVideoAssetTrack, at: CMTime.zero)
            }
        } catch {
            throw error
        }
        
        
        // Exporting
//        let savePathUrl: URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/newVideo.mp4")
        let savePathUrl: URL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(NSUUID().uuidString).mp4")!
//        do { // delete old video
//            try FileManager.default.removeItem(at: savePathUrl)
//        } catch { print(error.localizedDescription) }
        
        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)!
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = savePathUrl
        assetExport.shouldOptimizeForNetworkUse = true
        
        await assetExport.export()
        
        if assetExport.status == .completed {
            return savePathUrl
        }
        
        if let error = assetExport.error {
            throw error
        } else {
            throw VideoAudioMergeError.unknownError
        }
    }
    
    
    
    
    
    func mergeVideoAndAudioTest(videoUrl: URL,
                            audioUrl: URL,
                            shouldFlipHorizontally: Bool = false) throws -> URL {
        
        let mixComposition = AVMutableComposition()
        var mutableCompositionVideoTrack = [AVMutableCompositionTrack]()
        var mutableCompositionAudioTrack = [AVMutableCompositionTrack]()
        var mutableCompositionAudioOfVideoTrack = [AVMutableCompositionTrack]()
        
        //start merge
        
        let aVideoAsset = AVAsset(url: videoUrl)
        let aAudioAsset = AVAsset(url: audioUrl)
        
        guard let compositionAddVideo = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw VideoAudioMergeError.compositionAddVideoFailed
        }
        
        guard let compositionAddAudio = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw VideoAudioMergeError.compositionAddAudioFailed
        }
        
        guard let compositionAddAudioOfVideo = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw VideoAudioMergeError.compositionAddAudioOfVideoFailed
        }
        
        do {
            let aVideoAssetTrack: AVAssetTrack = try aVideoAsset.tracks(withMediaType: AVMediaType.video)[0]
            let aAudioOfVideoAssetTrack: AVAssetTrack? = try  aVideoAsset.tracks(withMediaType: AVMediaType.audio).first
            let aAudioAssetTrack: AVAssetTrack = try  aAudioAsset.tracks(withMediaType: AVMediaType.audio)[0]
            
            // Default must have transformation
            compositionAddVideo.preferredTransform = try aVideoAssetTrack.preferredTransform
            
            if shouldFlipHorizontally {
                // Flip video horizontally
                var frontalTransform: CGAffineTransform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                let naturalSize = try aVideoAssetTrack.naturalSize
                frontalTransform = frontalTransform.translatedBy(x: -naturalSize.width, y: 0.0)
                frontalTransform = frontalTransform.translatedBy(x: 0.0, y: -naturalSize.width)
                compositionAddVideo.preferredTransform = frontalTransform
            }
            
            mutableCompositionVideoTrack.append(compositionAddVideo)
            mutableCompositionAudioTrack.append(compositionAddAudio)
            mutableCompositionAudioOfVideoTrack.append(compositionAddAudioOfVideo)
            
            let videoTimeRange = try aVideoAssetTrack.timeRange
            
            try mutableCompositionVideoTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: videoTimeRange.duration),of: aVideoAssetTrack,at: CMTime.zero)
            
            //In my case my audio file is longer then video file so i took videoAsset duration
            //instead of audioAsset duration
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: videoTimeRange.duration), of: aAudioAssetTrack, at: CMTime.zero)
            
            // adding audio (of the video if exists) asset to the final composition
            if let aAudioOfVideoAssetTrack = aAudioOfVideoAssetTrack {
                try mutableCompositionAudioOfVideoTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: videoTimeRange.duration), of: aAudioOfVideoAssetTrack, at: CMTime.zero)
            }
        } catch {
            throw error
        }
        
        
        // Exporting
//        let savePathUrl: URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/newVideo.mp4")
        let savePathUrl: URL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(NSUUID().uuidString).mp4")!
        do { // delete old video
            try FileManager.default.removeItem(at: savePathUrl)
        } catch { print(error.localizedDescription) }
        
        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)!
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = savePathUrl
        assetExport.shouldOptimizeForNetworkUse = true
        
//        await assetExport.export()
        assetExport.exportAsynchronously {
            switch assetExport.status {
            case .failed:
                if let error = assetExport.error {
                    print("error")
                    print(error)
                }
                
            case .cancelled:
                if let error = assetExport.error {
                    print("cancelled")
                    print(error)
                }
                
            default:
                print("finished")
            }
            print("at export")
        }
        print(assetExport.status)
        
//        if assetExport.status == .completed {
//            return savePathUrl
//        }
//
//        if let error = assetExport.error {
//            throw error
//        } else {
//            throw VideoAudioMergeError.unknownError
//        }
        
        return savePathUrl
        
    }
    
    
    
    
}
