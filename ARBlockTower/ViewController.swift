//
//  ViewController.swift
//  iOS-WWDC18
//
//  Created by Nicholas Grana on 4/1/18.
//  Copyright © 2018 Nicholas Grana. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        GameManager.current.setup(controller: self)
    }
}

