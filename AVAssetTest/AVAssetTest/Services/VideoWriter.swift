//
//  VideoWriter.swift
//  AVAssetTest
//
//  Created by seo on 2017. 5. 15..
//  Copyright © 2017년 seoju. All rights reserved.
//

import AVFoundation
import UIKit

class VideoWriter {
    
    fileprivate var threadFlag: Bool = true
    let renderSettings: RenderSettings
    
    var videoWriter: AVAssetWriter!
    var videoWriterInput: AVAssetWriterInput!
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    
    init(renderSettings: RenderSettings) {
        self.renderSettings = renderSettings
    }
    
    func start() {
        let avOutputSettings: [String: AnyObject] = [
            AVVideoCodecKey: renderSettings.avCodecKey as AnyObject,
            AVVideoWidthKey: NSNumber(value: Float(renderSettings.frameSize.width)),
            AVVideoHeightKey: NSNumber(value: Float(renderSettings.frameSize.height))
        ]
        
        func createPixelBufferAdaptor() {
            let sourcePixelBufferAttributesDictionary = [
                kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: NSNumber(value: Float(renderSettings.frameSize.width)),
                kCVPixelBufferHeightKey as String: NSNumber(value: Float(renderSettings.frameSize.height))
            ]
            self.pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: self.videoWriterInput,
                                                                      sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        }
        
        func createAssetWriter(outputURL: URL) -> AVAssetWriter {
            guard let assetWriter = try? AVAssetWriter(outputURL: outputURL as URL, fileType: AVFileTypeMPEG4) else {
                fatalError("AVAssetWriter() failed")
            }
            
            guard assetWriter.canApply(outputSettings: avOutputSettings, forMediaType: AVMediaTypeVideo) else {
                fatalError("canApplyOutputSettings() failed")
            }
            
            return assetWriter
        }
        
        self.videoWriter = createAssetWriter(outputURL: self.renderSettings.outputURL)
        self.videoWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: avOutputSettings)
        
        if self.videoWriter.canAdd(self.videoWriterInput) {
           self.videoWriter.add(self.videoWriterInput)
        }
        else {
            fatalError("canAddInput() returned false")
        }
        
        // The pixel buffer adaptor must be created before we start writing.
        createPixelBufferAdaptor()
        
        if videoWriter.startWriting() == false {
            fatalError("startWriting() failed")
        }
        
        videoWriter.startSession(atSourceTime: kCMTimeZero)
        
