//
//  VideoViewController.swift
//  PoseEstimationTest
//
//  Created by 殷卓尔 on 2023/2/20.
//

import UIKit
import AVFoundation
import Vision
import Photos
import AVKit


class VideoViewController: UIViewController {
    
    // MARK: storyboard
    
    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var previewView: UIImageView!
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    
    @IBOutlet weak var progressView: UIProgressView!
    
    @IBOutlet weak var captureButton: UIButton!
    @IBAction func tappedCaptureButton(_ sender: UIButton) {
        if self.isCompleted == false || self.m_inputURL == nil || self.m_outputURL == nil{
            showAlert(title: "提示", message: "视频正在处理中，稍等")
            return
        }
        
        self.cameraView.image = nil
        
        if self.m_finalURL == nil {
            Task {
                do {
//                    let audiourl = try await self.tools.extractAudioTest(originalURL: self.m_inputURL!)
                    
//                    let tempurl = try await self.tools.mergeVideoAndAudio(videoUrl: self.m_outputURL!, audioUrl: audiourl!)
                    let tempurl = self.m_outputURL!
                    print("hi")
                    print(tempurl)
                    self.m_finalURL = tempurl
                    
                    self.playVideo(tempurl)
                    
                } catch {
                    print(error)
                    fatalError("error at converting video")
                }
            }
            
        } else {
            self.playVideo(self.m_finalURL!)
        }
        self.saveButton.isHidden = false
        self.messageLabel.isHidden = true
        
    }
    @IBOutlet weak var selectButton: UIButton!
    @IBAction func tappedSelectButton(_ sender: UIButton) {
        selectVideo()
    }
    
    
    @IBOutlet weak var saveButton: UIButton!
    
    @IBAction func tappedSaveButton(_ sender: UIButton) {
        
        if self.m_finalURL == nil {
            showAlert(title: "提示", message: "视频正在转换中")
        }
        else {
            moveVideoToPhotoLibrary(self.m_finalURL!)
            showAlert(title: "OK", message: "已加入相册")
            self.cameraView.layer.sublayers?.removeAll()
            self.saveButton.isHidden = true
            self.captureButton.isHidden = true
            self.messageLabel.text = "从相册中选择视频"
            self.messageLabel.isHidden = false
            self.updateSelectButton()
//            self.selectButton.isHidden = false
            
            
            do { // 清理
                try FileManager.default.removeItem(at: self.m_outputURL!)
                try FileManager.default.removeItem(at: self.m_finalURL!)
            } catch { print(error.localizedDescription) }
            self.m_inputURL = nil
            self.m_outputURL = nil
            self.m_finalURL = nil
        }
        
    }
    
    
    // MARK: 变量
    let imageSize = 368
    
    var deviceType: UIUserInterfaceIdiom?
    var isIPhoneX: Bool = false
    
    var canUseCamera: Bool?
    var canUsePhotoLibrary: Bool?
    
    let tools = VideoTools()
//    let modelCoreML = MobileOpenPose()
    
    
    // 用于捕获
    var captureSession = AVCaptureSession()
    var captureDevice: AVCaptureDevice?
    let videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
    var cameraLayer: AVCaptureVideoPreviewLayer!
    let fileOutput = AVCaptureMovieFileOutput()
    var isRecording = false
    
    // 用于相册中选择
    var selectedFileURL: URL?
    
    // 用于处理
    var editingImage: UIImage?
    // 指定模型的输入
    let targetImageSize = CGSize(width: 368, height: 368) // 必须一致
    let ciContext = CIContext()
    var resultBuffer: CVPixelBuffer?
    let pose = Pose()
    
    // 用于测试
    var cnt: Int = 0
    var urlfirst: URL?
    
    var isCompleted: Bool = false
    var m_inputURL: URL?
    var m_outputURL: URL?
    var m_finalURL: URL?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        deviceType = UIDevice.current.userInterfaceIdiom
        guard deviceType == .phone || deviceType == .pad else {
            fatalError("ERROR: Invalid device.")
        }

        let deviceName = tools.getDeviceName()
        if deviceType == .phone && deviceName.range(of: "iPhone10") != nil {
            isIPhoneX = true
        }
        
//        progressView.transform = CGAffineTransform(scaleX: 1.0, y: 3.0)
//
//        cameraLayer = AVCaptureVideoPreviewLayer(session: self.captureSession) as AVCaptureVideoPreviewLayer
//        cameraLayer.frame = self.view.bounds
//        cameraLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
//        cameraView.layer.addSublayer(cameraLayer)
        
