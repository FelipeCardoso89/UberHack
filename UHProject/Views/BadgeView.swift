//
//  BadgeView.swift
//  UHProject
//
//  Created by Felipe Antonio Cardoso on 03/06/2018.
//  Copyright © 2018 Felipe Antonio Cardoso. All rights reserved.
//

import UIKit

class BadgeView: UIView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var title: UILabel!

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.clipsToBounds = true
        imageView.layer.borderColor = UIColor.gray.cgColor
        imageView.layer.borderWidth = 2.0
        imageView.layer.cornerRadius =  39.75
    }
    
}
