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
    @Published var showAlert = false
    @Published var region: MKCoordinateRegion = MKCoordinateRegion()
    @Published var isUserInteracting = false
    var placesFetcher = PlacesFetcher()

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingLocation()
    }

    func updateRegion(coordinate: CLLocationCoordinate2D? = nil, zoomIn: Bool = true) {
        DispatchQueue.main.async {
            let newCoordinate = coordinate ?? self.lastKnownLocation?.coordinate
            if let coordinate = newCoordinate, (zoomIn || !self.isUserInteracting) {
                self.region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.lastKnownLocation = location
            self.updateRegion(coordinate: location.coordinate)
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
