//
//  RatingViewController.swift
//  UHProject
//
//  Created by Felipe Antonio Cardoso on 03/06/2018.
//  Copyright © 2018 Felipe Antonio Cardoso. All rights reserved.
//

import UIKit

class RatingViewController: UIViewController {

    @IBOutlet weak var btnAvaliar: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
