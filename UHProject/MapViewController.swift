//
//  MapViewController.swift
//  UHProject
//
//  Created by Felipe Antonio Cardoso on 02/06/2018.
//  Copyright © 2018 Felipe Antonio Cardoso. All rights reserved.
//

import UIKit
import MapKit
import GooglePlacePicker


class MapViewController: UIViewController {

    @IBOutlet weak var mainMapView: MKMapView!
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainMapView.delegate = self
        mainMapView.showsScale = true
        mainMapView.showsUserLocation = true

        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func showPlacePicker() {
        let config = GMSPlacePickerConfig(viewport: nil)
        let placePicker = GMSPlacePickerViewController(config: config)
        placePicker.delegate = self
        present(placePicker, animated: true, completion: nil)
    }
    
    
    @IBAction func pickNewDestination(_ sender: Any) {
        
        showPlacePicker()
    }
    
}

extension MapViewController: GMSPlacePickerViewControllerDelegate {
    
    func placePicker(_ viewController: GMSPlacePickerViewController, didPick place: GMSPlace) {
        viewController.dismiss(animated: true) {
            print("\(place.coordinate.latitude) - \(place.coordinate.longitude)")
        }
    }
    
}

extension MapViewController: MKMapViewDelegate, CLLocationManagerDelegate {
    
    
    
}