        messageLabel.text = String(format: "从相册中选择视频")
        
        captureButton.layer.borderColor = UIColor.gray.cgColor
        captureButton.layer.borderWidth = 3
        

        
//        AVCaptureDevice.requestAccess(for: AVMediaType.video) {response in
//            if response {
//                self.canUseCamera = true
//                DispatchQueue.main.async {
//                    self.captureButton.isHidden = false
//                }
//                self.setupCamera()
//            } else {
//                self.canUseCamera = false
//            }
//        }
        
    
        
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            if status == .authorized {
                self.canUsePhotoLibrary = true
                self.updateSelectButton()
            } else {
                self.canUsePhotoLibrary = false
                DispatchQueue.main.async {
                    self.captureButton.isHidden = true
                }
                self.navigationController?.popViewController(animated: true)
            }
        }
        
        
        
        
    }
    

    

    
    // MARK: - preparations
    
    
    func setupCamera() {
        let deviceDiscovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back)
        
        if let device = deviceDiscovery.devices.last {
            captureDevice = device
            
            beginSession()
        }
    }
    
    func beginSession() {
        let videoInput = try? AVCaptureDeviceInput(device: videoDevice!) as AVCaptureDeviceInput
        
        captureSession.addInput(videoInput!)
        captureSession.addOutput(fileOutput)
        
        if deviceType == .phone {
            captureSession.sessionPreset = .hd1920x1080
        } else {
            captureSession.sessionPreset = .vga640x480
        }
        
        // 启动录制，不是开始录制
        captureSession.startRunning()
    }
    
    // MARK: - 主要功能
    
    func startDetecting(_ inputURL: URL) -> URL? {
        
        self.isCompleted = false
        
        
        let outputURL: URL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(NSUUID().uuidString).mov")!
        
        // 记录输入输出
        self.m_inputURL = inputURL
        self.m_outputURL = outputURL
        
        
        guard let videoWriter = try? AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mov) else {
            fatalError("ERROR: failed to construct AVAssetwriter.")
        }
        
        
        let avAsset = AVURLAsset(url: inputURL)
        
        let composition = AVVideoComposition(asset: avAsset, applyingCIFiltersWithHandler: {request in})
        let track = avAsset.tracks(withMediaType: AVMediaType.video)
        
