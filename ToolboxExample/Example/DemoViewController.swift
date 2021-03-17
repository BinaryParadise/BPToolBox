//
//  DemoViewController.swift
//  ToolboxExample_Example
//
//  Created by Rake Yang on 2021/3/17.
//  Copyright © 2021 rakeyang. All rights reserved.
//

import UIKit

class DemoViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let view = UIImageView(image: UIImage(named: "yuqi"))
        view.addSubview(view)
    }
}
