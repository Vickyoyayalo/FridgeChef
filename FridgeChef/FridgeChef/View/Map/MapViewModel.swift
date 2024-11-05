//
//  MapViewModel.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/11/2.
//

import Foundation
import Combine
import CoreLocation
import MapKit

class MapViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var searchResults: [Supermarket] = []
    @Published var selectedSupermarket: Supermarket?
    @Published var region: MKCoordinateRegion
    @Published var showingNavigationAlert = false
    
    private var cancellables = Set<AnyCancellable>()
    private let locationManager: LocationManager
    
    var userLocation: CLLocationCoordinate2D? {
        locationManager.lastKnownLocation?.coordinate
    }
    
    var allSupermarkets: [Supermarket] {
        locationManager.placesFetcher.supermarkets
    }
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        self.region = locationManager.region
        setupBindings()
    }
    
    private func setupBindings() {
        locationManager.$region
            .receive(on: RunLoop.main)
            .sink { [weak self] newRegion in
                self?.region = newRegion
            }
            .store(in: &cancellables)
        
        locationManager.$lastKnownLocation
            .compactMap { $0 }
            .sink { [weak self] newLocation in
                self?.performSearch(at: newLocation.coordinate)
            }
            .store(in: &cancellables)
        
        locationManager.placesFetcher.$supermarkets
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateSearchResults()
            }
            .store(in: &cancellables)
        
        $searchText
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateSearchResults()
            }
            .store(in: &cancellables)
    }
    
    func updateSearchResults() {
        guard let userLocation = userLocation else {
            searchResults = []
            return
        }
        searchResults = allSupermarkets
            .filter { supermarket in
                searchText.isEmpty || supermarket.name.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { first, second in
                let distanceToFirst = distance(from: userLocation, to: first.coordinate)
                let distanceToSecond = distance(from: userLocation, to: second.coordinate)
                return distanceToFirst < distanceToSecond
            }
    }
    
    private func distance(from userLocation: CLLocationCoordinate2D, to supermarketLocation: CLLocationCoordinate2D) -> Double {
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let supermarketCLLocation = CLLocation(latitude: supermarketLocation.latitude, longitude: supermarketLocation.longitude)
        return userCLLocation.distance(from: supermarketCLLocation)
    }
    
    func openDirections(to supermarket: Supermarket) {
        selectedSupermarket = supermarket
        showingNavigationAlert = true
    }
    
    func performNavigation() {
        guard let supermarket = selectedSupermarket else { return }
        if isGoogleMapsInstalled() {
            openGoogleMaps(to: supermarket.coordinate, destinationName: supermarket.name)
        } else {
            openAppleMaps(to: supermarket.coordinate, destinationName: supermarket.name)
        }
    }
    
    private func isGoogleMapsInstalled() -> Bool {
        if let url = URL(string: "comgooglemaps://"), UIApplication.shared.canOpenURL(url) {
            return true
        }
        return false
    }
    
    private func openGoogleMaps(to coordinate: CLLocationCoordinate2D, destinationName: String) {
        let encodedName = destinationName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "comgooglemaps://?daddr=\(encodedName)&directionsmode=driving"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func openAppleMaps(to coordinate: CLLocationCoordinate2D, destinationName: String) {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = destinationName
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    func performSearch(at coordinate: CLLocationCoordinate2D) {
        locationManager.placesFetcher.fetchNearbyPlaces(coordinate: coordinate)
    }
}

