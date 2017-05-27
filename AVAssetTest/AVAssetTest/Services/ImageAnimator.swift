//
//  ImageAnimator.swift
//  AVAssetTest
//
//  Created by seo on 2017. 5. 15..
//  Copyright © 2017년 seoju. All rights reserved.
//

import UIKit
import Photos

class ImageAnimator {
    
    let settings: RenderSettings
    let videoWriter: VideoWriter
    
    init(renderSettings: RenderSettings) {
        self.settings = renderSettings
        self.videoWriter = VideoWriter(renderSettings: renderSettings)
    }
    
    fileprivate func saveToLibrary(videoURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }) { success, error in
                if !success {
                    print("Could not save video to photo library:", error!)
                }
            }
        }
    }
    
    fileprivate func removeFileAtURL(fileURL: URL) {
        do {
            try FileManager.default.removeItem(atPath: fileURL.path)
        }
        catch _ as NSError {
            // Assume file doesn't exist.
        }
    }
    
    
    func render(progress: @escaping (Progress) -> Void, completion: @escaping () -> Void) {
        let outputURL: URL = self.settings.outputURL
        removeFileAtURL(fileURL: outputURL)
        
        self.videoWriter.start()
        self.videoWriter.render(progress: { (prog) in
            progress(prog)
        }, completion: { (_) in
            print(outputURL)
//            self.saveToLibrary(videoURL: outputURL)
            completion()
        })
    }

    
}
