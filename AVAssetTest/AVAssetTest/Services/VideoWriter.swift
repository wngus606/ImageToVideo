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
    
    var frameNum = 0
    
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
            let isFinished: Bool = self.appendPixelBuffers(progress: { (prog) in
                DispatchQueue.main.async {
                    progress(prog)
                }
            })
            if isFinished {
                self.videoWriterInput.markAsFinished()
                self.videoWriter.finishWriting(completionHandler: { 
                    DispatchQueue.main.async {
                        completion()
                    }
                })
            }
        }
    }
    
    fileprivate func appendPixelBuffers(progress: (Progress) -> Void) -> Bool {
        var images: [UIImage] = loadImages()
        let currentProgress = Progress(totalUnitCount: Int64(images.count))
        var frameCount: Int64 = 0
        let frameDuration = CMTimeMake(3,1)
        while !images.isEmpty {
            
            if !self.videoWriterInput.isReadyForMoreMediaData {
                // Inform writer we have more buffers to write.
                return false
            }
            let image = images.remove(at: 0)
            let presentationTime = CMTimeMultiply(frameDuration, Int32(frameNum))
            let success = addImage(image, presentationTime)
            if success == false {
                fatalError("addImage() failed")
            }
            frameNum += 1
            frameCount += 1
            currentProgress.completedUnitCount = frameCount
            progress(currentProgress)
        }
        
        // Inform writer all buffers have been written.
        return true
    }
    
    fileprivate func pixelBufferFromImage(_ image: UIImage, _ pixelBufferPool: CVPixelBufferPool) -> CVPixelBuffer? {
//        var pixelBufferOut: CVPixelBuffer?
//        let size: CGSize = self.renderSettings.frameSize
//        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBufferOut)
//        if status != kCVReturnSuccess {
//            fatalError("CVPixelBufferPoolCreatePixelBuffer() failed")
//        }
//        
//        let pixelBuffer = pixelBufferOut!
//        
//        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
//        
//        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
//        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
//        let context = CGContext(data: data, width: Int(size.width), height: Int(size.height),
//                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
//        
//        context!.clear(CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
//        
//        let horizontalRatio = size.width / image.size.width
//        let verticalRatio = size.height / image.size.height
//        let aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
//        //        let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit
//        
//        let newSize = CGSize(width: image.size.width * aspectRatio, height: image.size.height * aspectRatio)
//        
//        let x = newSize.width < size.width ? (size.width - newSize.width) / 2 : 0
//        let y = newSize.height < size.height ? (size.height - newSize.height) / 2 : 0
//        
//        context?.draw(image.cgImage!, in: CGRect(x: x, y: y, width: newSize.width, height: newSize.height ))
//        
//        
//        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
//        
//        return pixelBuffer

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
    
    func addImage(_ image: UIImage, _ presentationTime: CMTime) -> Bool {
        precondition(pixelBufferAdaptor != nil, "Call start() to initialze the writer")
        
        guard let pixelBufferPoll = self.pixelBufferAdaptor.pixelBufferPool,
            let pixelBuffer = pixelBufferFromImage(image, pixelBufferPoll) else {
                print("addImage nil")
                return false
        }
        return self.pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }
    
    func loadImages() -> [UIImage] {
        var images: [UIImage] = []
        for index in 5...35 {
            let fileName: String = "\(index).JPG"
            images.append(UIImage(named: fileName)!)
        }
        return images
    }
}
