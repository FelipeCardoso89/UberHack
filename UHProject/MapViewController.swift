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
    
    
    func traceRoute(from startCoordinate: CLLocationCoordinate2D, to endCoordinate:  CLLocationCoordinate2D) {
        
        let startPlacemark = MKPlacemark(coordinate: startCoordinate)
        let endPlacemark = MKPlacemark(coordinate: endCoordinate)
        
        let startItem = MKMapItem(placemark: startPlacemark)
        let endItem = MKMapItem(placemark: endPlacemark)
        
        let directionRequest = MKDirectionsRequest()
        directionRequest.source = startItem
        directionRequest.destination = endItem
        directionRequest.transportType = .walking
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            
            guard let weakSelf = self as? MapViewController, let response = response else {
                
                if let error = error {
                    print(error.localizedDescription)
                    return
                } else {
                    return
                }
            }
            
            print("\(response.routes)")
            
            for i in 0..<response.routes.count {
                self.plotPolyline(route: response.routes[i])
                self.renderWeightedPolyline(mapView: self.mainMapView, coordinates: response.routes[i].polyline.coordinates)
            }
            
//            let route = response.routes[0]
//            weakSelf.mainMapView.add(route.polyline, level: .aboveRoads)
//
//            let routeRect = route.polyline.boundingMapRect
//            weakSelf.mainMapView.setRegion(MKCoordinateRegionForMapRect(routeRect), animated: true)
        }
        
    }
    
    func renderWeightedPolyline(mapView: MKMapView, coordinates: [CLLocationCoordinate2D]) {
        
        var i = 0
        var increment = coordinates.count/3
        while i + increment < coordinates.count {
            var splittedCoordinates = coordinates[i...i+increment]
            
            let geodesic = MKPolyline(coordinates: Array(splittedCoordinates), count: splittedCoordinates.count)
            mapView.add(geodesic)
            
            let polylineBoundingRect =  MKMapRectUnion(mainMapView.visibleMapRect, geodesic.boundingMapRect)
            mainMapView.setVisibleMapRect(
                polylineBoundingRect,
                edgePadding: UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0),
                animated: false)
            
            i += increment
        }
    }
    
    func plotPolyline(route: MKRoute) {
        
        print("\(route.steps)")
        print("\(route.advisoryNotices)")
        
        mainMapView.add(route.polyline)
        
        self.placeStartAndEndPin(mapView: mainMapView, userLocation: route.polyline.coordinates[0], destinationLocation: route.polyline.coordinates.last!)
        
        if mainMapView.overlays.count == 1 {
            mainMapView.setVisibleMapRect(
                route.polyline.boundingMapRect,
                edgePadding: UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0),
                animated: false)
        } else {
            let polylineBoundingRect =  MKMapRectUnion(mainMapView.visibleMapRect, route.polyline.boundingMapRect)
            mainMapView.setVisibleMapRect(
                polylineBoundingRect,
                edgePadding: UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0),
                animated: false)
        }
    }
    
    private func placeStartAndEndPin(mapView: MKMapView, userLocation: CLLocationCoordinate2D, destinationLocation: CLLocationCoordinate2D) {
        
        let userAnnotation = MKPointAnnotation()
        userAnnotation.coordinate = CLLocationCoordinate2D(latitude: userLocation.latitude, longitude: userLocation.longitude)
        mapView.addAnnotation(userAnnotation)
        
        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.coordinate = CLLocationCoordinate2D(latitude: destinationLocation.latitude, longitude: destinationLocation.longitude)
        mapView.addAnnotation(destinationAnnotation)
        
    }
    
    func removeAllAnnotationsFromMap(mapView: MKMapView) {
        let allAnnotations = mapView.annotations
        mapView.removeAnnotations(allAnnotations)
    }
    
    @IBAction func pickNewDestination(_ sender: Any) {
        showPlacePicker()
    }
    
}


extension MapViewController: GMSPlacePickerViewControllerDelegate {
    
    func placePicker(_ viewController: GMSPlacePickerViewController, didPick place: GMSPlace) {
        viewController.dismiss(animated: true) {
            
            guard let weakSelf = self as? MapViewController else {
                return
            }
            
            guard let userLocation = weakSelf.locationManager.location?.coordinate else {
                return
            }
            
            weakSelf.mainMapView.removeOverlays(weakSelf.mainMapView.overlays)
            weakSelf.traceRoute(from: userLocation, to: place.coordinate)
            
            // removes all annotations (pins)
            weakSelf.removeAllAnnotationsFromMap(mapView: weakSelf.mainMapView)
        }
    }
}

public extension MKPolyline {
    public var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid,
                                              count: self.pointCount)
        
        self.getCoordinates(&coords, range: NSRange(location: 0, length: self.pointCount))
        
        return coords
    }
}

extension MapViewController: MKMapViewDelegate, CLLocationManagerDelegate {
    
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        if (overlay is MKPolyline) {
            if mapView.overlays.count == 1 {
                polylineRenderer.strokeColor = UIColor.blue
            } else if mapView.overlays.count == 2 {
                polylineRenderer.strokeColor = UIColor.green
            } else if mapView.overlays.count == 3 {
                polylineRenderer.strokeColor = UIColor.red
            }
            polylineRenderer.lineWidth = 5
        }
        return polylineRenderer
    }
    
    
}