//        let track = avAsset.tracks(withMediaType: AVMediaType.video)
        guard let media = track[0] as AVAssetTrack? else {
            fatalError("ERROR: There is no video track. ")
        }
        
        
        
        
        DispatchQueue.main.async {
            self.messageLabel.isHidden = true
            self.captureButton.isHidden = true
            self.selectButton.isHidden = true
            self.progressLabel.text = "处理中...(0%)"
            self.progressLabel.isHidden = false
            self.progressView.setProgress(0.0, animated: false)
            self.progressView.isHidden = false
            
            //  清除预览
            self.cameraView.layer.sublayers?.removeAll()
            self.cameraView.isHidden = true
        }
        
        
        let naturalSize: CGSize = media.naturalSize
        let preferedTransform: CGAffineTransform = media.preferredTransform
        let size = naturalSize.applying(preferedTransform)
        let width = abs(size.width)
        let height = abs(size.height)
        
        let outputSettings = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ] as [String: AnyObject]
        
        
        let writerInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings as [String : AnyObject])
        videoWriter.add(writerInput)
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height,
            ]
        )
        
        
        
        writerInput.expectsMediaDataInRealTime = true
        
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: CMTime.zero)
        
        let generator = AVAssetImageGenerator(asset: avAsset)
        // Settings to get captures of all frames.
        // Without these settings, you can only get captures of integral seconds.
        // 获取具体的视频时间的帧
        generator.requestedTimeToleranceAfter = CMTime.zero
        generator.requestedTimeToleranceBefore = CMTime.zero
        
        var buffer: CVPixelBuffer? = nil
        var frameCount = 0
        let durationForEachImage = 1
        
        let length: Double = Double(CMTimeGetSeconds(avAsset.duration))
        let fps: Int = Int(1 / CMTimeGetSeconds(composition.frameDuration))
        
        DispatchQueue.global().async {
//            DispatchQueue.main.async {
//                self.cameraView.isHidden = true
//            }
            
            for i in stride(from: 0, to: length, by: 1.0 / Double(fps)) {
                autoreleasepool {
                    // Capture an image from the video file.
                    let capturedImage : CGImage! = try? generator.copyCGImage(at: CMTime(seconds: i, preferredTimescale : 600), actualTime: nil)
                    
//                    print(img.size.height)
//                    print(img.size.width)
                    
                    var orientation: UIImage.Orientation
                    // Rotate the captured image.
                    if preferedTransform.tx == naturalSize.width && preferedTransform.ty == naturalSize.height {
                        orientation = UIImage.Orientation.down
                    } else if preferedTransform.tx == 0 && preferedTransform.ty == 0 {
                        orientation = UIImage.Orientation.up
                    } else if preferedTransform.tx == 0 && preferedTransform.ty == naturalSize.width {
                        orientation = UIImage.Orientation.left
                    } else {
                        orientation = UIImage.Orientation.right
                    }
                    
//                    let tmpImageToEdit = UIImage(cgImage: capturedImage, scale: 1.0, orientation: orientation)
//                    print(tmpImageToEdit.size.width)
//                    print(tmpImageToEdit.size.height)
//                    print("--------")
                    


                    let tmpImageToDetect: UIImage = UIImage(cgImage: capturedImage)
//                    let bufferToDetect = self.uiImageToPixelBuffer(tmpImageToDetect, targetSize: self.targetImageSize, orientation: orientation)!
                    
                    // 图片进入模型
                    
                    self.pose.setRawImage(tmpImageToDetect)
                    self.pose.coreMLOperate()
                    
                    
                    var resultImgBuffered: CVPixelBuffer?
                    while true {
                        if self.pose.resImage != nil {
                            var resultImg = self.pose.resImage!
                            
                            //获取一张预览图
                            if i == 0 {
//                                self.testPreview = resultImg
//                                self.cameraView.image = resultImg
                            }
                            
                            self.editingImage = resultImg
                            self.pose.resImage = nil
                            //写成视频的文件长和宽必须是16的倍数，否则视频就distorted了
                            resultImg = self.tools.resizeImage(image: resultImg, size: resultImg.size, useToMakeVideo: true)
                            resultImgBuffered = self.tools.getPixelBufferFromCGImage(cgImage: resultImg.cgImage!)
                            break
                        }
                    }
                    
                    
                    let frameTime: CMTime = CMTimeMake(value: Int64(__int32_t(frameCount) * __int32_t(durationForEachImage)), timescale: __int32_t(fps))
                    
                    
                    // Repeat until the adaptor is ready.
                    while true {
                        if (adaptor.assetWriterInput.isReadyForMoreMediaData) {
                            adaptor.append(resultImgBuffered!, withPresentationTime: frameTime)
                            break
                        }
                    }
                    
                    frameCount += 1
                }
                
                let progressRate = floor(i / length * 100)
                
                print(progressRate)
                
                
                DispatchQueue.main.async {
                    self.previewView.image = self.editingImage!
                    self.progressLabel.text = "处理中...(" + String(Int(progressRate)) + "%)"
                    self.progressView.setProgress(Float(progressRate / 100), animated: true)
                }
                
            }
            
            writerInput.markAsFinished()
            DispatchQueue.main.async {
                self.previewView.image = nil
                self.progressLabel.text = "Detecting bones...(100%)"
                self.progressView.setProgress(1.0, animated: true)
                self.cameraView.isHidden = false
            }
            
            videoWriter.endSession(atSourceTime: CMTimeMake(value: Int64((__int32_t(frameCount)) *  __int32_t(durationForEachImage)), timescale: __int32_t(fps)))
            
            videoWriter.finishWriting(completionHandler: {
                print("finished")
                self.isCompleted = true
                
            })
            
            
            
            
            DispatchQueue.main.async {
                self.messageLabel.text = "点击按钮播放视频"
                self.messageLabel.isHidden = false
                
//                if self.canUsePhotoLibrary! {
//                    if self.canUseCamera! {
//                        self.captureButton.isHidden = false
//                    }
//                    self.selectButton.isHidden = false
//                }
                
                self.captureButton.isHidden = false
                
                self.progressLabel.isHidden = true
                self.progressView.isHidden = true
                
                // 开启预览
                self.cameraView.isHidden = false
                
                
            }
            
            
            
            
        }
        
        return outputURL
    }
    
    
    
    // MARK: - 辅助功能
    

    
    
    func updateSelectButton() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        let last = fetchResult.lastObject
        
        if let lastAsset = last {
            // 说明此时相册中有视频
            let targetSize: CGSize = CGSize(width: 50, height: 50)
            let options: PHImageRequestOptions = PHImageRequestOptions()
            options.version = .current
            
            PHImageManager.default().requestImage(for: lastAsset, targetSize: targetSize, contentMode: .aspectFit, options: options) { image, _ in
                if self.canUsePhotoLibrary! {
                    DispatchQueue.main.async {
                        self.selectButton.setImage(image, for: .normal)
                        self.selectButton.isHidden = false
                    }
                }
            }
        }
        
    }
    
    func uiImageToPixelBuffer(_ uiImage: UIImage, targetSize: CGSize, orientation: UIImage.Orientation) -> CVPixelBuffer? {
        var angle: CGFloat
            
        if orientation == UIImage.Orientation.down {
            angle = CGFloat.pi
        } else if orientation == UIImage.Orientation.up {
            angle = 0
        } else if orientation == UIImage.Orientation.left {
            angle = CGFloat.pi / 2.0
        } else {
            angle = -CGFloat.pi / 2.0
        }
        
        let rotateTransform: CGAffineTransform = CGAffineTransform(translationX: targetSize.width / 2.0, y: targetSize.height / 2.0).rotated(by: angle).translatedBy(x: -targetSize.height / 2.0, y: -targetSize.width / 2.0)
        
        let uiImageResized = tools.resizeImage(image: uiImage, size: targetSize, keepAspectRatio: true)
        let ciImage = CIImage(image: uiImageResized)!
        let rotated = ciImage.transformed(by: rotateTransform)
        
        // Only need to create this buffer one time and then we can reuse it for every frame
        if resultBuffer == nil {
            let result = CVPixelBufferCreate(kCFAllocatorDefault, Int(targetSize.width), Int(targetSize.height), kCVPixelFormatType_32BGRA, nil, &resultBuffer)
            
            guard result == kCVReturnSuccess else {
                fatalError("Can't allocate pixel buffer.")
            }
        }
        
        // Render the Core Image pipeline to the buffer
        ciContext.render(rotated, to: resultBuffer!)
        
        //  For debugging
        //  let image = imageBufferToUIImage(resultBuffer!)
        //  print(image.size) // set breakpoint to see image being provided to CoreML
        
        return resultBuffer
    }
    
    func moveVideoToPhotoLibrary(_ url: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url as URL)
        }){ completed, error in
            if error != nil {
                print("ERROR: Failed to move a video file to Photo Library.")
            }
        }
    }

    
    
    
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle:.alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        
        present(alert, animated: true)
    }
    
    
    func playVideo(_ videourl: URL) {
        self.cameraView.layer.sublayers?.removeAll()
        let player = AVPlayer(url: videourl)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.cameraView.bounds
        self.cameraView.layer.addSublayer(playerLayer)
        player.play()

        
    }
    
    
    func videoProcessAtFinish(_ originalUrl: URL, _ outputUrl: URL) -> URL? {
        let audiourl = self.tools.extractAudio(originalURL: originalUrl)
        var res: URL? = nil
        Task {
            do {
                res = try await self.tools.mergeVideoAndAudio(videoUrl: outputUrl, audioUrl: audiourl!)
            } catch {
                fatalError("处理声音时出错")
            }
        }
        return res
    }
    

    
}
    
    



