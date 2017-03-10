//
//  ViewController.swift
//  SavedLocations
//
//  Created by Callum Carmichael on 09/03/2017.
//  Copyright © 2017 Callum Carmichael. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager: CLLocationManager = CLLocationManager()
    
    var destination: MKMapItem = MKMapItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    
        let uilpgr = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.longpress(gestureRecognizer:)))
        
        uilpgr.minimumPressDuration = 2
        
        mapView.addGestureRecognizer(uilpgr)
        
        if activePlace == -1 {
            
         locationManager.delegate = self
         locationManager.desiredAccuracy = kCLLocationAccuracyBest
         locationManager.requestWhenInUseAuthorization()
         locationManager.startUpdatingLocation()
            
        mapView.showsUserLocation = true
            
            
        } else {
        
            // Get Place details to display on map
            
            if places.count > activePlace {
                
                if let name = places[activePlace]["name"] {
                    
                    if let lat = places[activePlace]["lat"] {
                        
                        
                        if let lon = places [activePlace]["lon"] {
                            
                            if let latitude = Double(lat) {
                                
                                if let longitude = Double(lon) {
                                    
                                    let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                    
                                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                    
                                    let region = MKCoordinateRegion(center: coordinate, span: span)
                                    
                                    self.mapView.setRegion(region, animated: true)
                                    
                                    let annotation = MKPointAnnotation()
                                    
                                    annotation.coordinate = coordinate
                                    
                                    annotation.title = name
                                    
                                    self.mapView.addAnnotation(annotation)
                                    
                                    
                                }
                                
                            }
                            
                        }
                    }
                    
                    
                }
                
            }
            
            
            
        }
        
        
        
    
    }
    
    func longpress(gestureRecognizer: UIGestureRecognizer) {
        
        if gestureRecognizer.state == UIGestureRecognizerState.began {
        
            let touchPoint = gestureRecognizer.location(in: self.mapView)
        
            let newCoordinate = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            
            let location = CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude)
            
            var title = ""
            
            CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
                
                if error != nil {
                    
                    print(error!)
                    
                } else {
                    
                    if let placemark = placemarks?[0] {
                        
                        if placemark.subThoroughfare != nil {
                            
                            title += placemark.subThoroughfare! + ""
                            
                        }
                        
                        if placemark.thoroughfare != nil {
                            
                            title += placemark.thoroughfare!
                        }
                        
                }
                
            }
                
                if title == "" {
                    
                    title = "Added \(NSDate())"
                    
                }
                
        
        
            let annotation = MKPointAnnotation()
        
            annotation.coordinate = newCoordinate
        
            annotation.title = title
            
            let placeMark = MKPlacemark(coordinate: newCoordinate, addressDictionary: nil)
                
            self.destination = MKMapItem(placemark: placeMark)
            
            self.mapView.addAnnotation(annotation)
            
            places.append(["name":title, "lat": String(newCoordinate.latitude), "lon": String(newCoordinate.longitude)])
        
            UserDefaults.standard.set(places, forKey: "places")
                
            
        })
        
    }
}
    
    
    
    
    @IBAction func locateMe(_ sender: Any) {
        
    mapView.setUserTrackingMode(.follow, animated: true)
        
    }
    
    
    @IBAction func showDirections(_ sender: AnyObject) {
        
        
     let routeRequest = MKDirectionsRequest()
        routeRequest.source = MKMapItem.forCurrentLocation()
        routeRequest.transportType = .walking
        routeRequest.requestsAlternateRoutes = true
        routeRequest.destination = destination
        
        let directions = MKDirections(request: routeRequest)
        
        directions.calculate
            {
                (response, error) -> Void in
                
                if let routes = response?.routes, (response?.routes.count)! > 0 && error == nil
                {
                    let route : MKRoute = routes[0]
                    
                    //distance calculated from the request
                    print(route.distance)
                    
                    //travel time calculated from the request
                    print(route.expectedTravelTime)
                }
        }
        
        
        
    }
    
    
    
        
        
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        
        let region = MKCoordinateRegion(center: location, span: span)
        
        self.mapView.setRegion(region, animated: true)
        
    }
    
    
    func clearMap() {
        let overlays = mapView.overlays
        mapView.removeOverlays(overlays)
    }
    
    func addRouteToMap(route: MKRoute) {
        clearMap()
        
        for step in route.steps {
            print(step.instructions)
        }
        
        mapView.add(route.polyline)
        mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0), animated: true)
        mapView.setUserTrackingMode(.none, animated: true)
        
    }
    
    func getDirections(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) {
        
        let request = MKDirectionsRequest()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end, addressDictionary: nil))
        request.requestsAlternateRoutes = true
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        directions.calculate( completionHandler: {(response: MKDirectionsResponse?, error: NSError?) in
            if let routeResponse = response?.routes {
                let quickestRouteForSegment: MKRoute = routeResponse.sorted(by: {$0.expectedTravelTime < $1.expectedTravelTime}) [0]
                self.addRouteToMap(route: quickestRouteForSegment)
                
            }
            } as! MKDirectionsHandler)
        
    }

        
    }







