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


class MapViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var btnCancelRoute: UIBarButtonItem!
    @IBOutlet weak var btnNewRoute: UIButton!
    @IBOutlet weak var mainMapView: MKMapView!
    @IBOutlet weak var routerDetailView: RouteDetailView!
    
    let locationManager = CLLocationManager()
    let badges = RouteBadge.badges()
    var isShowingRoute = false
    var isInitialized = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideBarButton()
        generateAnnoLoc()
        
//        routerDetailView.badgeCollectionView.delegate = self
//        routerDetailView.badgeCollectionView.dataSource = self
        
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
        
        mainMapView.register(BadgeAnnotationView.self,
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
        var increment = coordinates.count/4
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
    
    func generateAnnoLoc() {
        
        var num = 0
        //First we declare While to repeat adding Annotation
        while num != 15 {
            num += 1
            
            //Add Annotation
            let annotation = MKPointAnnotation()
            annotation.coordinate = generateRandomCoordinates(min: 1000, max: 1000) //this will be the maximum and minimum distance of the annotation from the current Location (Meters)
            annotation.title = "Ocorrências"
            annotation.subtitle = "Usuário reportou algo acontecido aqui!"
            mainMapView.addAnnotation(annotation)
            
        }
        
    }
    
    func generateRandomCoordinates(min: UInt32, max: UInt32)-> CLLocationCoordinate2D {
        //Get the Current Location's longitude and latitude
        let currentLong = locationManager.location?.coordinate.longitude
        let currentLat = locationManager.location?.coordinate.latitude
        
        //1 KiloMeter = 0.00900900900901° So, 1 Meter = 0.00900900900901 / 1000
        let meterCord = 0.00900900900901 / 1000
        
        //Generate random Meters between the maximum and minimum Meters
        let randomMeters = UInt(arc4random_uniform(max) + min)
        
        //then Generating Random numbers for different Methods
        let randomPM = arc4random_uniform(6)
        
        //Then we convert the distance in meters to coordinates by Multiplying number of meters with 1 Meter Coordinate
        let metersCordN = meterCord * Double(randomMeters)
        
        //here we generate the last Coordinates
        if randomPM == 0 {
            return CLLocationCoordinate2D(latitude: currentLat! + metersCordN, longitude: currentLong! + metersCordN)
        }else if randomPM == 1 {
            return CLLocationCoordinate2D(latitude: currentLat! - metersCordN, longitude: currentLong! - metersCordN)
        }else if randomPM == 2 {
            return CLLocationCoordinate2D(latitude: currentLat! + metersCordN, longitude: currentLong! - metersCordN)
        }else if randomPM == 3 {
            return CLLocationCoordinate2D(latitude: currentLat! - metersCordN, longitude: currentLong! + metersCordN)
        }else if randomPM == 4 {
            return CLLocationCoordinate2D(latitude: currentLat!, longitude: currentLong! - metersCordN)
        }else {
            return CLLocationCoordinate2D(latitude: currentLat! - metersCordN, longitude: currentLong!)
        }
        
    }
    
    @IBAction func pickNewDestination(_ sender: Any) {
        
        if routerDetailView.isHidden {
            showPlacePicker()
        } else if ( btnNewRoute.currentTitle == "Encerrar caminhada!") {
            
            //TODO: mover usuário
            
            let controller = PopupViewController()
            controller.modalPresentationStyle = UIModalPresentationStyle.popover
            let popController = controller.popoverPresentationController
            popController?.permittedArrowDirections = .any
            popController?.delegate = self
            
            self.present(controller, animated: true, completion: nil)

        } else {
            btnNewRoute.setTitle("Encerrar caminhada!", for: .normal)
            routerDetailView.isHidden = true
            print("Start route!")
        }
    }
    
    @IBAction func cancelRouter(_ sender: Any) {
        routerDetailView.isHidden = true
        cancelRoutes()
        hideBarButton()
        btnNewRoute.setTitle("Novo Destino!", for: .normal)
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

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !isInitialized {
            // Here is called only once
            isInitialized = true
            
            let userLoction: CLLocation = locations[0]
            let latitude = userLoction.coordinate.latitude
            let longitude = userLoction.coordinate.longitude
            let latDelta: CLLocationDegrees = 0.05
            let lonDelta: CLLocationDegrees = 0.05
            let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
            let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
            let region: MKCoordinateRegion = MKCoordinateRegionMake(location, span)
            mainMapView.setRegion(region, animated: true)
            mainMapView.showsUserLocation = true
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        if (overlay is MKPolyline) {
            if mapView.overlays.count == 1 {
                polylineRenderer.strokeColor = UIColor.orange.withAlphaComponent(1.0)
            } else if mapView.overlays.count == 2 {
                polylineRenderer.strokeColor = UIColor.blue.withAlphaComponent(1.0)
            } else if mapView.overlays.count == 3 {
                polylineRenderer.strokeColor = UIColor.red.withAlphaComponent(1.0)
            }
            polylineRenderer.lineWidth = 5
        }
        return polylineRenderer
    }
}

extension MapViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return badges.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BadgeCollectionViewCell", for: indexPath) as? BadgeCollectionViewCell {
            return cell
        } else {
            return UICollectionViewCell()
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


