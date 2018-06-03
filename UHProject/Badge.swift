//
//  Badge.swift
//  UHProject
//
//  Created by Wilder Pereira on 03/06/18.
//  Copyright © 2018 Felipe Antonio Cardoso. All rights reserved.
//

import Foundation
import MapKit

class Badge: NSObject, MKAnnotation {
    let title: String?
    let type: String = "default"
    let coordinate: CLLocationCoordinate2D
    
    init(title: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.coordinate = coordinate
        
        super.init()
    }
    
    var subtitle: String? {
        return ""
    }
    
    var markerTintColor: UIColor  {
        switch type {
        case "Monument":
            return .red
        case "Mural":
            return .cyan
        case "Plaque":
            return .blue
        case "Sculpture":
            return .purple
        default:
            return .green
        }
    }
    
}
