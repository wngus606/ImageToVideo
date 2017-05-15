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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let buttonSize: CGSize = CGSize(width: 100.0, height: 50.0)
        self.testButton.frame = CGRect(x: self.view.center.x - buttonSize.width / 2,
                                       y: self.view.center.y - buttonSize.height / 2,
                                       width: buttonSize.width,
                                       height: buttonSize.height)
        self.view.addSubview(self.testButton)
    }
}

