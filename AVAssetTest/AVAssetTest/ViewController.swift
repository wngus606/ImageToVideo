//
//  ViewController.swift
//  AVAssetTest
//
//  Created by seo on 2017. 5. 15..
//  Copyright © 2017년 seoju. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let testButton: UIButton = {
        let testButton: UIButton = UIButton()
        testButton.setTitle("Test", for: .normal)
        testButton.backgroundColor = UIColor.red
        return testButton
    }()
    
    let progressView: UIProgressView = {
        let progressView: UIProgressView = UIProgressView(progressViewStyle: .bar)
        progressView.progress = 0.0
        progressView.trackTintColor = .yellow
        progressView.progressTintColor = .red
        return progressView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .lightGray
        
        // target
        self.testButton.addTarget(self, action: #selector(testButtonTouchUpInsdie), for: .touchUpInside)
        
        // frame
        let buttonSize: CGSize = CGSize(width: 100.0, height: 50.0)
        self.testButton.frame = CGRect(x: self.view.center.x - buttonSize.width / 2,
                                       y: self.view.center.y - buttonSize.height / 2,
                                       width: buttonSize.width,
                                       height: buttonSize.height)
        self.progressView.frame = CGRect(x: 70.0,
                                         y: self.testButton.frame.maxY + 30.0,
                                         width: self.view.frame.width - 140.0,
                                         height: 10.0)
        
        // add subview
        self.view.addSubview(self.testButton)
        self.view.addSubview(self.progressView)
    }
    
    // MARK: Actions
    
    func testButtonTouchUpInsdie(_ sender: UIButton) {
        let settings: RenderSettings = RenderSettings()
        let imageAnimator: ImageAnimator = ImageAnimator(renderSettings: settings)
        imageAnimator.render(progress: { (progress) in
            print("progress : \(Float(progress.fractionCompleted))")
            self.progressView.progress = Float(progress.fractionCompleted)
        }) { 
            print("Completion!!!!!!!!!")
        }
    }
}

