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
    
    @IBOutlet weak var btnCancelRoute: UIBarButtonItem!
    @IBOutlet weak var btnNewRoute: UIButton!
    @IBOutlet weak var mainMapView: MKMapView!
    @IBOutlet weak var routerDetailView: RouteDetailView!
    
    let locationManager = CLLocationManager()
    var isShowingRoute = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideBarButton()
        
        routerDetailView.tableView.delegate = self
        routerDetailView.tableView.register(PlaceTableViewCell.self, forCellReuseIdentifier: String(describing: PlaceTableViewCell.self))
        
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
            
            for i in 0..<response.routes.count {
                self.plotPolyline(route: response.routes[i])
            }
        }
    }
    
    func plotPolyline(route: MKRoute) {
        
        print("\(route.steps)")
        print("\(route.advisoryNotices)")
        
        mainMapView.add(route.polyline)
        
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
    
    func showRouteDetail(for place: GMSPlace) {
        routerDetailView.title.text = place.formattedAddress
        routerDetailView.isHidden = false
    }
    
    func cancelRoutes() {
        mainMapView.removeOverlays(mainMapView.overlays)
    }
    
    
    func startRoute() {
        
    }
    
    func showBarButton() {
        btnCancelRoute.isEnabled = true
        btnCancelRoute.tintColor = nil
    }
    
    func hideBarButton() {
        btnCancelRoute.isEnabled = false
        btnCancelRoute.tintColor = UIColor.clear
    }
    
    @IBAction func pickNewDestination(_ sender: Any) {
        
        if routerDetailView.isHidden {
            showPlacePicker()
        } else {
            btnNewRoute.setTitle("Encerrar caminhada!", for: .normal)
            print("Start route!")
        }
    }
    
    @IBAction func cancelRouter(_ sender: Any) {
        routerDetailView.isHidden = true
        cancelRoutes()
        hideBarButton()
        btnNewRoute.setTitle("Nova Destino!", for: .normal)
    }
}

extension MapViewController: GMSPlacePickerViewControllerDelegate {
    
    func placePickerDidCancel(_ viewController: GMSPlacePickerViewController) {
        viewController.dismiss(animated: true) {
            
            guard let weakSelf = self as? MapViewController else {
                return
            }
            
            
            weakSelf.mainMapView.removeOverlays(weakSelf.mainMapView.overlays)
            weakSelf.isShowingRoute = false
        }
    }
    
    
    func placePicker(_ viewController: GMSPlacePickerViewController, didPick place: GMSPlace) {
        viewController.dismiss(animated: true) {
            
            guard let weakSelf = self as? MapViewController else {
                return
            }
            
            guard let userLocation = weakSelf.locationManager.location?.coordinate else {
                return
            }
            
            weakSelf.btnNewRoute.setTitle("Iniciar Caminhada", for: .normal)
            weakSelf.showBarButton()
            weakSelf.traceRoute(from: userLocation, to: place.coordinate)
            weakSelf.showRouteDetail(for: place)
        }
    }
}

extension MapViewController: MKMapViewDelegate, CLLocationManagerDelegate {

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        if (overlay is MKPolyline) {
            if mapView.overlays.count == 1 {
                polylineRenderer.strokeColor = UIColor.black.withAlphaComponent(1.0)
            } else if mapView.overlays.count == 2 {
                polylineRenderer.strokeColor = UIColor.black.withAlphaComponent(0.5)
            } else if mapView.overlays.count == 3 {
                polylineRenderer.strokeColor = UIColor.red
            }
            polylineRenderer.lineWidth = 5
        }
        return polylineRenderer
    }
}

extension MapViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PlaceTableViewCell.self)) as? PlaceTableViewCell {
            return cell
        } else {
            return UITableViewCell()
        }
        
    }

}

