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
    
    var routeBadges = [
        RouteBadge(id:"free-sidewalk", name:"Calçadas Livres", image: ""),
        RouteBadge(id:"light", name:"Iluminado", image: ""),
        RouteBadge(id:"people", name:"Local Movimentado", image: ""),
        RouteBadge(id:"hole-sidewalk", name:"Calçada com buraco", image: ""),
        RouteBadge(id:"crossing-road", name:"Faixa de pedestre", image: ""),
        RouteBadge(id:"no-light-sinalization", name:"Sem luz de pedestre", image: ""),
    ]
    
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
        
        mainMapView.register(BadgeView.self,
                             forAnnotationViewWithReuseIdentifier: "marker")
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotationOnLongPress(gesture:)))
        longPressGesture.minimumPressDuration = 0.5
        
        mainMapView.addGestureRecognizer(longPressGesture)
        
    }
    
    @objc func addAnnotationOnLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .ended {
            let point = gesture.location(in: self.mainMapView)
            let coordinate = self.mainMapView.convert(point, toCoordinateFrom: self.mainMapView)
            print(coordinate)
            var badge = Badge(title: "test", coordinate: coordinate)
            self.mainMapView.addAnnotation(badge)
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
                self.renderWeightedPolyline(mapView: self.mainMapView, coordinates: response.routes[i].polyline.coordinates)
            }
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
    
    func showRouteDetail(for place: GMSPlace) {
        routerDetailView.title.text = place.formattedAddress
        routerDetailView.isHidden = false
    }
    
    func cancelRoutes() {
        mainMapView.removeOverlays(mainMapView.overlays)
        removeAllAnnotationsFromMap(mapView: mainMapView)
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
    
    // 1
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 2
        guard let annotation = annotation as? Badge else { return nil }
        // 3
        let identifier = "marker"
        var view: MKMarkerAnnotationView
        // 4
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            // 5
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        return view
    }

}

