//
//  RenderSettings.swift
//  AVAssetTest
//
//  Created by seo on 2017. 5. 15..
//  Copyright © 2017년 seoju. All rights reserved.
//

import AVFoundation
import UIKit
import Photos

struct RenderSettings {
    
    fileprivate var width: CGFloat = 1920
    fileprivate var height: CGFloat = 1080
    var fps: Int32 = 1
    var avCodecKey: String = AVVideoCodecH264
    
    var frameSize: CGSize {
        return CGSize(width: self.width, height: self.height)
    }
    
    var outputURL: URL {
        // 앨범경로
//        let fileManager = FileManager.default
//        if let tmpDirURL = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
//            return tmpDirURL.appendingPathComponent("Test").appendingPathExtension("mp4") as URL
//        }
//        fatalError("URLForDirectory() failed")
        
        // local document
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let videoOutputURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("Test.mp4")
        
        return videoOutputURL
    }
    
    func removeDocumentMP4Flie() {
        do {
            try FileManager.default.removeItem(at: self.outputURL)
        } catch {}
    }
}