        precondition(pixelBufferAdaptor.pixelBufferPool != nil, "nil pixelBufferPool")
    }
    
    func render(progress: @escaping (Progress) -> Void, completion: @escaping () -> Void) {
        precondition(videoWriter != nil, "Call start() to initialze the writer")

        
        let queue = DispatchQueue(label: "mediaInputQueue")
        self.videoWriterInput.requestMediaDataWhenReady(on: queue) {
            if self.threadFlag {
                self.threadFlag = false
                let isFinished: Bool = self.appendPixelBuffers(progress: { (prog) in
                    DispatchQueue.main.async {
                        progress(prog)
                    }
                })
                
                if isFinished {
                    self.videoWriterInput.markAsFinished()
                    self.videoWriter.finishWriting(completionHandler: {
                        DispatchQueue.main.async {
                            self.threadFlag = true
                            completion()
                        }
                    })
                }
            }
        }
    }
    
    fileprivate func appendPixelBuffers(progress: (Progress) -> Void) -> Bool {
        var images: [UIImage] = loadImages()
        let currentProgress = Progress(totalUnitCount: Int64(images.count))
        var frameCount: Int64 = 0
        var frameNum: Int64 = 0
        var presentationTime: CMTime = CMTimeMake(0, self.renderSettings.fps)
        while !images.isEmpty {
            if !self.videoWriterInput.isReadyForMoreMediaData {
                // Inform writer we have more buffers to write.
                print("sleep 1")
                sleep(1)
            }
            let baseImage = images.remove(at: 0)
            print("image count : \(images.count)")
            presentationTime = CMTimeMake(frameNum, self.renderSettings.fps)
            print("presentiation seconds0 : \(presentationTime.seconds)")
            
            let success = addImage(baseImage, presentationTime)
            if success == false {
                fatalError("addImage() failed")
            }
            
            if images.count > 0 {
                // fade
                let fadeTime: CMTime = CMTimeMake(1, 50)
                for _ in 1...80 {
                    presentationTime = CMTimeAdd(presentationTime, fadeTime)
                }
                print("presentiation seconds1 : \(presentationTime.seconds)")
                let fadeImage: UIImage = images[0]
                for index in 1...19 {
                    if !self.videoWriterInput.isReadyForMoreMediaData {
                        // Inform writer we have more buffers to write.
                        print("Sleep 2")
                        sleep(1)
                    }
                    let success = addFadeImage(baseImage, fadeImage, presentationTime, CGFloat(index)/CGFloat(19))
                    if !success {
                        fatalError("addFadeImage() failed")
                    }
                    presentationTime = CMTimeAdd(presentationTime, fadeTime)
                }
                print("presentiation seconds2 : \(presentationTime.seconds)")
            }
            
            // end fade
            
            frameNum += 2
            frameCount += 1
            currentProgress.completedUnitCount = frameCount
            progress(currentProgress)
        }
        
        // Inform writer all buffers have been written.
        return true
    }
    
    fileprivate func pixelBufferFromImage(_ image: UIImage, _ pixelBufferPool: CVPixelBufferPool) -> CVPixelBuffer? {
        var pixelBufferOut: CVPixelBuffer? = nil
        let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault,
                                                                  pixelBufferPool,
                                                                  &pixelBufferOut)
        if status == kCVReturnSuccess, let pixelBuffer: CVPixelBuffer = pixelBufferOut {
            let frameSize: CGSize = self.renderSettings.frameSize
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: pixelData,
                                    width: Int(frameSize.width),
                                    height: Int(frameSize.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                    space: rgbColorSpace,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
            context?.clear(CGRect(x: 0.0, y: 0.0, width: frameSize.width, height: frameSize.height))
            context?.draw(image.cgImage!, in: CGRect(x: 0.0, y: 0.0, width: frameSize.width, height: frameSize.height))
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            return pixelBuffer
        }
        
        return pixelBufferOut
    }
    
    fileprivate func crossFadeImage(_ baseImage: UIImage, _ fadeImage: UIImage, _ pixelBufferPool: CVPixelBufferPool, _ alpha: CGFloat) -> CVPixelBuffer? {
        var pixelBufferOut: CVPixelBuffer? = nil
        let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault,
                                                                  pixelBufferPool,
                                                                  &pixelBufferOut)
        guard status == kCVReturnSuccess, let pixelBuffer: CVPixelBuffer = pixelBufferOut,
            let baseCGImage: CGImage = baseImage.cgImage, let fadeCGImage: CGImage = fadeImage.cgImage else {
            return pixelBufferOut
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let frameSize: CGSize = self.renderSettings.frameSize
        let pixelData: UnsafeMutableRawPointer? = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData,
                                width: Int(frameSize.width),
                                height: Int(frameSize.height),
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        let drawRect: CGRect = CGRect(x: 0.0, y: 0.0, width: frameSize.width, height: frameSize.height)
        context?.draw(baseCGImage, in: drawRect)
        context?.beginTransparencyLayer(auxiliaryInfo: nil)
        context?.setAlpha(alpha)
        context?.draw(fadeCGImage, in: drawRect)
        context?.endTransparencyLayer()
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
        
    }
    
    func addImage(_ image: UIImage, _ presentationTime: CMTime) -> Bool {
        precondition(pixelBufferAdaptor != nil, "Call start() to initialze the writer")
        
        guard let pixelBufferPool = self.pixelBufferAdaptor.pixelBufferPool,
            let pixelBuffer = pixelBufferFromImage(image, pixelBufferPool) else {
                print("addImage nil")
                return false
        }
        
        return self.pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }
    
    func addFadeImage(_ baseImage: UIImage, _ fadeImage: UIImage, _ presentationTime: CMTime, _ alpha: CGFloat) -> Bool {
        precondition(self.pixelBufferAdaptor != nil, "Call start() to initialze the writer")

        guard let pixelBufferPool = self.pixelBufferAdaptor.pixelBufferPool,
            let pixelBuffer = crossFadeImage(baseImage, fadeImage, pixelBufferPool, alpha) else {
            print("addFadeImage error")
            return false
        }
        
        return self.pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }
    
    func loadImages() -> [UIImage] {
        var images: [UIImage] = []
        for index in 1...30 {
            let fileName: String = "\(index).JPG"
            images.append(UIImage(named: fileName)!)
        }
        return images
    }
}
