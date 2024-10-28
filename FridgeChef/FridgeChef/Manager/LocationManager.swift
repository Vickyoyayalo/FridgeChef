//
//  LocationManager.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/20.
//

import Foundation
import Combine
import CoreLocation
import MapKit

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    private let manager = CLLocationManager()
    @Published var lastKnownLocation: CLLocation?
    @Published var region: MKCoordinateRegion = MKCoordinateRegion()
    @Published var isUserInteracting = false
    @Published var showAlert = false
    var placesFetcher = PlacesFetcher()
    
    private var lastUpdatedLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingLocation()
    }

    // MARK: - Update Region with Threshold Check
    func updateRegion(coordinate: CLLocationCoordinate2D? = nil, zoomIn: Bool = true) {
        DispatchQueue.main.async {
            let newCoordinate = coordinate ?? self.lastKnownLocation?.coordinate
            if let coordinate = newCoordinate, (zoomIn || !self.isUserInteracting) {
                // Only update region if not interacting or if zooming in
                self.region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            }
        }
    }

    // MARK: - CLLocationManagerDelegate Methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Calculate distance from last update
        let distanceThreshold: CLLocationDistance = 50.0 // Threshold of 50 meters
        if let lastUpdatedLocation = lastUpdatedLocation {
            let distance = lastUpdatedLocation.distance(from: location)
            if distance < distanceThreshold {
                return // Ignore updates if the user has moved less than 50 meters
            }
        }
        
        DispatchQueue.main.async {
            self.lastKnownLocation = location
            self.lastUpdatedLocation = location // Store this location for future comparison
            
            // Only update region if the user is not interacting
            if !self.isUserInteracting {
                self.updateRegion(coordinate: location.coordinate)
            }
            
            // Fetch nearby places regardless of interaction
            self.placesFetcher.fetchNearbyPlaces(coordinate: location.coordinate)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            print("Failed to get user location: \(error.localizedDescription)")
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
                self.showAlert = false
                if let coordinate = self.lastKnownLocation?.coordinate {
                    self.updateRegion(coordinate: coordinate, zoomIn: true)
                }
            default:
                self.showAlert = true
            }
        }
    }
}
