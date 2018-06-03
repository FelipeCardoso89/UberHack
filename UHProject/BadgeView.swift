//
//  BadgeView.swift
//  UHProject
//
//  Created by Wilder Pereira on 03/06/18.
//  Copyright © 2018 Felipe Antonio Cardoso. All rights reserved.
//

import Foundation
import MapKit

class BadgeView: MKAnnotationView {
    override var annotation: MKAnnotation? {
        willSet {
            guard let badge = newValue as? Badge else {return}
            canShowCallout = true
            calloutOffset = CGPoint(x: -5, y: 5)
            rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            // glyphText = String("T")
        }
    }
}
