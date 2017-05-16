//
//  ViewController.swift
//  AVAssetTest
//
//  Created by seo on 2017. 5. 15..
//  Copyright © 2017년 seoju. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    let testButton: UIButton = {
        let testButton: UIButton = UIButton()
        testButton.setTitle("Test", for: .normal)
        testButton.backgroundColor = .red
        return testButton
    }()
    
    let playButton: UIButton =  {
        let playButton: UIButton = UIButton()
        playButton.setTitle("Play", for: .normal)
        playButton.setTitleColor(UIColor.black, for: .normal)
        playButton.backgroundColor = .yellow
        return playButton
    }()
    
    let progressView: UIProgressView = {
        let progressView: UIProgressView = UIProgressView(progressViewStyle: .bar)
        progressView.progress = 0.0
        progressView.trackTintColor = .yellow
        progressView.progressTintColor = .red
        return progressView
    }()
    
    let playheadLabel: UILabel = {
        let playheadLabel: UILabel = UILabel()
        playheadLabel.textColor = .black
        return playheadLabel
    }()
    
    let durationLabel: UILabel = {
        let durationLabel: UILabel = UILabel()
        durationLabel.textColor = .red
        return durationLabel
    }()
    
    let playSlider: UISlider = {
        let playSlider: UISlider = UISlider()
        playSlider.tintColor = .green
        playSlider.isContinuous = false
        playSlider.minimumValue = 0.0
        return playSlider
    }()
    
    
    let settings: RenderSettings = RenderSettings()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 파일 삭제
        settings.removeDocumentMP4Flie()
        
        // target
        self.playButton.addTarget(self, action: #selector(playButtonTouchUpInside), for: .touchUpInside)
        self.testButton.addTarget(self, action: #selector(testButtonTouchUpInside), for: .touchUpInside)
        
        // frame
        let buttonSize: CGSize = CGSize(width: 100.0, height: 50.0)
        self.playButton.frame = CGRect(x: 100.0,
                                       y: 30.0,
                                       width: buttonSize.width,
                                       height: buttonSize.height)
        self.testButton.frame = CGRect(x: self.playButton.frame.maxX + 10.0,
                                       y: 30.0,
                                       width: buttonSize.width,
                                       height: buttonSize.height)
        self.progressView.frame = CGRect(x: 70.0,
                                         y: self.testButton.frame.maxY + 30.0,
                                         width: self.view.frame.width - 140.0,
                                         height: 10.0)
        self.playheadLabel.frame = CGRect(x: 100.0,
                                          y: self.view.frame.height - 200.0,
                                          width: 100.0,
                                          height: 100.0)
        self.durationLabel.frame = CGRect(x: self.playheadLabel.frame.maxX + 20.0,
                                          y: self.playheadLabel.frame.origin.y,
                                          width: 100.0,
                                          height: 100.0)
        self.playSlider.frame = CGRect(x: 20.0,
                                       y: self.playheadLabel.frame.maxY + 20.0,
                                       width: self.view.frame.width - 40.0,
                                       height: 10.0)
        
        // add subview
        self.view.addSubview(self.playButton)
        self.view.addSubview(self.testButton)
        self.view.addSubview(self.progressView)
        self.view.addSubview(self.playheadLabel)
        self.view.addSubview(self.durationLabel)
        self.view.addSubview(self.playSlider)
    }
    
    
    func getHoursMinutesSecondsFrom(seconds: Double) -> (hours: Int, minutes: Int, seconds: Int) {
        let secs = Int(seconds)
        let hours = secs / 3600
        let minutes = (secs % 3600) / 60
        let seconds = (secs % 3600) % 60
        return (hours, minutes, seconds)
    }
    
    func formatTimeFor(seconds: Double) -> String {
        let result = getHoursMinutesSecondsFrom(seconds: seconds)
        let hoursString = "\(result.hours)"
        var minutesString = "\(result.minutes)"
        if minutesString.characters.count == 1 {
            minutesString = "0\(result.minutes)"
        }
        var secondsString = "\(result.seconds)"
        if secondsString.characters.count == 1 {
            secondsString = "0\(result.seconds)"
        }
        var time = "\(hoursString):"
        if result.hours >= 1 {
            time.append("\(minutesString):\(secondsString)")
        }
        else {
            time = "\(minutesString):\(secondsString)"
        }
        return time
    }
    
    func updateTime(_ player: AVPlayer) {
        // Access current item
        if let currentItem = player.currentItem {
            // Get the current time in seconds
            let playhead = currentItem.currentTime().seconds
            let duration = currentItem.asset.duration.seconds
            
            self.playSlider.maximumValue = Float(duration)
            // Format seconds for human readable string
            playheadLabel.text = formatTimeFor(seconds: playhead)
            durationLabel.text = formatTimeFor(seconds: duration)
        }
    }

    
    // MARK: Actions
    
    func playButtonTouchUpInside(_ sender: UIButton) {
        let player = AVPlayer(url: settings.outputURL)
        updateTime(player)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.view.bounds
        self.view.layer.addSublayer(playerLayer)
        
        
        let interval = CMTime(seconds: 1.0,
                              preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [unowned self] time in
            self.playheadLabel.text = self.formatTimeFor(seconds: time.seconds)
            self.playSlider.value = Float(time.seconds)
        }
        player.play()
    }
    
    func testButtonTouchUpInside(_ sender: UIButton) {
        let imageAnimator: ImageAnimator = ImageAnimator(renderSettings: settings)
        imageAnimator.render(progress: { (progress) in
            print("progress : \(Float(progress.fractionCompleted))")
            self.progressView.progress = Float(progress.fractionCompleted)
        }) { 
            print("Completion!!!!!!!!!")
        }
    }
}