// MARK: - 扩展功能

/// 处理录制完成后的视频
extension VideoViewController: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("Just Finished Recording")
        // TODO: 完成检测
    }
    
}


// 从系统相册中选择
extension VideoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func selectVideo() {
        let imgPicker = UIImagePickerController()
        imgPicker.sourceType = .photoLibrary
        imgPicker.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
        imgPicker.mediaTypes = ["public.movie"]
        present(imgPicker, animated: true, completion: nil)
        
        
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
        self.selectedFileURL = info[.referenceURL] as? URL
        picker.dismiss(animated: true, completion: nil)
        guard let url: URL = selectedFileURL else { return }
        
        if ["MOV", "MP4", "M4V"].firstIndex(of: url.pathExtension.uppercased()) != nil {
            // 在view重新加载的时候判断是否要检测
            startDetecting(url)
//            self.playVideo(url)
            
//            Task {
//                do {
//                    let temp = try await self.tools.mergeVideoAndAudio(videoUrl: url, audioUrl: self.urlfirst!)
//                    print("hi")
//                    moveVideoToPhotoLibrary(temp)
//                    playVideo(temp)
//                } catch {
//                    fatalError("ERROR at adding audio")
//                }
//            }
            
        } else {
            showAlert(title: "出错了", message: "请使用 mov mp4 m4v 格式的视频")
        }
        
        selectedFileURL = nil
    }
    
}


